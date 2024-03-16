import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
    // final baseFile = ref.watch(
    //     i18nConfigsProvider.select((data) => data.valueOrNull?.defaultLocale));

    final baseLocaleJson = ref.watch(baseLocaleJsonProvider);
    final files = ref.watch(filesNotifierProvider);

    if (baseLocaleJson.valueOrNull == null || files.valueOrNull == null) {
      return const CircularProgressIndicator();
    }

    final baseLocalePath = ref.watch(baseLocalePathProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocaleKeyEditor(
          file: (baseLocalePath.requireValue!, baseLocaleJson.requireValue!),
        ),
        for (final file in files.requireValue!)
          LocaleKeyEditor(
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
  });
  final I18nFile file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _debouncer = Debouncer(milliseconds: 100);
    final selectedNode_ = ref.watch(selectedNode)!;
    final value = selectedNode_.values[file.$1];
    final textController = useTextEditingController(text: value);
    final isModified = ref
            .watch(modifiedNodesProvider)[selectedNode_.address]
            ?.contains(file.$1) ??
        false;

    useEffect(() {
      textController.text = value ?? '';
      return null;
    }, [value]);

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
            Text(extractBaseName(file.$1)),
            const SizedBox(height: 8),
            Directionality(
              textDirection: direction.value,
              child: TextField(
                controller: textController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _debouncer.run(() {
                    ref
                        .read(keysProvider.notifier)
                        .updateSelectedNode(file.$1, value);
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
