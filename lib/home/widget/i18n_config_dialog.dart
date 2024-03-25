import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';

void showI18nConfigsDialog(BuildContext context, WidgetRef ref) {
  final i18nConfigs = ref.read(i18nConfigsProvider).value;
  showDialog(
    context: context,
    builder: (context) {
      return HookBuilder(
        builder: (context) {
          final prefixController =
              useTextEditingController(text: i18nConfigs?.filePrefix);
          final defaultLocaleController =
              useTextEditingController(text: i18nConfigs?.defaultLocale);
          void cancel() {
            Navigator.of(context).pop();
          }

          void ok() {
            ref.read(i18nConfigsProvider.notifier).updateFile(
                  prefix: prefixController.text,
                  defaultLocale: defaultLocaleController.text,
                );
            Navigator.of(context).pop();
          }

          return AlertDialog(
            title: const Text('i18n Project'),
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
        },
      );
    },
  );
}
