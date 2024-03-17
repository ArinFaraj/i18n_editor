import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/core/logger/talker.dart';

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
