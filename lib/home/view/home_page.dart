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
import 'package:i18n_editor/home/widget/toast_handler.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(toastProvider, (_, toasts) {
      if (toasts.isEmpty) return;
      handleToasts(toasts, context, ref);
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
    final project = ref.watch(projectManagerProvider);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeMenuBar(),
          const Divider(height: 1),
          Expanded(
            child: project == null
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
                            ? const Center(
                                child: Text('Select a key to edit'),
                              )
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
