import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:intl/intl.dart' as intl;

class Editor extends HookConsumerWidget {
  const Editor({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final baseFile = ref.watch(
    //     i18nConfigsProvider.select((data) => data.valueOrNull?.defaultLocale));

    // final baseLocaleJson = ref.watch(baseLocaleJsonProvider);
    final files = ref.watch(filesNotifierProvider);

    if (/*baseLocaleJson.valueOrNull == null ||*/ files.valueOrNull == null) {
      return const CircularProgressIndicator();
    }

    // final baseLocalePath = ref.watch(baseLocalePathProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LocaleKeyEditor(
        //   file: (baseLocalePath.requireValue!, baseLocaleJson.requireValue!),
        // ),
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
    final selectedNode_ = ref.watch(selectedNode);
    if (selectedNode_ == null) return const Text('No node selected');
    final value = ref.watch(keyValueProvider((file.$2, selectedNode_.address)));
    final textController = useTextEditingController();

    useEffect(() {
      textController.text = value ?? '';
      return null;
    }, [value]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(file.$1),
        Directionality(
          textDirection:
              isRTL(value ?? '') ? TextDirection.rtl : TextDirection.ltr,
          child: TextField(
            controller: textController,
          ),
        ),
      ],
    );
  }
}

bool isRTL(String text) {
  return intl.Bidi.detectRtlDirectionality(text);
}

final keyValueProvider =
    Provider.family<String?, (Map<String, dynamic>, List<dynamic>)>(
  (ref, input) {
    final (map, address) = input;

    dynamic value = map;
    for (final key in address) {
      if (value is Map) {
        value = value[key];
      } else if (value is List) {
        value = value[key];
      }
    }

    return value;
  },
);
