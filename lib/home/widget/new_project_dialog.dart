import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';

void showNewProjectDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return HookBuilder(builder: (context) {
        final prefixController = useTextEditingController(text: 'strings');
        final defaultLocaleController = useTextEditingController(text: 'en');

        void cancel() {
          ref.read(projectManagerProvider.notifier).closeProject();
          Navigator.of(context).pop();
        }

        void ok() {
          ref.read(i18nConfigsProvider.notifier).createFile(
                prefix: prefixController.text,
                defaultLocale: defaultLocaleController.text,
              );
          Navigator.of(context).pop();
        }

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
              onPressed: cancel,
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: ok,
              child: const Text('Ok'),
            ),
          ],
        );
      });
    },
  );
}
