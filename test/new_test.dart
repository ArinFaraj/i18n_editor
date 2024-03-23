import 'package:flutter_test/flutter_test.dart';
import 'package:i18n_editor/home/model/keys_state.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:i18n_editor/home/provider/movements.dart';

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
        Leaf(getNewId(state.nodeOrder.toList()), key: 'key6', values: {
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
        Leaf(getNewId(state.nodeOrder.toList()), key: 'key6', values: {
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
        Leaf(getNewId(state.nodeOrder.toList()), key: 'key6', values: {
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
        Leaf(getNewId(state.nodeOrder.toList()), key: 'key6', values: {
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

    test('move node after second node', () {
      final state = newKeysNotifier.extractNodes(baseLocalePath, files)!;
      final secondId = state.nodeOrder[1];
      final node = state.nodes[state.nodeOrder.first]!;
      final newState = state.moveNode(
        node,
        newParentId: state.nodeOrder.first,
        afterId: secondId,
      );
      expect(newState.nodeOrder[1], node.id);
    });

    test('move node into a sub node', () {
      final state = newKeysNotifier.extractNodes(baseLocalePath, files)!;
      final node = state.nodes[state.nodeOrder.first]!;
      final newParentId = state.nodeOrder[2];
      final newState = state.moveNode(
        node,
        newParentId: newParentId,
      );
      expect(newState.parentTree[node.id], newParentId);
    });

    test('move node outside a sub node', () {
      final state = newKeysNotifier.extractNodes(baseLocalePath, files)!;
      final node = state.nodes[state.nodeOrder[3]]!;
      final newState = state.moveNode(
        node,
        newParentId: null,
      );
      expect(newState.parentTree[node.id], null);
    });

    test('update node', () {
      final state = newKeysNotifier.extractNodes(baseLocalePath, files)!;
      final node = state.nodes[state.nodeOrder.first]!;
      final newState = state.updateNode(
        node,
        Leaf(
          node.id,
          key: 'key8',
          values: {
            'en.json': 'value8',
            'ar.json': 'قيمة8',
          },
        ),
      );
      expect(newState.nodes[node.id]!.key, 'key8');
    });

    test('add empty leaf at address', () {
      final state = newKeysNotifier.extractNodes(baseLocalePath, files)!;
      final newState = state.addLeafAtAddress(['key9']);
      expect(newState.nodes[newState.nodeOrder.last]!.key, 'key9');
    });
    test('add empty leaf at address with existing parent', () {
      final state = newKeysNotifier.extractNodes(baseLocalePath, files)!;
      final newState = state.addLeafAtAddress(['key3', 'key6']);
      expect(newState.nodes[newState.nodeOrder.last]!.key, 'key6');
    });
    test('add empty leaf at address with non existing parent', () {
      final state = newKeysNotifier.extractNodes(baseLocalePath, files)!;
      final newState = state.addLeafAtAddress(['key10', 'key11', 'key6']);
      final order = newState.nodeOrder.reversed;
      expect(newState.nodes[order[0]]!.key, 'key6');
      expect(newState.nodes[order[1]]!.key, 'key11');
      expect(newState.nodes[order[2]]!.key, 'key10');
    });
  });
}
