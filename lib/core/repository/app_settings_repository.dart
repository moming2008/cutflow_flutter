import '../database/app_database.dart' as db;

class AppSettingsRepository {
  final db.AppDatabase _db;

  AppSettingsRepository(this._db);

  static const String keyExportDirectory = 'export_directory';

  /// 获取导出目录路径
  Future<String?> getExportDirectory() async {
    return await _db.getSetting(keyExportDirectory);
  }

  /// 设置导出目录路径
  Future<void> setExportDirectory(String path) async {
    await _db.upsertSetting(keyExportDirectory, path);
  }

  /// 获取任意设置值
  Future<String?> getSetting(String key) async {
    return await _db.getSetting(key);
  }

  /// 设置任意设置值
  Future<void> setSetting(String key, String value) async {
    await _db.upsertSetting(key, value);
  }

  /// 删除设置
  Future<void> deleteSetting(String key) async {
    await _db.deleteSetting(key);
  }
}
