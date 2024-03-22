import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:i18n_editor/home/model/keys_state.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:i18n_editor/home/provider/movements.dart';
import 'package:i18n_editor/utils.dart';
import 'package:riverpod/riverpod.dart';

final emptyNewKeysState = (
  nodes: IMap<int, NewNode>(),
  parentTree: IMap<int, int?>(),
  nodeOrder: IList<int>(),
);

class NewKeysNotifier extends AsyncNotifier<NewKeysState?> {
  @override
  Future<NewKeysState?> build() async {
    final configs = await ref.watch(i18nConfigsProvider.future);
    if (configs == null) return null;
    final files = await ref.watch(filesNotifierProvider.future);
    if (files == null) return null;

    final baseLocalePath = '${configs.filePrefix}.json';

    return extractNodes(baseLocalePath, files);
  }

  NewKeysState? extractNodes(
    String baseLocalePath,
    Files files,
  ) {
    final filesCopy = Map<String, Map<String, dynamic>>.from(files);
    final baseJson = filesCopy.remove(baseLocalePath);
    if (baseJson == null) return null;

    var nodes = <int, NewNode>{};
    var parentTree = <int, int>{};
    List<int> nodeOrder = <int>[];

    int decodeNode(
      Object jsonValue, [
      List<Object>? path,
    ]) {
      final nodeKey = path?.last;
      final id = getNewId(nodeOrder);
      nodeOrder.add(id);

      switch (jsonValue) {
        case Map<String, Object?> map:
          nodes[id] = NewNode(id, key: nodeKey);
          for (final MapEntry(:key, :value) in map.entries) {
            if (value == null) continue;
            final newPath = [...?path, key];
            final childId = decodeNode(value, newPath);
            parentTree[childId] = id;
          }
        case List<Object?> list:
          nodes[id] = NewNode(id, key: nodeKey);
          for (int i = 0; i < list.length; i++) {
            final child = list[i];
            if (child == null) continue;

            final newPath = [...?path, i];
            final childId = decodeNode(child, newPath);
            parentTree[childId] = id;
          }
        case String string:
          final values = filesCopy.map(
            (file, data) => MapEntry(
              file,
              getMapValue(data, path!),
            ),
          );

          values[baseLocalePath] = string;

          final leaf = NewLeaf(id, key: nodeKey, values: values);
          nodes[id] = leaf;
      }

      return id;
    }

    for (final entry in baseJson.entries) {
      decodeNode(entry.value, [entry.key]);
    }

    return (
      nodes: nodes.lock,
      parentTree: parentTree.lock,
      nodeOrder: nodeOrder.lock,
    );
  }

  void add(
    NewNode node, {
    required int? newParentId,
    int? beforeId,
    int? afterId,
  }) {
    state = AsyncData(state.value?.addNode(
      node,
      parentId: newParentId,
      beforeId: beforeId,
      afterId: afterId,
    ));
  }

  void remove(NewNode node) {
    state = AsyncData(state.value?.removeNode(node));
  }
}
