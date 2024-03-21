import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:i18n_editor/home/provider/movements.dart';
import 'package:riverpod/riverpod.dart';

final selectedLeafProvider = FutureProvider<Leaf?>(
  (ref) async {
    final address = ref.watch(selectedAddressProvider);
    if (address == null) return null;
    final rootNode = await ref.watch(keysProvider.future);
    if (rootNode == null) return null;

    return getLeaf(
      rootNode,
      address,
    );
  },
  name: 'selectedLeaf',
);
final selectedAddressProvider = StateProvider<List<dynamic>?>(
  (ref) => null,
  name: 'selectedAddress',
);
