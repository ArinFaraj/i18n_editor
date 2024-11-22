import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';

void showNewKeyDialog(BuildContext context, [List<dynamic>? prefix]) {
  showDialog(
    context: context,
    builder: (context) {
      return HookConsumer(builder: (context, WidgetRef ref, child) {
        final text = convertAddressToString(prefix);
        final controller = useTextEditingController(
          text: text != null ? '$text.' : '',
        );

        return AlertDialog(
          title: const Text('New Key'),
          content: TextField(
            autofocus: true,
            controller: controller,
            onSubmitted: (_) => _newKey(ref, controller, context),
            decoration: const InputDecoration(
              labelText: 'Key',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _newKey(ref, controller, context),
              child: const Text('Create'),
            ),
          ],
        );
      });
    },
  );
}

void _newKey(
    WidgetRef ref, TextEditingController controller, BuildContext context) {
  try {
    ref.read(keysProvider.notifier).addEmptyLeafAtAddress(
          convertStringToAddress(controller.text),
        );
    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );
  }
}

void showMoveKeyDialog(BuildContext context, Node node, List<Object> address) {
  showDialog(
    context: context,
    builder: (context) {
      return HookConsumer(builder: (context, WidgetRef ref, child) {
        final controller = useTextEditingController(
          text: convertAddressToString(address),
        );
        return AlertDialog(
          title: const Text('Move Key'),
          content: TextField(
            autofocus: true,
            controller: controller,
            onSubmitted: (_) => _moveKey(ref, node, controller, context),
            decoration: const InputDecoration(
              labelText: 'Key',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _moveKey(ref, node, controller, context);
              },
              child: const Text('Move'),
            ),
          ],
        );
      });
    },
  );
}

void _moveKey(WidgetRef ref, Node node, TextEditingController controller,
    BuildContext context) {
  try {
    ref.read(keysProvider.notifier).moveToAddress(
          node,
          convertStringToAddress(controller.text),
        );
    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );
  }
}

String? convertAddressToString(List<dynamic>? address) {
  return address?.map((e) => e.toString()).join('.');
}

List<String> convertStringToAddress(String address) {
  return address.split('.').toList();
}
