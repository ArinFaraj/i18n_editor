import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/core/logger/talker.dart';
import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:i18n_editor/home/widget/home_menu_bar.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(projectManagerProvider, (prev, next) async {
      if (prev != next && next != null) {
        final configs = await ref.refresh(i18nConfigsProvider.future);
        if (configs == null && context.mounted) {
          showNewProjectDialog(context, ref);
        }
      }
    });

    // final files = ref.watch(filesNotifierProvider);
    final keys = ref.watch(baseLocaleKeysProvider);
    logger.info('building HomePage');

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeMenuBar(),
          keys.when(
            skipLoadingOnRefresh: true,
            data: (key_) => ListView.builder(
              shrinkWrap: true,
              itemCount: key_?.length ?? 1,
              itemBuilder: (context, index) => ListTile(
                title: Text(key_?[index].toString() ?? 'No files'),
                onTap: () {},
              ),
            ),
            error: (e, s) => Text('$e\n$s'),
            loading: () => const CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }

  void showNewProjectDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return HookBuilder(builder: (context) {
          final prefixController = useTextEditingController(text: 'strings');
          final defaultLocaleController = useTextEditingController(text: 'en');

          return AlertDialog(
            title: const Text('New i18n Project'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: prefixController,
                  decoration: const InputDecoration(
                    labelText: 'File Prefix',
                  ),
                ),
                TextField(
                  controller: defaultLocaleController,
                  decoration: const InputDecoration(
                    labelText: 'Default Locale',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  ref.read(projectManagerProvider.notifier).closeProject();
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(i18nConfigsProvider.notifier).createFile(
                        prefix: prefixController.text,
                        defaultLocale: defaultLocaleController.text,
                      );
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          );
        });
      },
    );
  }
}
