import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/core/local_storage/sembast_local_storage.dart';
import 'package:i18n_editor/core/settings/app_theme.dart';

final appStartupProvider = FutureProvider((Ref ref) async {
  ref.onDispose(() {
    ref.invalidate(localStorageRepoProvider);
    ref.invalidate(appThemeProvider);
  });

  await Future.wait(
    [
      ref.read(localStorageRepoProvider.future),
      ref.read(appThemeProvider.future),
    ],
  );
});
