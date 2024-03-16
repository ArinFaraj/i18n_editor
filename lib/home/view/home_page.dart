import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:i18n_editor/home/widget/editor.dart';
import 'package:i18n_editor/home/widget/home_menu_bar.dart';
import 'package:i18n_editor/home/widget/key_tree.dart';
import 'package:i18n_editor/home/widget/new_project_dialog.dart';

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

    final keys = ref.watch(keysProvider);
    final selectedNode_ = ref.watch(selectedNode);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeMenuBar(),
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
                          data: (key_) => key_ == null
                              ? const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('empty'),
                                )
                              : buildKeyTree(key_, ref),
                          error: (e, s) => Text('$e\n$s'),
                          loading: () => const CircularProgressIndicator(),
                        ),
                      ),
                      const VerticalDivider(),
                      Expanded(
                        flex: 2,
                        child: selectedNode_ == null
                            ? const Center(child: Text('Select a key to edit'))
                            : const Editor(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
