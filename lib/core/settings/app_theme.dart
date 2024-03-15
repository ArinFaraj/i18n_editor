import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/core/settings/generic_local_notifier.dart';

final appThemeProvider =
    AsyncNotifierProvider<GenericLocalNotifier<ThemeMode, String>, ThemeMode>(
  () => GenericLocalNotifier(
    'appTheme',
    ThemeMode.system,
    (value) => ThemeMode.values.firstWhere(
      (element) => element.name == value,
      orElse: () => ThemeMode.system,
    ),
    (value) => value.name,
  ),
  name: 'appTheme',
);
