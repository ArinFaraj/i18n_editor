import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:path/path.dart';
import 'package:riverpod/riverpod.dart';

final baseLocalePathProvider = FutureProvider(
  (ref) async {
    final projectPath = ref.watch(projectManagerProvider);
    if (projectPath == null) return null;

    final filePrefix = await ref
        .watch(i18nConfigsProvider.selectAsync((value) => value?.filePrefix));
    if (filePrefix == null) {
      return null;
    }

    final baseLocalePath = join(projectPath, '$filePrefix.json');
    return baseLocalePath;
  },
  name: 'baseLocalePath',
);
