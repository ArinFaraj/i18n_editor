import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:i18n_editor/home/provider/modified_nodes_porvider.dart';
import 'package:i18n_editor/home/provider/selected_leaf.dart';
import 'package:i18n_editor/utils.dart';

class Editor extends HookConsumerWidget {
  const Editor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(filesNotifierProvider).valueOrNull;

    if (files == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedNode_ = ref.watch(selectedLeafProvider);
    var selected = selectedNode_.value;
    if (selected == null) return const LinearProgressIndicator();

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files.keys.elementAt(index);

        return LocaleKeyEditor(
          node: selected,
          filePath: file,
        );
      },
    );
  }
}

class LocaleKeyEditor extends HookConsumerWidget {
  const LocaleKeyEditor({
    super.key,
    required this.filePath,
    required this.node,
  });
  final String filePath;
  final Leaf node;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modifiedFilesOfNode = ref.watch(modifiedNodesProvider)[node.id];
    final isModified = modifiedFilesOfNode?.contains(filePath) ?? false;

    final value = node.values[filePath];
    final textController = useTextEditingController(text: value);
    final focusNode = useFocusNode();

    final debouncer = useRef(
      Debouncer(milliseconds: 50),
    );

    useEffect(() {
      if (!focusNode.hasFocus) textController.text = value ?? '';
      return null;
    }, [value, focusNode]);

    final direction = useState(isRTL(textController.text));

    useEffect(() {
      void updateDirection() {
        direction.value = isRTL(textController.text);
      }

      textController.addListener(updateDirection);
      return () => textController.removeListener(updateDirection);
    }, [textController]);

    return Card(
      color: isModified
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1)
          : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(extractBaseName(filePath)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Directionality(
                    textDirection: direction.value,
                    child: TextField(
                      focusNode: focusNode,
                      maxLines: null,
                      controller: textController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.2),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        debouncer.value.run(() {
                          ref.read(keysProvider.notifier).updateNode(
                                node,
                                node.copyWith(
                                  values: {
                                    ...node.values,
                                    filePath: value,
                                  },
                                ),
                              );
                          ref.read(modifiedNodesProvider.notifier).add(
                            address: node.id,
                            changedFiles: [filePath],
                          );
                        });
                      },
                    ),
                  ),
                ),
                if (isModified)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        focusNode.unfocus();
                        ref
                            .read(keysProvider.notifier)
                            .resetLeafChanges(node, filePath);
                        ref.read(modifiedNodesProvider.notifier).remove(
                          address: node.id,
                          changedFiles: [filePath],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
