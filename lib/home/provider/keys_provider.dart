import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:i18n_editor/home/provider/modified_nodes_porvider.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:path/path.dart';
import 'package:riverpod/riverpod.dart';

final selectedNodeProvider = FutureProvider<JsonString?>(
  (ref) async => getNode(
      await ref.watch(keysProvider.future), ref.watch(selectedAddressProvider)),
  name: 'selectedNode',
);

final selectedAddressProvider = StateProvider<List<dynamic>?>(
  (ref) => null,
  name: 'selectedAddress',
);

final keysProvider = AsyncNotifierProvider<KeysNotifier, List<Node>?>(
  KeysNotifier.new,
  name: 'keys',
);

class KeysNotifier extends AsyncNotifier<List<Node>?> {
  @override
  Future<List<Node>?> build() async {
    final configs = await ref.watch(i18nConfigsProvider.future);
    if (configs == null) return null;
    final files = await ref.watch(filesNotifierProvider.future);
    if (files == null) return null;

    return extractAllNodes('${configs.filePrefix}.json', files);
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

  void addEmptyNode(List<dynamic> address) {
    if (state.value == null) return;
    final node = JsonString(
      address,
      {},
    );
    state = AsyncData(
      setValue(state.value!, address, node.values),
    );
    ref.read(modifiedNodesProvider.notifier).add(
      address: address,
      changedFiles: [],
    );
  }

  Future<void> updateSelectedNode(String file, String value) async {
    if (state.value == null) return;
    final selectedNode_ = await ref.read(selectedNodeProvider.future);
    if (selectedNode_ == null) return;
    final node = selectedNode_.updateFileValue(file, value);

    state = AsyncData(
      setValue(state.value!, node.address, node.values),
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
      if (json is JsonObject) {
        for (final child in json.children) {
          addData(child);
        }
      } else if (json is JsonString) {
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

    for (final item in data) {
      addData(item);
    }

    for (final MapEntry(key: path, value: content) in filesData.entries) {
      final stringContent = encoder.convert(content);
      await File(join(projectPath, path)).writeAsString(stringContent);
    }

    ref.invalidate(modifiedNodesProvider);
  }

  void resetNode(JsonString node, String file) {
    if (state.value == null) return;
    final files = ref.read(filesNotifierProvider).value;
    if (files == null) return;
    final data = files[file];
    if (data == null) return;

    final original = getValue(data, node.address);
    final newValue = node.updateFileValue(file, original);

    state = AsyncData(
      setValue(state.value!, node.address, newValue.values),
    );

    ref.read(modifiedNodesProvider.notifier).remove(
      address: node.address,
      changedFiles: [file],
    );
  }
}

List<Node> extractAllNodes(
  String baseLocalePath,
  Files files,
) {
  final filescopy = Map<String, Map<String, dynamic>>.from(files);
  final baseJson = filescopy.remove(baseLocalePath);

  List<Node> extractNodes(dynamic jsonValue, [List<dynamic> path = const []]) {
    final nodes = <Node>[];

    if (jsonValue is Map) {
      final children = <Node>[];
      jsonValue.forEach((key, value) {
        final newPath = [...path, key];
        children.addAll(extractNodes(value, newPath));
      });
      nodes.add(JsonObject(children, path));
    } else if (jsonValue is List) {
      for (int i = 0; i < jsonValue.length; i++) {
        final newPath = [...path, i];
        nodes.addAll(extractNodes(jsonValue[i], newPath));
      }
    } else {
      final values = filescopy.map(
        (file, data) => MapEntry(
          file,
          getValue(data, path),
        ),
      );

      values[baseLocalePath] = jsonValue;

      nodes.add(JsonString(path, values));
    }

    return nodes;
  }

  return extractNodes(baseJson);
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
  // final key = address.last;
  final tail = address.sublist(0, address.length - 1);

  List<Node> newNodes = [];
  for (final node in oldNodes) {
    if (node is JsonString && node.address == address) {
      newNodes.add(JsonString(node.address, values));
      continue;
    }

    final beginsWithAddress = tail.length >= node.address.length &&
        node.address.indexed.every(
          (e) => tail[e.$1] == e.$2,
        );

    if (node is JsonObject && beginsWithAddress) {
      newNodes.add(
          JsonObject(setValue(node.children, address, values), node.address));
      continue;
    }

    newNodes.add(node);
  }
  return newNodes;
}

JsonString? getNode(List<Node>? nodes, List<dynamic>? address) {
  if (address == null || nodes == null) return null;
  for (final node in nodes) {
    if (node is JsonString && node.address == address) {
      return node;
    } else if (node is JsonObject) {
      final result = getNode(node.children, address);
      if (result != null) return result;
    }
  }
  return null;
}
