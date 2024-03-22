import 'package:flutter_test/flutter_test.dart';
import 'package:i18n_editor/home/model/keys_state.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/movements.dart';
import 'package:i18n_editor/home/provider/new_keys_provider.dart';

void main() {
  group('NewKeysNotifier', () {
    late Map<String, Map<String, Object>> files;
    late String baseLocalePath;
    late NewKeysNotifier newKeysNotifier;
    setUp(() {
      files = {
        'en.json': {
          'key1': 'value1',
          'key2': 'value2',
          'key3': {
            'key4': 'value4',
            'key5': [
              'value5',
              'value6',
            ],
          },
        },
        'ar.json': {
          'key1': 'قيمة1',
          'key2': 'قيمة2',
          'key3': {
            'key4': 'قيمة4',
            'key5': [
              'قيمة5',
              'قيمة6',
            ],
          },
        },
      };
      baseLocalePath = 'en.json';
      newKeysNotifier = NewKeysNotifier();
    });
    test('decode json', () {
      final _ = newKeysNotifier.extractNodes(baseLocalePath, files);
    });
    test('add node after second node', () {
      final state = newKeysNotifier.extractNodes(baseLocalePath, files)!;
      final secondId = state.nodeOrder[1];
      final newState = state.addNode(
        NewLeaf(getNewId(state.nodeOrder.toList()), key: 'key6', values: {
          'en.json': 'value7',
          'ar.json': 'قيمة7',
        }),
        parentId: state.nodeOrder.first,
        afterId: secondId,
      );

      expect(newState.nodes[newState.nodeOrder[2]]!.key, 'key6');
    });

    test('add node before second node', () {
      final state = newKeysNotifier.extractNodes(baseLocalePath, files)!;
      final secondId = state.nodeOrder[1];
      final newState = state.addNode(
        NewLeaf(getNewId(state.nodeOrder.toList()), key: 'key6', values: {
          'en.json': 'value7',
          'ar.json': 'قيمة7',
        }),
        parentId: state.nodeOrder.first,
        beforeId: secondId,
      );
      expect(newState.nodes[newState.nodeOrder[1]]!.key, 'key6');
    });

    test('add node without before or after', () {
      final state = newKeysNotifier.extractNodes(baseLocalePath, files)!;
      final newState = state.addNode(
        NewLeaf(getNewId(state.nodeOrder.toList()), key: 'key6', values: {
          'en.json': 'value7',
          'ar.json': 'قيمة7',
        }),
        parentId: state.nodeOrder.first,
      );
      expect(newState.nodes[newState.nodeOrder.last]!.key, 'key6');
    });

    test('add node with no parent', () {
      final state = newKeysNotifier.extractNodes(baseLocalePath, files)!;
      final newState = state.addNode(
        NewLeaf(getNewId(state.nodeOrder.toList()), key: 'key6', values: {
          'en.json': 'value7',
          'ar.json': 'قيمة7',
        }),
        parentId: null,
      );
      expect(newState.nodes[newState.nodeOrder.last]!.key, 'key6');
    });

    test('remove node', () {
      final state = newKeysNotifier.extractNodes(baseLocalePath, files)!;
      final node = state.nodes[state.nodeOrder.first]!;
      final newState = state.removeNode(node);
      expect(newState.nodes[node.id], null);
      expect(newState.nodeOrder.contains(node.id), false);
    });
  });
}
