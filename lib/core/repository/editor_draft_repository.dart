import 'package:drift/drift.dart';

import '../database/app_database.dart' as db;
import '../model/editor_draft.dart';

class EditorDraftRepository {
  final db.AppDatabase _db;

  EditorDraftRepository(this._db);

  /// 根据视频ID获取草稿
  Future<EditorDraft?> getDraftByVideoId(int videoId) async {
    final row = await _db.getDraftByVideoId(videoId);
    return row != null ? _fromDb(row) : null;
  }

  /// 插入草稿
  Future<int> insertDraft(EditorDraft draft) async {
    final companion = db.EditorDraftsCompanion.insert(
      sourceVideoId: draft.sourceVideoId,
      outputName: draft.outputName,
      trimStartMs: draft.trimStartMs,
      trimEndMs: draft.trimEndMs,
      selectedCropPresetId: Value(draft.selectedCropPresetId),
      updatedAt: draft.updatedAt,
    );
    return await _db.into(_db.editorDrafts).insert(companion);
  }

  /// 更新草稿
  Future<void> updateDraft(EditorDraft draft) async {
    final companion = db.EditorDraftsCompanion(
      id: Value(draft.id),
      sourceVideoId: Value(draft.sourceVideoId),
      outputName: Value(draft.outputName),
      trimStartMs: Value(draft.trimStartMs),
      trimEndMs: Value(draft.trimEndMs),
      selectedCropPresetId: Value(draft.selectedCropPresetId),
      updatedAt: Value(draft.updatedAt),
    );
    await _db.updateDraft(companion);
  }

  /// Upsert草稿(存在则更新,不存在则插入)
  Future<void> upsertDraft(EditorDraft draft) async {
    final existing = await getDraftByVideoId(draft.sourceVideoId);
    if (existing != null) {
      // 更新现有草稿
      final updatedDraft = EditorDraft(
        id: existing.id,
        sourceVideoId: draft.sourceVideoId,
        outputName: draft.outputName,
        trimStartMs: draft.trimStartMs,
        trimEndMs: draft.trimEndMs,
        selectedCropPresetId: draft.selectedCropPresetId,
        updatedAt: draft.updatedAt,
      );
      await updateDraft(updatedDraft);
    } else {
      await insertDraft(draft);
    }
  }

  /// 删除草稿
  Future<void> deleteDraft(int id) async {
    await _db.deleteDraft(id);
  }

  /// 获取所有草稿
  Future<List<EditorDraft>> getAllDrafts() async {
    final rows = await _db.getAllDrafts();
    return rows.map(_fromDb).toList();
  }

  /// 根据视频ID删除草稿
  Future<void> deleteDraftByVideoId(int videoId) async {
    final draft = await getDraftByVideoId(videoId);
    if (draft != null) {
      await deleteDraft(draft.id);
    }
  }

  // ==================== Private Helpers ====================

  EditorDraft _fromDb(db.EditorDraft row) {
    return EditorDraft(
      id: row.id,
      sourceVideoId: row.sourceVideoId,
      outputName: row.outputName,
      trimStartMs: row.trimStartMs,
      trimEndMs: row.trimEndMs,
      selectedCropPresetId: row.selectedCropPresetId,
      updatedAt: row.updatedAt,
    );
  }
}
