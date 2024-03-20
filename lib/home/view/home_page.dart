import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/core/toast/toast_provider.dart';
import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:i18n_editor/home/provider/selected_leaf.dart';
import 'package:i18n_editor/home/widget/editor.dart';
import 'package:i18n_editor/home/widget/home_menu_bar.dart';
import 'package:i18n_editor/home/widget/key_tree.dart';
import 'package:i18n_editor/home/widget/new_project_dialog.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(toastProvider, (_, toasts) {
      if (toasts.isEmpty) return;

      showSequencialToasts(
        toasts: toasts
            .map(
              (e) => Toast(
                animationBuilder: (context, controller, child) =>
                    SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(controller),
                  child: FadeTransition(
                    opacity: controller,
                    child: child,
                  ),
                ),
                alignment: Alignment.topRight,
                duration: const Duration(seconds: 4),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 60,
                    right: 30,
                  ),
                  child: Card(
                    color: switch (e.$2) {
                      ToastType.info => null,
                      ToastType.success => Colors.green,
                      ToastType.warning => Colors.orange,
                      ToastType.error => Colors.red,
                    }
                        ?.withOpacity(0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            switch (e.$2) {
                              ToastType.info => Icons.info,
                              ToastType.success => Icons.check,
                              ToastType.warning => Icons.warning,
                              ToastType.error => Icons.error,
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            e.$1,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
        context: context,
      );
      ref.read(toastProvider.notifier).remove(toasts);
    });

    ref.listen(projectManagerProvider, (prev, next) async {
      if (prev != next && next != null) {
        final configs = await ref.refresh(i18nConfigsProvider.future);
        if (configs == null && context.mounted) {
          showNewProjectDialog(context, ref);
        }
      }
    });

    final keys = ref.watch(keysProvider);
    final selectedNode = ref.watch(selectedLeafProvider).value;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeMenuBar(),
          const Divider(height: 1),
          Expanded(
            child: (ref.watch(projectManagerProvider) == null)
                ? const Center(
                    child: Icon(Icons.language_outlined, size: 100),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: keys.when(
                          skipLoadingOnRefresh: true,
                          data: (nodes) => nodes == null
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('empty'),
                                )
                              : KeyTree(nodes.children),
                          error: (e, s) => Text('$e\n$s'),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        flex: 2,
                        child: selectedNode == null
                            ? const Center(child: Text('Select a key to edit'))
                            : const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Editor(),
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
