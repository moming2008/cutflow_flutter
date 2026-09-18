import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

// 库表里也有个叫 AudioTask 的行类型，必须加前缀区分
import 'package:cutflow_flutter/core/database/app_database.dart' as db;
import 'package:cutflow_flutter/core/model/audio_source_info.dart';
import 'package:cutflow_flutter/core/model/audio_task.dart';
import 'package:cutflow_flutter/core/repository/app_settings_repository.dart';
import 'package:cutflow_flutter/core/repository/audio_repository.dart';
import 'package:cutflow_flutter/features/audio/audio_viewmodel.dart';

import 'support/seedable_audio_viewmodel.dart';

/// 覆盖 AudioViewModel 中**不需要 ffmpeg** 的那部分编排：
/// 输出路径去重、校验早退、记录回填、取消守卫、记录删除。
///
/// 其余部分（真实执行 ffmpeg 的进度/失败/取消分支、DONE 落库失败时的消息区分）
/// 无法在测试中启动外部进程，只能靠阅读与 Task 9 的端到端人工验收。
void main() {
  late db.AppDatabase testDb;
  late AudioRepository repository;
  late AppSettingsRepository settings;
  late Directory workDir;

  const hasAudio = AudioSourceInfo(hasAudio: true, durationMs: 60000);

  setUp(() async {
    testDb = db.AppDatabase.forTest(NativeDatabase.memory());
    repository = AudioRepository(testDb);
    settings = AppSettingsRepository(testDb);
    workDir = await Directory.systemTemp.createTemp('cutflow_audio_vm_');
  });

  tearDown(() async {
    await testDb.close();
    if (await workDir.exists()) {
      await workDir.delete(recursive: true);
    }
  });

  /// 构造一个「已选好视频、已探测出音轨」的基准状态
  AudioState seededState({
    String? sourcePath,
    String? coverPath,
    String? outputDirectory,
    int trimStartMs = 0,
    int trimEndMs = 60000,
    bool isConverting = false,
  }) {
    return AudioState(
      sourcePath: sourcePath ?? p.join(workDir.path, 'video.mp4'),
      sourceName: 'video.mp4',
      sourceDurationMs: 60000,
      trimStartMs: trimStartMs,
      trimEndMs: trimEndMs,
      coverPath: coverPath,
      outputDirectory: outputDirectory,
      targetBitrateKbps: 320,
      sourceInfo: hasAudio,
      isConverting: isConverting,
    );
  }

  /// 构造 VM 并等构造里的 `_restorePreferences` 落定
  ///
  /// 不等它落定的话，它可能在测试断言之后才写状态（把 outputDirectory 覆盖成
  /// 空），且 tearDown 关库时它还挂在查询上。
  /// 先写入同名设置，使那次写入与测试铺的前置状态一致。
  Future<SeedableAudioViewModel> makeViewModel({String? exportDirectory}) async {
    if (exportDirectory != null) {
      await settings.setExportDirectory(exportDirectory);
    }
    final viewModel = SeedableAudioViewModel(repository, settings);
    await pumpEventQueue();
    return viewModel;
  }

  group('startConversion 校验早退', () {
    test('未选文件时报错且不进入转换中', () async {
      final viewModel = await makeViewModel();

      await viewModel.startConversion();

      expect(viewModel.state.error, equals('请先选择视频文件'));
      expect(viewModel.state.isConverting, isFalse);
    });

    test('出点不大于入点时报错', () async {
      final viewModel = await makeViewModel(exportDirectory: workDir.path);
      viewModel.seed(seededState(
        trimStartMs: 60000,
        trimEndMs: 60000,
        outputDirectory: workDir.path,
      ));

      await viewModel.startConversion();

      expect(viewModel.state.error, equals('出点必须大于入点'));
      expect(viewModel.state.isConverting, isFalse);
    });

    test('未设置输出目录时报错', () async {
      final viewModel = await makeViewModel();
      viewModel.seed(seededState(outputDirectory: null));

      await viewModel.startConversion();

      expect(viewModel.state.error, equals('未设置输出目录'));
      expect(viewModel.state.isConverting, isFalse);
    });

    test('源文件不存在时报错', () async {
      final viewModel = await makeViewModel(exportDirectory: workDir.path);
      viewModel.seed(seededState(
        sourcePath: p.join(workDir.path, 'missing.mp4'),
        outputDirectory: workDir.path,
      ));

      await viewModel.startConversion();

      expect(viewModel.state.error, equals('源文件不存在'));
      expect(viewModel.state.isConverting, isFalse);
    });

    test('封面图片不存在时报错', () async {
      // 源文件真实存在，才能走到封面校验那一步（内容无所谓，只做 exists 判断）
      final source = File(p.join(workDir.path, 'video.mp4'));
      await source.writeAsString('not a real video');
      final viewModel = await makeViewModel(exportDirectory: workDir.path);
      viewModel.seed(seededState(
        sourcePath: source.path,
        coverPath: p.join(workDir.path, 'missing.jpg'),
        outputDirectory: workDir.path,
      ));

      await viewModel.startConversion();

      expect(viewModel.state.error, equals('封面图片不存在，请重新选择'));
      expect(viewModel.state.isConverting, isFalse);
    });

    test('转换进行中重复调用被忽略', () async {
      final viewModel = await makeViewModel(exportDirectory: workDir.path);
      // 源文件故意不存在：即便互斥守卫被摘掉，本用例也只会走到「源文件不存在」
      // 而不会真的启动 ffmpeg
      viewModel.seed(seededState(
        sourcePath: p.join(workDir.path, 'missing.mp4'),
        outputDirectory: workDir.path,
        isConverting: true,
      ));

      await viewModel.startConversion();

      expect(viewModel.state.isConverting, isTrue);
      expect(viewModel.state.error, isNull);
    });
  });

  group('cancelConversion', () {
    test('没有在跑的引擎时不改动状态', () async {
      final viewModel = await makeViewModel();
      viewModel.seed(seededState(isConverting: true));

      await viewModel.cancelConversion();

      // 守卫若丢失，这里会被写成「已取消」并把 isConverting 复位
      expect(viewModel.state.isConverting, isTrue);
      expect(viewModel.state.error, isNull);
      expect(viewModel.state.progress, equals(0));
    });
  });

  group('restoreFromTask', () {
    // 记录里的出点必须原样回到状态里：这条路径的全部意义就是「回填参数重试」，
    // 把区间悄悄放宽到全片会让重试产出与失败那次不同的文件。
    test('回填记录参数、保留出点并重置探测态', () async {
      final viewModel = await makeViewModel();
      viewModel.seed(const AudioState(
        sourceInfo: AudioSourceInfo(hasAudio: true, durationMs: 1000),
        error: '旧错误',
        success: '旧成功',
      ));

      viewModel.restoreFromTask(AudioTask(
        id: 7,
        sourcePath: p.join(workDir.path, 'old.mp4'),
        sourceName: 'old.mp4',
        sourceDurationMs: 90000,
        trimStartMs: 1000,
        trimEndMs: 45000,
        title: '晴天',
        artist: '周杰伦',
        album: '叶惠美',
        coverPath: '/nope/cover.jpg',
        targetBitrateKbps: 192,
        outputName: '晴天.mp3',
        status: AudioTaskStatus.failed,
        progress: 40,
        errorMessage: '转换失败: x',
        createdAt: 0,
      ));

      final state = viewModel.state;
      expect(state.sourcePath, equals(p.join(workDir.path, 'old.mp4')));
      expect(state.sourceName, equals('old.mp4'));
      expect(state.sourceDurationMs, equals(90000));
      expect(state.trimStartMs, equals(1000));
      expect(state.trimEndMs, equals(45000));
      expect(state.title, equals('晴天'));
      expect(state.artist, equals('周杰伦'));
      expect(state.album, equals('叶惠美'));
      expect(state.coverPath, equals('/nope/cover.jpg'));
      expect(state.targetBitrateKbps, equals(192));
      // 换源必须丢掉上一个文件的探测结果并重新探测
      expect(state.sourceInfo, isNull);
      expect(state.isProbing, isTrue);
      expect(state.error, isNull);
      expect(state.success, isNull);

      // 释放 VM：在途的探测（真的会去调 ffprobe）以 !mounted 作废，
      // 不再回写状态；本用例只断言上面的同步写入
      viewModel.dispose();
    });
  });

  group('resolveOutputPath 去重', () {
    test('无同名文件时原样返回', () async {
      final path =
          await AudioViewModel.resolveOutputPath(workDir.path, '晴天.mp3');
      expect(path, equals(p.join(workDir.path, '晴天.mp3')));
    });

    test('同名文件已存在时追加 _1', () async {
      // 第一次转换已产出 晴天.mp3，同名再转一次必须另起名字
      File(p.join(workDir.path, '晴天.mp3')).writeAsStringSync('x');

      final path =
          await AudioViewModel.resolveOutputPath(workDir.path, '晴天.mp3');

      expect(path, equals(p.join(workDir.path, '晴天_1.mp3')));
    });

    test('_1 也被占用时递增到 _2', () async {
      File(p.join(workDir.path, '晴天.mp3')).writeAsStringSync('x');
      File(p.join(workDir.path, '晴天_1.mp3')).writeAsStringSync('x');

      final path =
          await AudioViewModel.resolveOutputPath(workDir.path, '晴天.mp3');

      expect(path, equals(p.join(workDir.path, '晴天_2.mp3')));
    });
  });

  group('deleteRecord', () {
    Future<int> insertTask({String? outputPath}) {
      return repository.insertTask(AudioTask(
        id: 0,
        sourcePath: p.join(workDir.path, 'video.mp4'),
        sourceName: 'video.mp4',
        sourceDurationMs: 60000,
        trimStartMs: 0,
        trimEndMs: 60000,
        targetBitrateKbps: 320,
        outputName: '晴天.mp3',
        outputPath: outputPath,
        status: AudioTaskStatus.done,
        progress: 100,
        createdAt: 0,
      ));
    }

    test('删除记录时连同产物文件一起删除', () async {
      final produced = File(p.join(workDir.path, '晴天.mp3'));
      await produced.writeAsString('mp3');
      final id = await insertTask(outputPath: produced.path);
      final viewModel = await makeViewModel();

      await viewModel.deleteRecord((await repository.getTaskById(id))!);

      expect(await repository.getTaskById(id), isNull);
      expect(produced.existsSync(), isFalse);
    });

    test('产物文件已不在时仍然删除记录', () async {
      // 文件删除是尽力而为：文件可能被用户手动移走或正被占用，
      // 卡在这个异常上会让记录永远删不掉。
      final id = await insertTask(
        outputPath: p.join(workDir.path, '已经不存在.mp3'),
      );
      final viewModel = await makeViewModel();

      await viewModel.deleteRecord((await repository.getTaskById(id))!);

      expect(await repository.getTaskById(id), isNull);
    });
  });
}
