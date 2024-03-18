import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:i18n_editor/home/provider/modified_nodes_porvider.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:i18n_editor/home/provider/selected_leaf.dart';
import 'package:i18n_editor/utils.dart';
import 'package:path/path.dart';
import 'package:riverpod/riverpod.dart';

final keysProvider = AsyncNotifierProvider<KeysNotifier, KeysState>(
  KeysNotifier.new,
  name: 'keys',
);

typedef KeysState = Parent?;

class KeysNotifier extends AsyncNotifier<KeysState> {
  @override
  Future<KeysState> build() async {
    final configs = await ref.watch(i18nConfigsProvider.future);
    if (configs == null) return null;
    final files = await ref.watch(filesNotifierProvider.future);
    if (files == null) return null;

    final baseLocalePath = '${configs.filePrefix}.json';

    return extractNodes(baseLocalePath, files);
  }

  void updateLeaf(Leaf leaf) {
    if (state.value == null) return;

    state = AsyncData(
      setLeafValue(state.value!, leaf.address, leaf.values) as Parent,
    );

    ref
        .read(modifiedNodesProvider.notifier)
        .add(address: leaf.address, changedFiles: leaf.values.keys.toList());
  }

  void addEmptyLeaf(List<dynamic> address) {
    if (state.value == null) return;
    final leaf = Leaf(
      address,
      const {},
    );
    state = AsyncData(
      setLeafValue(state.value!, address, leaf.values) as Parent,
    );
    ref.read(modifiedNodesProvider.notifier).add(
      address: address,
      changedFiles: [],
    );
  }

  Future<void> updateSelectedLeaf(String file, String value) async {
    if (state.value == null) return;
    final selectedNode_ = await ref.read(selectedLeafProvider.future);
    if (selectedNode_ == null) return;
    final node = selectedNode_.updateFileValue(file, value);

    state = AsyncData(
      setLeafValue(state.value!, node.address, node.values) as Parent,
    );

    ref.read(modifiedNodesProvider.notifier).add(
      address: selectedNode_.address,
      changedFiles: [file],
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

    void addData(dynamic json) {
      if (json is Parent) {
        for (final child in json.children) {
          addData(child);
        }
      } else if (json is Leaf) {
        for (final file in files) {
          final content = json.values[file];
          final address = json.address;

          if (content != null) {
            filesData[file] = filesData[file] ?? {};
            dynamic current = filesData[file]!;
            for (final key in address) {
              if (key == address.last) {
                current[key] = content;
              } else {
                current[key] = current[key] ?? {};
                current = current[key];
              }
            }
          }
        }
      }
    }

    for (final item in data.children) {
      addData(item);
    }

    for (final MapEntry(key: path, value: content) in filesData.entries) {
      final stringContent = encoder.convert(content);
      await File(join(projectPath, path)).writeAsString(stringContent);
    }

    ref.invalidate(modifiedNodesProvider);
  }

  void resetLeafChanges(Leaf node, String file) {
    if (state.value == null) return;
    final files = ref.read(filesNotifierProvider).value;
    if (files == null) return;
    final data = files[file];
    if (data == null) return;

    final original = getMapValue(data, node.address);
    final newValue = node.updateFileValue(file, original);

    state = AsyncData(
      setLeafValue(state.value!, node.address, newValue.values) as Parent,
    );

    ref.read(modifiedNodesProvider.notifier).remove(
      address: node.address,
      changedFiles: [file],
    );
  }
}

Parent extractNodes(
  String baseLocalePath,
  Files files,
) {
  final filesCopy = Map<String, Map<String, dynamic>>.from(files);
  final baseJson = filesCopy.remove(baseLocalePath);

  Node extractNode(dynamic jsonValue, [List<dynamic> path = const []]) {
    if (jsonValue is Map) {
      final children = <Node>[];
      jsonValue.forEach((key, value) {
        final newPath = [...path, key];
        children.add(extractNode(value, newPath));
      });
      return Parent(children, path);
    } else if (jsonValue is List) {
      final children = <Node>[];
      for (int i = 0; i < jsonValue.length; i++) {
        final newPath = [...path, i];
        children.add(extractNode(jsonValue[i], newPath));
      }
      return Parent(children, path);
    } else {
      final values = filesCopy.map(
        (file, data) => MapEntry(
          file,
          getMapValue(data, path),
        ),
      );

      values[baseLocalePath] = jsonValue;

      return Leaf(path, values);
    }
  }

  return extractNode(baseJson) as Parent;
}

Leaf? getLeaf(Node node, List<dynamic> address) {
  if (node is Leaf && listEquals(node.address, address)) {
    return node;
  } else if (node is Parent) {
    Leaf? result;
    for (final child in node.children) {
      result = getLeaf(child, address);
      if (result != null) return result;
    }
  }

  return null;
}

Node setLeafValue(
  Node? oldNode,
  List<dynamic> address,
  Map<String, String?> values,
) {
  assert(address.isNotEmpty);
  final tail = address.sublist(0, address.length - 1);
  Node newNode = oldNode ?? const Parent([], []);

  if (newNode is Leaf && listEquals(newNode.address, address)) {
    newNode = Leaf(newNode.address, values);
  } else if (newNode is Parent) {
    for (int i = 0; i < newNode.children.length; i++) {
      final child = newNode.children[i];
      final beginsWithAddress = tail.length >= child.address.length &&
          child.address.indexed.every(
            (e) => tail[e.$1] == e.$2,
          );
      if (beginsWithAddress) {
        newNode.children[i] = setLeafValue(child, address, values) as Parent;

        break;
      }
    }
  }

  return newNode;
}
