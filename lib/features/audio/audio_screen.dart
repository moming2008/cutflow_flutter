/// 音频提取页面
///
/// 视频 → MP3，封装封面图与歌名/歌手/专辑 ID3 标签。
/// 单页布局：上部表单区（预览 + 标签 + 区间 + 码率 + 输出），下部转换记录。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/model/audio_task.dart';
import '../../core/model/video_item.dart';
import '../../core/services/explorer_service.dart';
import '../../ui/theme/colors.dart';
import '../editor/widgets/trim_range_control.dart';
import '../editor/widgets/video_preview_panel.dart';
import 'audio_viewmodel.dart';
import 'widgets/audio_bitrate_selector.dart';
import 'widgets/audio_record_tile.dart';
import 'widgets/audio_tag_panel.dart';

/// 步进按钮每次移动的毫秒数（音频场景用秒级，不是帧级）
const int kAudioStepMs = 1000;

class AudioScreen extends ConsumerStatefulWidget {
  const AudioScreen({super.key});

  @override
  ConsumerState<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends ConsumerState<AudioScreen> {
  final _previewKey = GlobalKey<VideoPreviewPanelState>();

  /// 预览播放头位置（毫秒），喂给区间控件的当前位置指示点
  int _currentPositionMs = 0;

  Future<void> _pickSourceFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      final path = result?.files.firstOrNull?.path;
      if (path != null) {
        await ref.read(audioProvider.notifier).setSourceFile(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('选择文件失败: $e')));
      }
    }
  }

  Future<void> _pickOutputDirectory() async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择输出目录',
    );
    if (dir != null) {
      ref.read(audioProvider.notifier).setOutputDirectory(dir);
    }
  }

  /// 步进预览播放头（音频场景按秒计，不是按帧）
  ///
  /// 与编辑器一致：这两个按钮移动的是**播放位置**，不是入点/出点。
  /// 「设定入点 / 设定出点」取的是当前播放位置，若播放头只能靠拖滑块移动，
  /// 那对按钮就形同虚设；而且「快进」若去推入点，几下就能把入点顶到出点，
  /// 让「开始转换」无解释地变灰。
  void _seekBy(int deltaMs) {
    final preview = _previewKey.currentState;
    if (preview == null) return;
    final durationMs = ref.read(audioProvider).sourceDurationMs;
    final target = (preview.currentPositionMs + deltaMs).clamp(0, durationMs);
    preview.seekTo(target);
    // 指示点立刻跟手，不等播放器位置流：播放器未就绪时流回调根本不会来，
    // 而滑块上的圆点就是这两个按钮唯一可见的反馈。clamp 与 seek 同一处。
    setState(() => _currentPositionMs = target);
  }

  /// 播放位置变化 → 更新指示点
  ///
  /// **节流方式：只在整秒值变化时才重建。**
  /// 播放器的位置流是连续触发的，每次都 setState 会让整棵表单每秒重建几十次；
  /// 而指示点按秒级粒度移动已经足够（跨多分钟的素材上远小于一个像素）。
  /// 选整秒而非「~100ms 时间闸」是因为它不依赖真实时钟，行为可被确定性地断言。
  void _onPositionChanged(int ms) {
    if (ms ~/ 1000 == _currentPositionMs ~/ 1000) return;
    setState(() => _currentPositionMs = ms);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(audioProvider);
    final records = ref.watch(audioRecordsProvider);
    final notifier = ref.read(audioProvider.notifier);

    // 换源后区间会被重置为全片，上一个文件的播放头留着无意义，还可能落在
    // 新时长之外，故归零
    ref.listen(audioProvider.select((s) => s.sourcePath), (previous, next) {
      if (previous != next) setState(() => _currentPositionMs = 0);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '音频提取',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: state.isConverting ? null : _pickSourceFile,
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('选择视频'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: state.sourcePath == null
                    ? _buildEmptyState()
                    : _buildForm(state, notifier),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),
            _buildRecords(records, notifier, state.isConverting),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note_outlined, size: 48, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            '选择一个视频开始提取音频',
            style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AudioState state, AudioViewModel notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 阻断原因（无音轨 / 出点不大于入点）
        //
        // 按钮变灰时必须说明为什么，否则用户只看到一个不可点的「开始转换」。
        // 无音轨那条也走 blockingError，故统一在这里渲染一次，不会重复。
        // 排除的两种情况：
        // - state.error 非空：它会在下方单独成条，同一时刻不叠两条消息；
        // - 探测中：此时入点/出点都还是 0，报「出点必须大于入点」是误导。
        if (state.error == null &&
            !state.isProbing &&
            state.blockingError != null) ...[
          _banner(state.blockingError!, AppColors.error),
          const SizedBox(height: 12),
        ],

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 预览区
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 240,
                child: _buildPreview(state),
              ),
            ),
            const SizedBox(width: 16),
            // 标签区
            Expanded(
              flex: 2,
              child: AudioTagPanel(
                title: state.title,
                artist: state.artist,
                album: state.album,
                coverPath: state.coverPath,
                enabled: !state.isConverting,
                onTitleChanged: notifier.setTitle,
                onArtistChanged: notifier.setArtist,
                onAlbumChanged: notifier.setAlbum,
                onCoverChanged: notifier.setCoverPath,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 区间选择（复用编辑器组件）
        TrimRangeControl(
          durationMs: state.sourceDurationMs,
          trimStartMs: state.trimStartMs,
          trimEndMs: state.trimEndMs,
          currentPositionMs: _currentPositionMs,
          frameRate: 0,
          stepBackwardLabel: '快退 1s',
          stepForwardLabel: '快进 1s',
          onSetStart: () => notifier
              .setTrimStart(_previewKey.currentState?.currentPositionMs ?? 0),
          onSetEnd: () => notifier
              .setTrimEnd(_previewKey.currentState?.currentPositionMs ?? 0),
          onTrimStartManualChanged: notifier.setTrimStart,
          onTrimEndManualChanged: notifier.setTrimEnd,
          onSliderChanged: (ms) => _previewKey.currentState?.seekTo(ms.round()),
          onStepBackward: () => _seekBy(-kAudioStepMs),
          onStepForward: () => _seekBy(kAudioStepMs),
        ),

        const SizedBox(height: 16),

        AudioBitrateSelector(
          sourceInfo: state.sourceInfo,
          targetBitrateKbps: state.targetBitrateKbps,
          enabled: !state.isConverting,
          onChanged: notifier.setTargetBitrate,
        ),

        const SizedBox(height: 12),

        // 输出路径
        Row(
          children: [
            const SizedBox(
              width: 60,
              child: Text('输出到',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ),
            Expanded(
              child: Container(
                height: 36,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Text(
                  state.outputDirectory == null
                      ? '未设置输出目录'
                      : p.join(state.outputDirectory!, state.outputFileName),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: state.isConverting ? null : _pickOutputDirectory,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('更改'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (state.error != null) ...[
          _banner(state.error!, AppColors.error),
          const SizedBox(height: 12),
        ],
        if (state.success != null) ...[
          _banner(state.success!, AppColors.success),
          const SizedBox(height: 12),
        ],

        // 进度
        if (state.isConverting) ...[
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.progress / 100,
                    backgroundColor: AppColors.outline,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${state.progress}%',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // 开始 / 取消
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: state.isConverting
                ? () => notifier.cancelConversion()
                : (state.canConvert ? () => notifier.startConversion() : null),
            icon: state.isConverting
                ? const Icon(Icons.stop, size: 18)
                : state.isProbing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.music_note, size: 18),
            label: Text(state.isConverting
                ? '取消转换'
                : state.isProbing
                    ? '探测中…'
                    : '开始转换'),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.isConverting
                  ? AppColors.error
                  : (state.canConvert ? AppColors.primary : AppColors.outline),
              foregroundColor: state.isConverting || state.canConvert
                  ? Colors.white
                  : AppColors.textTertiary,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(AudioState state) {
    // VideoPreviewPanel 需要 VideoItem；这里用最小字段构造，
    // 音频场景不关心分辨率/编码，只用到 path/name/duration。
    final video = VideoItem(
      id: 0,
      path: state.sourcePath!,
      name: state.sourceName ?? p.basename(state.sourcePath!),
      duration: state.sourceDurationMs,
      width: 0,
      height: 0,
      fileSize: 0,
      frameRate: 0,
      codec: '',
      importedAt: 0,
    );

    return VideoPreviewPanel(
      key: _previewKey,
      video: video,
      onPositionChanged: _onPositionChanged,
    );
  }

  Widget _banner(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecords(
    AsyncValue<List<AudioTask>> records,
    AudioViewModel notifier,
    bool isConverting,
  ) {
    return SizedBox(
      height: 180,
      child: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('读取记录失败: $e',
              style: const TextStyle(fontSize: 12, color: AppColors.error)),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Text('暂无转换记录',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            );
          }
          return ListView.separated(
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = tasks[index];
              final outputPath = task.outputPath;
              return AudioRecordTile(
                task: task,
                fileExists: outputPath != null && File(outputPath).existsSync(),
                // 打开产物文件不碰 ViewModel，转换中看已完成的结果是安全的，
                // 故不随 isConverting 禁用
                onOpen: () {
                  if (outputPath != null) {
                    ExplorerService.openFileLocation(outputPath);
                  }
                },
                // 转换中禁掉重试与删除：重试会把表单回填到一次正在跑的转换底下，
                // 删除若落在在飞的那一行上，它收尾的 DONE 更新会打到 0 行——
                // 留下一条「转换完成」提示，列表里却没有任何对应记录
                onRetry: isConverting
                    ? null
                    : () => notifier.restoreFromTask(task),
                onDelete: isConverting
                    ? null
                    : () => _confirmDelete(task, notifier),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(AudioTask task, AudioViewModel notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录', style: TextStyle(fontSize: 16)),
        content: Text(
          '将删除这条记录${task.outputPath != null ? '，并删除已生成的 mp3 文件' : ''}。确定吗？',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await notifier.deleteRecord(task);
  }
}
