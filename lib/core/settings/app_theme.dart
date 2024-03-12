import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/core/local_storage/sembast_local_storage.dart';

final appThemeProvider = AsyncNotifierProvider<AppThemeNotifier, ThemeMode>(
  AppThemeNotifier.new,
);

class AppThemeNotifier extends AsyncNotifier<ThemeMode> {
  static const _fallbackTheme = ThemeMode.system;
  static const _themeKey = 'appTheme';

  @override
  Future<ThemeMode> build() async {
    final localStorageRepo = await ref.watch(localStorageRepoProvider.future);
    final themeName = await localStorageRepo.get<String>(_themeKey);

    if (themeName == null) {
      return _fallbackTheme;
    }

    return ThemeMode.values.firstWhere(
      (locale) => locale.name == themeName,
      orElse: () => _fallbackTheme,
    );
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final localStorageRepo = ref.watch(localStorageRepoProvider).requireValue;
      await localStorageRepo.set(_themeKey, themeMode.name);

      return themeMode;
    });
  }
}
