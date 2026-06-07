/// 应用初始化器
/// 在应用启动时执行必要的初始化操作
library;

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../database/app_database.dart';
import '../repository/crop_preset_repository.dart';
import '../repository/app_settings_repository.dart';
import '../util/logger.dart';

class AppInitializer {
  /// 初始化应用
  static Future<void> initialize(AppDatabase db) async {
    log('AppInit').i('Starting app initialization');

    // 初始化裁切预设
    final presetRepo = CropPresetRepository(db);
    await presetRepo.initializeDefaults();
    log('AppInit').i('Crop presets initialized');

    // 初始化默认导出目录（仅首次启动时设置）
    final settingsRepo = AppSettingsRepository(db);
    final existingDir = await settingsRepo.getExportDirectory();
    if (existingDir == null) {
      final docsDir = await getApplicationDocumentsDirectory();
      final defaultExportDir = p.join(docsDir.path, 'CutFlow', 'exports');
      await settingsRepo.setExportDirectory(defaultExportDir);
      log('AppInit').i('Default export directory set: $defaultExportDir');
    } else {
      log('AppInit').i('Export directory already set: $existingDir');
    }

    log('AppInit').i('App initialization completed');
  }
}
