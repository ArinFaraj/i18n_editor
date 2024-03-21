import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:i18n_editor/home/provider/modified_nodes_porvider.dart';
import 'package:i18n_editor/home/provider/movements.dart';
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

  void moveLeafAddress(List<Object> oldAddress, List<Object> newAddress) {
    state = AsyncData(
      moveLeaf(state.value!, oldAddress, newAddress),
    );

    ref.read(selectedAddressProvider.notifier).state = newAddress;
    ref.read(modifiedNodesProvider.notifier)
      ..remove(
        address: oldAddress,
        changedFiles: [],
      )
      ..add(
        address: newAddress,
        changedFiles: [],
      );
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
    ref.read(selectedAddressProvider.notifier).state = address;
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
        final address = json.address;
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
