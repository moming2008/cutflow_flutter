import 'package:drift/drift.dart';

import '../database/app_database.dart' as db;
import '../model/crop_preset.dart';

class CropPresetRepository {
  final db.AppDatabase _db;

  CropPresetRepository(this._db);

  /// 获取所有预设(按排序顺序)
  Future<List<CropPreset>> getAllPresets() async {
    final rows = await _db.getAllPresets();
    return rows.map(_fromDb).toList();
  }

  /// 根据ID获取预设
  Future<CropPreset?> getPresetById(int id) async {
    final row = await _db.getPresetById(id);
    return row != null ? _fromDb(row) : null;
  }

  /// 插入预设
  Future<int> insertPreset(CropPreset preset) async {
    final companion = db.CropPresetsCompanion.insert(
      name: preset.name,
      ratioLabel: preset.ratioLabel,
      ratioW: preset.ratioW,
      ratioH: preset.ratioH,
      outputW: preset.outputW,
      outputH: preset.outputH,
      offsetX: preset.offsetX,
      offsetY: preset.offsetY,
      isBuiltin: preset.isBuiltin,
      sortOrder: preset.sortOrder,
    );
    return await _db.into(_db.cropPresets).insert(companion);
  }

  /// 删除预设
  Future<void> deletePreset(int id) async {
    await _db.deletePreset(id);
  }

  /// 更新预设
  Future<void> updatePreset(CropPreset preset) async {
    final companion = db.CropPresetsCompanion(
      id: Value(preset.id),
      name: Value(preset.name),
      ratioLabel: Value(preset.ratioLabel),
      ratioW: Value(preset.ratioW),
      ratioH: Value(preset.ratioH),
      outputW: Value(preset.outputW),
      outputH: Value(preset.outputH),
      offsetX: Value(preset.offsetX),
      offsetY: Value(preset.offsetY),
      isBuiltin: Value(preset.isBuiltin),
      sortOrder: Value(preset.sortOrder),
    );
    await _db.update(_db.cropPresets).replace(companion);
  }

  /// 不再初始化默认预设，由用户自行添加
  Future<void> initializeDefaults() async {}

  // ==================== Private Helpers ====================

  CropPreset _fromDb(db.CropPreset row) {
    return CropPreset(
      id: row.id,
      name: row.name,
      ratioLabel: row.ratioLabel,
      ratioW: row.ratioW,
      ratioH: row.ratioH,
      outputW: row.outputW,
      outputH: row.outputH,
      offsetX: row.offsetX,
      offsetY: row.offsetY,
      isBuiltin: row.isBuiltin,
      sortOrder: row.sortOrder,
    );
  }
}
