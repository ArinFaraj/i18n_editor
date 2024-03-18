import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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

final keysProvider = AsyncNotifierProvider<KeysNotifier, KeysState>(
  KeysNotifier.new,
  name: 'keys',
);

typedef KeysState = JsonObject?;

class KeysNotifier extends AsyncNotifier<KeysState> {
  @override
  Future<KeysState> build() async {
    final configs = await ref.watch(i18nConfigsProvider.future);
    if (configs == null) return null;
    final files = await ref.watch(filesNotifierProvider.future);
    if (files == null) return null;

    return extractAllNodes('${configs.filePrefix}.json', files);
  }

  void updateNode(JsonString node) {
    if (state.value == null) return;

    state = AsyncData(
      setJsonStringValue(state.value!, node.address, node.values) as JsonObject,
    );

    ref
        .read(modifiedNodesProvider.notifier)
        .add(address: node.address, changedFiles: node.values.keys.toList());
  }

  void addEmptyNode(List<dynamic> address) {
    if (state.value == null) return;
    final node = JsonString(
      address,
      const {},
    );
    state = AsyncData(
      setJsonStringValue(state.value!, address, node.values) as JsonObject,
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
      setJsonStringValue(state.value!, node.address, node.values) as JsonObject,
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

    for (final item in data.children) {
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
      setJsonStringValue(state.value!, node.address, newValue.values)
          as JsonObject,
    );

    ref.read(modifiedNodesProvider.notifier).remove(
      address: node.address,
      changedFiles: [file],
    );
  }
}

JsonObject extractAllNodes(
  String baseLocalePath,
  Files files,
) {
  final filescopy = Map<String, Map<String, dynamic>>.from(files);
  final baseJson = filescopy.remove(baseLocalePath);

  Node extractNodes(dynamic jsonValue, [List<dynamic> path = const []]) {
    if (jsonValue is Map) {
      final children = <Node>[];
      jsonValue.forEach((key, value) {
        final newPath = [...path, key];
        children.add(extractNodes(value, newPath));
      });
      return JsonObject(children, path);
    } else if (jsonValue is List) {
      final children = <Node>[];
      for (int i = 0; i < jsonValue.length; i++) {
        final newPath = [...path, i];
        children.add(extractNodes(jsonValue[i], newPath));
      }
      return JsonObject(children, path);
    } else {
      final values = filescopy.map(
        (file, data) => MapEntry(
          file,
          getValue(data, path),
        ),
      );

      values[baseLocalePath] = jsonValue;

      return JsonString(path, values);
    }
  }

  return extractNodes(baseJson) as JsonObject;
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

Node setJsonStringValue(
  Node? oldNode,
  List<dynamic> address,
  Map<String, String?> values,
) {
  assert(address.isNotEmpty);
  final tail = address.sublist(0, address.length - 1);
  Node newNode = oldNode ?? const JsonObject([], []);

  if (newNode is JsonString && listEquals(newNode.address, address)) {
    newNode = JsonString(newNode.address, values);
  } else if (newNode is JsonObject) {
    for (int i = 0; i < newNode.children.length; i++) {
      final child = newNode.children[i];
      final beginsWithAddress = tail.length >= child.address.length &&
          child.address.indexed.every(
            (e) => tail[e.$1] == e.$2,
          );
      if (beginsWithAddress) {
        newNode.children[i] =
            setJsonStringValue(child, address, values) as JsonObject;

        break;
      }
    }
  }

  return newNode;
}

JsonString? getNode(Node? node, List<dynamic>? address) {
  if (address == null || node == null) return null;
  if (node is JsonString && node.address == address) {
    return node;
  } else if (node is JsonObject) {
    JsonString? result;
    for (final child in node.children) {
      result = getNode(child, address);
      if (result != null) return result;
    }
  }
  return null;
}
