import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:riverpod/riverpod.dart';

final selectedLeafProvider = FutureProvider<Leaf?>(
  (ref) async {
    final address = ref.watch(selectedNodeIdProvider);
    if (address == null) return null;
    final rootNode = await ref.watch(keysProvider.future);
    if (rootNode == null) return null;

    return rootNode.nodes[address] as Leaf?;
  },
  name: 'selectedLeaf',
);
final selectedNodeIdProvider = StateProvider<int?>(
  (ref) => null,
  name: 'selectedAddress',
);
