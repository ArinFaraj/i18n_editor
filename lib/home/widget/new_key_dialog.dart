import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';

void showNewKeyDialog(BuildContext context, [List<dynamic>? prefix]) {
  showDialog(
    context: context,
    builder: (context) {
      return HookConsumer(builder: (context, WidgetRef ref, child) {
        final controller = useTextEditingController(
          text: convertAddressToString(prefix),
        );

        return AlertDialog(
          title: const Text('New Key'),
          content: TextField(
            autofocus: true,
            controller: controller,
            onSubmitted: (_) => submit(ref, controller, context),
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
                submit(ref, controller, context);
              },
              child: const Text('Create'),
            ),
          ],
        );
      });
    },
  );
}

void submit(
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

// void showMoveKeyDialog(BuildContext context, List<Object> address) {
//   showDialog(
//     context: context,
//     builder: (context) {
//       return HookConsumer(builder: (context, WidgetRef ref, child) {
//         final controller = useTextEditingController(
//           text: convertAddressToString(address),
//         );
//         return AlertDialog(
//           title: const Text('Move Key'),
//           content: TextField(
//             autofocus: true,
//             controller: controller,
//             decoration: const InputDecoration(
//               labelText: 'Key',
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 try {
//                   ref.read(keysProvider.notifier).moveToAddress(
//                         address,
//                         convertStringToAddress(controller.text),
//                       );
//                   Navigator.pop(context);
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text(e.toString()),
//                     ),
//                   );
//                 }
//               },
//               child: const Text('Move'),
//             ),
//           ],
//         );
//       });
//     },
//   );
// }

String? convertAddressToString(List<dynamic>? address) {
  if (address == null) return null;
  return address.map((e) => e.toString()).join('.');
}

List<Object> convertStringToAddress(String address) {
  return address.split('.').map((e) {
    if (int.tryParse(e) != null) {
      return int.parse(e);
    }

    return e;
  }).toList();
}
