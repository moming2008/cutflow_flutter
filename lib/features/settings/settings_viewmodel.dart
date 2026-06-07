/// 设置页 ViewModel
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/model/crop_preset.dart';
import '../../core/repository/app_settings_repository.dart';
import '../../core/repository/crop_preset_repository.dart';
import '../../core/util/logger.dart';
import '../../main.dart';

final settingsProvider =
    StateNotifierProvider<SettingsViewModel, SettingsState>(
  (ref) {
    final vm = SettingsViewModel(
      settingsRepo: AppSettingsRepository(database),
      presetRepo: CropPresetRepository(database),
    );
    Future.microtask(() => vm.load());
    return vm;
  },
);

class SettingsState {
  final String exportDirectory;
  final List<CropPreset> presets;
  final bool isLoading;

  const SettingsState({
    this.exportDirectory = '',
    this.presets = const [],
    this.isLoading = false,
  });

  SettingsState copyWith({
    String? exportDirectory,
    List<CropPreset>? presets,
    bool? isLoading,
  }) {
    return SettingsState(
      exportDirectory: exportDirectory ?? this.exportDirectory,
      presets: presets ?? this.presets,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsViewModel extends StateNotifier<SettingsState> {
  final AppSettingsRepository _settingsRepo;
  final CropPresetRepository _presetRepo;

  SettingsViewModel({
    required AppSettingsRepository settingsRepo,
    required CropPresetRepository presetRepo,
  })  : _settingsRepo = settingsRepo,
        _presetRepo = presetRepo,
        super(const SettingsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final dir = await _settingsRepo.getExportDirectory() ?? '未设置';
      final presets = await _presetRepo.getAllPresets();
      state = state.copyWith(
        exportDirectory: dir,
        presets: presets,
        isLoading: false,
      );
      log('Settings').i('Loaded: exportDir="$dir", presets=${presets.length}');
    } catch (e) {
      log('Settings').e('Failed to load settings', error: e);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setExportDirectory(String path) async {
    log('Settings').i('Setting export directory: $path');
    await _settingsRepo.setExportDirectory(path);
    state = state.copyWith(exportDirectory: path);
  }

  Future<void> addPreset(CropPreset preset) async {
    log('Settings').i('Adding crop preset: "${preset.name}"');
    await _presetRepo.insertPreset(preset);
    await load();
  }

  Future<void> updatePreset(CropPreset preset) async {
    log('Settings').i('Updating crop preset: id=${preset.id}, "${preset.name}"');
    await _presetRepo.updatePreset(preset);
    await load();
  }

  Future<void> deletePreset(int id) async {
    log('Settings').i('Deleting crop preset id=$id');
    await _presetRepo.deletePreset(id);
    await load();
  }
}
