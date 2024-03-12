import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/app/view/i18n_app.dart';
import 'package:i18n_editor/startup/view/app_startup_widget.dart';

void main() {
  runApp(
    ProviderScope(
      child: AppStartupWidget(
        onLoaded: (context) => const I18nApp(),
      ),
    ),
  );
}
