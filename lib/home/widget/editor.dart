import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:i18n_editor/home/provider/modified_nodes_porvider.dart';
import 'package:i18n_editor/utils.dart';

class Editor extends HookConsumerWidget {
  const Editor({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(filesNotifierProvider);

    if (files.valueOrNull == null) {
      return const CircularProgressIndicator();
    }

    final selectedNode_ = ref.watch(selectedNodeProvider);
    var selected = selectedNode_.value;
    if (selected == null) return const LinearProgressIndicator();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final file in files.requireValue!.keys)
          LocaleKeyEditor(
            selectedNode: selected,
            file: file,
          ),
      ],
    );
  }
}

class LocaleKeyEditor extends HookConsumerWidget {
  const LocaleKeyEditor({
    super.key,
    required this.file,
    required this.selectedNode,
  });
  final String file;
  final JsonString selectedNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debouncer = useRef(Debouncer(milliseconds: 50));
    final value = selectedNode.values[file];
    final isModified = ref
            .watch(modifiedNodesProvider)[selectedNode.address]
            ?.contains(file) ??
        false;
    final textController = useTextEditingController(text: value);
    final focusNode = useFocusNode();

    useEffect(() {
      if (!focusNode.hasFocus) textController.text = value ?? '';
      return null;
    }, [value, focusNode]);

    final direction = useState(TextDirection.ltr);

    useEffect(() {
      void updateDirection() {
        direction.value =
            isRTL(textController.text) ? TextDirection.rtl : TextDirection.ltr;
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
            Text(extractBaseName(file)),
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
                            .surfaceVariant
                            .withOpacity(0.2),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        debouncer.value.run(() {
                          ref
                              .read(keysProvider.notifier)
                              .updateSelectedNode(file, value);
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
                            .resetNode(selectedNode, file);
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
