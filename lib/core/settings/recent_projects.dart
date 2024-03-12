import 'package:i18n_editor/core/settings/generic_local_notifier.dart';
import 'package:riverpod/riverpod.dart';

final recentProjectsProvider = AsyncNotifierProvider<
    GenericLocalNotifier<List<String>, List<Object?>>, List<String>>(
  () => GenericLocalNotifier(
    'recentProjects',
    [],
    (value) => value.cast<String>(),
    (value) => value,
  ),
);
