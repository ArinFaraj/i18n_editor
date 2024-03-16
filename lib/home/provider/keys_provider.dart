import 'dart:async';

import 'package:i18n_editor/home/provider/base_json_provider.dart';
import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/home/provider/modified_nodes_porvider.dart';
import 'package:riverpod/riverpod.dart';

final selectedNode = StateProvider<JsonString?>(
  (ref) => null,
  name: 'selectedNode',
);
final keysProvider = AsyncNotifierProvider<KeysNotifier, List<Node>?>(
  KeysNotifier.new,
  name: 'baseLocaleKeys',
);

class KeysNotifier extends AsyncNotifier<List<Node>?> {
  @override
  Future<List<Node>?> build() async {
    final baseLocalePath = await ref.watch(baseLocalePathProvider.future);
    if (baseLocalePath == null) return null;
    final baseJson = await ref.watch(baseLocaleJsonProvider.future);
    if (baseJson == null) return null;
    final otherFiles = await ref.watch(filesNotifierProvider.future);
    if (otherFiles == null) return null;

    return extractAllNodes(baseLocalePath, baseJson, otherFiles);
  }

  void updateNode(JsonString node) {
    if (state.value == null) return;

    state = AsyncData(
      setValue(state.value!, node.address, node.values),
    );

    ref
        .read(modifiedNodesProvider.notifier)
        .add(address: node.address, changedFiles: node.values.keys.toList());
  }

  void updateSelectedNode(String file, String value) {
    if (state.value == null) return;
    final selectedNode_ = ref.read(selectedNode);
    if (selectedNode_ == null) return;
    final node = selectedNode_.updateKey(file, value);

    state = AsyncData(
      setValue(state.value!, node.address, node.values),
    );
    ref.read(modifiedNodesProvider.notifier).add(
      address: selectedNode_.address,
      changedFiles: [file],
    );
  }

//   Future<void> saveFiles() async {
//     final modifiedNodes = ref.read(modifiedNodesProvider);
//     final files = ref.read(filesNotifierProvider);
//     if (modifiedNodes.isEmpty) return;
//     final modifiedFiles = modifiedNodes.entries
//         .map((e) => e.key.last)
//         .toSet()
//         .map((file) => files[file]!)
//         .toList();
//     await Future.wait(modifiedFiles.map((file) async {
//       final json = await file.readAsString();
//       final updatedJson = updateJson(json, modifiedNodes, file.$1);
//       await file.writeAsString(updatedJson);
//     }));
//     ref.read(modifiedNodesProvider.notifier).clear();
//   }
}

sealed class Node {
  const Node(this.address);

  final List<dynamic> address;
}

class JsonString extends Node {
  const JsonString(super.address, this.values);
  final Map<String, String?> values;

  JsonString copyWith({Map<String, String?>? values}) {
    return JsonString(address, values ?? this.values);
  }

  JsonString updateKey(String key, String? value) {
    return copyWith(
      values: Map.from(values)..[key] = value,
    );
  }
}

class JsonObject extends Node {
  const JsonObject(this.children, super.address);
  final List<Node> children;
}

List<Node> extractAllNodes(
  String baseLocalePath,
  dynamic json,
  List<I18nFile> otherFiles,
) {
  List<Node> extractNodes(dynamic json, [List<dynamic> path = const []]) {
    final nodes = <Node>[];

    if (json is Map) {
      final children = <Node>[];
      json.forEach((key, value) {
        final newPath = [...path, key];
        children.addAll(extractNodes(value, newPath));
      });
      nodes.add(JsonObject(children, path));
    } else if (json is List) {
      for (int i = 0; i < json.length; i++) {
        final newPath = [...path, i];
        nodes.addAll(extractNodes(json[i], newPath));
      }
    } else {
      final values = Map.fromEntries(
          otherFiles.map((file) => MapEntry(file.$1, getValue(file.$2, path))));
      values[baseLocalePath] = json;

      nodes.add(JsonString(path, values));
    }

    return nodes;
  }

  return extractNodes(json);
}

String? getValue(Map<String, dynamic> json, List<dynamic> address) {
  dynamic value = json;
  for (final key in address) {
    if (value is Map) {
      value = value[key];
    } else if (value is List) {
      value = value[key];
    } else {
      return null;
    }
  }
  return value;
}

List<Node> setValue(
    List<Node> oldNodes, List<dynamic> address, Map<String, String?> values) {
  List<Node> newNodes = [];
  for (final node in oldNodes) {
    if (node is JsonString && node.address == address) {
      newNodes.add(JsonString(node.address, values));
    } else if (node is JsonObject) {
      newNodes.add(
          JsonObject(setValue(node.children, address, values), node.address));
    } else {
      newNodes.add(node);
    }
  }
  return newNodes;
}
