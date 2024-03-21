import 'package:flutter_test/flutter_test.dart';
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
            'key5': 'value5',
          },
        },
        'ar.json': {
          'key1': 'قيمة1',
          'key2': 'قيمة2',
          'key3': {
            'key4': 'قيمة4',
            'key5': 'قيمة5',
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
      final secondId = state.elementOrder[1];
      final newState = state.addNode(
        NewLeaf(getNewId(state.elementOrder.toList()), key: 'key6', values: {
          'en.json': 'value6',
          'ar.json': 'قيمة6',
        }),
        parentId: state.elementOrder.first,
        afterId: secondId,
      );

      expect(newState.elements[newState.elementOrder[2]]!.key, 'key6');
    });
  });
}
