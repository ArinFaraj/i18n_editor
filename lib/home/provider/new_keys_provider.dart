import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:i18n_editor/home/provider/movements.dart';
import 'package:i18n_editor/utils.dart';
import 'package:riverpod/riverpod.dart';

typedef NewKeysState = ({
  IMap<int, NewNode> elements,
  IMap<int, int?> parentTree,
  IList<int> elementOrder,
});

extension NewKeyStateExt on NewKeysState {
  NewKeysState copyWith({
    IMap<int, NewNode>? elements,
    IMap<int, int?>? parentTree,
    IList<int>? elementOrder,
  }) =>
      (
        elements: elements ?? this.elements,
        parentTree: parentTree ?? this.parentTree,
        elementOrder: elementOrder ?? this.elementOrder,
      );

  NewKeysState addNode(
    NewNode node, {
    required int? parentId,
    int? beforeId,
    int? afterId,
  }) {
    // if (parentId == null && node is! NewNode) {
    //   throw TemplateException('NewNode expected');
    // }
    final nodeId = node.id;

    final IList<int> aelementOrder;

    if (beforeId != null) {
      final index = elementOrder.indexOf(beforeId);
      aelementOrder = elementOrder.insert(index, nodeId);
    } else if (afterId != null) {
      final index = elementOrder.indexOf(afterId) + 1;
      aelementOrder = elementOrder.insert(index, nodeId);
    } else {
      aelementOrder = elementOrder.add(nodeId);
    }

    var result = copyWith(
      elements: elements.add(nodeId, node),
      parentTree: parentTree.add(nodeId, parentId),
      elementOrder: aelementOrder,
    );

    return result;
  }
}

final emptyNewKeysState = (
  elements: IMap<int, NewNode>(),
  parentTree: IMap<int, int?>(),
  elementOrder: IList<int>(),
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

    var elements = <int, NewNode>{};
    var parentTree = <int, int?>{};
    List<int> elementOrder = <int>[];

    int decodeElement(
      Object jsonValue, [
      List<Object>? path,
    ]) {
      final nodeKey = path?.last;
      final id = getNewId(elementOrder);
      elementOrder.add(id);

      switch (jsonValue) {
        case Map<String, Object?> map:
          elements[id] = NewNode(id, key: nodeKey);
          for (final MapEntry(:key, :value) in map.entries) {
            if (value == null) continue;
            final newPath = [...?path, key];
            final childId = decodeElement(value, newPath);
            parentTree[childId] = id;
          }
        case List<Object?> list:
          elements[id] = NewNode(id, key: nodeKey);
          for (int i = 0; i < list.length; i++) {
            final child = list[i];
            if (child == null) continue;

            final newPath = [...?path, i];
            final childId = decodeElement(child, newPath);
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
          elements[id] = leaf;
      }

      return id;
    }

    decodeElement(baseJson);

    return (
      elements: elements.lock,
      parentTree: parentTree.lock,
      elementOrder: elementOrder.lock,
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
}
