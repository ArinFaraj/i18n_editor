import 'package:i18n_editor/home/model/keys_state.dart';
import 'package:i18n_editor/home/provider/selected_leaf.dart';
import 'package:riverpod/riverpod.dart';

import 'dart:convert';
import 'dart:io';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:i18n_editor/home/provider/keys_traverse.dart';
import 'package:i18n_editor/home/provider/modified_nodes_porvider.dart';
import 'package:i18n_editor/home/provider/movements.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:i18n_editor/utils.dart';
import 'package:path/path.dart';

final emptyNewKeysState = (
  nodes: IMap<int, Node>(),
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

    var nodes = <int, Node>{};
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
          nodes[id] = Parent(id, key: nodeKey);
          for (final MapEntry(:key, :value) in map.entries) {
            if (value == null) continue;
            final newPath = [...?path, key];
            final childId = decodeNode(value, newPath);
            parentTree[childId] = id;
          }
        case List<Object?> list:
          nodes[id] = Parent(id, key: nodeKey);
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

          final leaf = Leaf(id, key: nodeKey, values: values);
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

  Future<void> saveFiles() async {
    final projectPath = ref.watch(projectManagerProvider);
    if (projectPath == null) return;
    final files = (await ref.read(filesNotifierProvider.future))?.keys.toList();
    if (files == null) return;
    final data = state.value;
    if (data == null) return;

    const encoder = JsonEncoder.withIndent('  ');
    final filesData = <String, Map<String, dynamic>>{};

    void addData(Object json) {
      if (json is Leaf) {
        final address = data.getAddress(json);
        final last = address.last;
        final isInt = last is int;
        for (final file in files) {
          final content = json.values[file];
          if (content == null) continue;
          filesData[file] = filesData[file] ?? {};
          dynamic current = filesData[file]!;
          for (final key in address) {
            if (key == last) {
              current[key] = content;
            } else if (isInt && key == address[address.length - 2]) {
              current[key] = current[key] ?? [];
              current = current[key];
            } else {
              current[key] = current[key] ?? {};
              current = current[key];
            }
          }
        }
      } else if (json is Node) {
        final children = data.getChildren(json);
        for (final child in children) {
          addData(child);
        }
      }
    }

    final rootNodes = data.nodeOrder
        .where((element) => data.parentTree[element] == null)
        .toList();

    for (final id in rootNodes) {
      final item = data.nodes[id];
      addData(item!);
    }

    for (final MapEntry(key: path, value: content) in filesData.entries) {
      final stringContent = encoder.convert(content);
      await File(join(projectPath, path)).writeAsString(stringContent);
    }

    ref.invalidate(modifiedNodesProvider);
  }

  void add(
    Node node, {
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

  void remove(Node node) {
    state = AsyncData(state.value?.removeNode(node));
  }

  void move(Node node, int newParentId, {int? beforeId, int? afterId}) {
    state = AsyncData(state.value?.moveNode(
      node,
      newParentId: newParentId,
      beforeId: beforeId,
      afterId: afterId,
    ));
  }

  void updateNode(Node currentNode, Node newNode) {
    state = AsyncData(state.value?.updateNode(currentNode, newNode));
  }

  void addEmptyLeafAtAddress(List<Object> address) {
    final result = state.value!.addLeafAtAddress(address);
    state = AsyncData(result.$1);
    ref.read(selectedNodeIdProvider.notifier).state = result.$2;
  }

  void resetLeafChanges(Leaf node, String filePath) {
    final files = ref.read(filesNotifierProvider).value;
    if (files == null) return;
    final data = files[filePath];

    if (data == null) return;
    // this will be wrong if the node is relocated,
    // consider storing the original address in the node
    final address = state.value!.getAddress(node);
    final original = getMapValue(data, address);
    final newValue = node.copyWith(values: {
      ...node.values,
      filePath: original,
    });

    state = AsyncData(state.value?.updateNode(node, newValue));
  }

  void moveToAddress(Node node, List<Object> address) {
    state = AsyncData(state.value?.moveNodeToAddress(node, address));
  }
}

final keysProvider = AsyncNotifierProvider<NewKeysNotifier, NewKeysState?>(
  NewKeysNotifier.new,
  name: 'keys',
);
