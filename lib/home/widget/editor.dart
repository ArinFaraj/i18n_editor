import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/base_json_provider.dart';
import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:i18n_editor/home/provider/modified_nodes_porvider.dart';
import 'package:i18n_editor/utils.dart';
import 'package:intl/intl.dart' as intl;

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

    final baseLocalePath = ref.watch(baseLocalePathProvider);
    final selectedNode_ = ref.watch(selectedNodeProvider);
    var selected = selectedNode_.value;
    if (selected == null) return const LinearProgressIndicator();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocaleKeyEditor(
          selectedNode: selected,
          file: baseLocalePath.value!,
        ),
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
    final debouncer = Debouncer(milliseconds: 100);
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
          ? Theme.of(context).colorScheme.surface
          : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(extractBaseName(file)),
            const SizedBox(height: 8),
            Directionality(
              textDirection: direction.value,
              child: TextField(
                focusNode: focusNode,
                controller: textController,
                decoration: InputDecoration(
                  border: null,
                  suffix: isModified
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            focusNode.unfocus();
                            ref
                                .read(keysProvider.notifier)
                                .resetNode(selectedNode, file);
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  debouncer.run(() {
                    ref
                        .read(keysProvider.notifier)
                        .updateSelectedNode(file, value);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String extractBaseName(String path) {
  final parts = path.split(RegExp('[/\\\\]'));
  return parts[parts.length - 1];
}

bool isRTL(String text) {
  return intl.Bidi.detectRtlDirectionality(text);
}
