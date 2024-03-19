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
      setLeaf(state.value!, leaf.address, leaf.values),
    );

    ref
        .read(modifiedNodesProvider.notifier)
        .add(address: leaf.address, changedFiles: leaf.values.keys.toList());
  }

  void addEmptyLeaf(List<Object> address) {
    if (state.value == null) return;
    final leaf = Leaf(
      address,
      const {},
    );
    state = AsyncData(
      setLeaf(state.value!, address, leaf.values),
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
      setLeaf(state.value!, node.address, node.values),
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
      setLeaf(state.value!, node.address, newValue.values),
    );

    ref.read(modifiedNodesProvider.notifier).remove(
      address: node.address,
      changedFiles: [file],
    );
  }

  void removeLeaf(List<Object> address) {
    if (state.value == null) return;
    state = AsyncData(
      deleteLeaf(state.value!, address),
    );
    ref
        .read(modifiedNodesProvider.notifier)
        .add(address: address, changedFiles: []);
  }
}

Parent deleteLeaf(Parent node, List<Object> address) {
  final children = node.children
      .where((child) => !listEquals(child.address, address))
      .map((child) {
    if (child is Parent) {
      return deleteLeaf(child, address);
    }
    return child;
  }).toList();

  return Parent(children, node.address);
}

Parent extractNodes(
  String baseLocalePath,
  Files files,
) {
  final filesCopy = Map<String, Map<String, dynamic>>.from(files);
  final baseJson = filesCopy.remove(baseLocalePath);

  Node extractNode(dynamic jsonValue, [List<Object> path = const []]) {
    if (jsonValue is Map) {
      final children = <Node>[];
      jsonValue.forEach((key, value) {
        final newPath = [...path, key as Object];
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

Parent setLeaf(
  Node oldNode,
  List<Object> address,
  Map<String, String?> values,
) {
  // Helper function to create a new node (leaf or parent) with the given address and values.
  Node createNewNode(List<Object> address, Map<String, String?> values,
      List<dynamic> currentAddress) {
    var index = currentAddress.length;
    Node newNode = Leaf(address, values);
    while (index < address.length - 1) {
      newNode = Parent([newNode], address.sublist(0, index + 1));
      index++;
    }
    return newNode;
  }

  // Helper function to recursively copy the tree and set/update the leaf.
  Node setLeafRecursive(
      Node node, List<Object> address, Map<String, String?> values) {
    if (node is Leaf && node.address.equals(address)) {
      // If the current node is the target leaf, update its values.
      return node.copyWith(values: values);
    } else if (node is Parent) {
      // If the current node is a parent, recursively update its children.
      var newChildren = <Node>[];
      var found = false;
      for (var child in node.children) {
        if (address.startsWith(child.address)) {
          found = true;
          newChildren.add(setLeafRecursive(child, address, values));
        } else {
          newChildren.add(child);
        }
      }
      // If the target leaf was not found in the children, create a new leaf or parent as needed.
      if (!found) {
        Node newNode = createNewNode(address, values, node.address);
        newChildren.add(newNode);
      }
      return Parent(newChildren, node.address);
    }
    return node;
  }

  // Check if the oldNode is a Parent and start the recursion.
  if (oldNode is Parent) {
    return setLeafRecursive(oldNode, address, values) as Parent;
  } else {
    throw Exception('The root node must be a Parent node.');
  }
}

// Extension method to compare two lists for equality and to check if a list starts with another list.
extension ListExtensions on List {
  bool equals(List list) {
    return listEquals(this, list);
  }

  bool startsWith(List list) {
    if (length < list.length) return false;
    for (int i = 0; i < list.length; i++) {
      if (this[i] != list[i]) return false;
    }
    return true;
  }
}
