import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/app/view/i18n_app.dart';
import 'package:i18n_editor/core/logger/talker.dart';
import 'package:i18n_editor/startup/view/app_startup_widget.dart';

void main() {
  runApp(
    ProviderScope(
      observers: [RiverpodLogger()],
      child: AppStartupWidget(
        onLoaded: (context) => const I18nApp(),
      ),
    ),
  );
}

class RiverpodLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    logger.info('R ⏰: ${provider.name}\n        $newValue');
  }

  @override
  void didAddProvider(ProviderBase<Object?> provider, Object? value,
      ProviderContainer container) {
    logger.info('R ➕: ${provider.name}\n        $value');
  }

  @override
  void didDisposeProvider(
      ProviderBase<Object?> provider, ProviderContainer container) {
    logger.info('R 🗑️: ${provider.name}');
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    logger
        .severe('R 🛑: ${provider.name}\n        $error\n        $stackTrace');
  }
}
