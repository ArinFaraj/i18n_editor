import 'package:flutter_test/flutter_test.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/movements.dart';

void main() {
  group('KeysNotifier', () {
    test('setValue update existing root value', () {
      const nodes = Parent([
        Leaf(['address1'], {'file1': 'value1'}),
      ], []);

      final newValues = setLeaf(
        nodes,
        ['address1'],
        {'file1': 'value2'},
      );
      expect(
        newValues,
        const Parent([
          Leaf(['address1'], {'file1': 'value2'}),
        ], []),
      );
    });

    test('setValue update existing child value', () {
      const nodes = Parent([
        Leaf(['address1'], {'file1': 'value1'}),
        Parent(
          [
            Leaf(['address2', 'address3'], {'file1': 'value3'}),
          ],
          ['address2'],
        ),
      ], []);

      final newValues = setLeaf(
        nodes,
        ['address2', 'address3'],
        {'file1': 'value4'},
      );
      expect(
        newValues,
        const Parent([
          Leaf(['address1'], {'file1': 'value1'}),
          Parent(
            [
              Leaf(['address2', 'address3'], {'file1': 'value4'}),
            ],
            ['address2'],
          ),
        ], []),
      );
    });
    test('setValue add to root', () {
      const nodes = Parent([
        Leaf(['address1'], {'file1': 'value1'}),
      ], []);

      final newValues = setLeaf(
        nodes,
        ['address2'],
        {'file1': 'value2'},
      );

      expect(
        newValues,
        const Parent([
          Leaf(['address1'], {'file1': 'value1'}),
          Leaf(['address2'], {'file1': 'value2'}),
        ], []),
      );
    });
    test('setValue add to child with existing parent', () {
      const nodes = Parent(
        [
          Leaf(['address1'], {'file1': 'value1'}),
          Parent(
            [
              Leaf(['address2', 'address1'], {'file1': 'value3'}),
            ],
            ['address2'],
          ),
        ],
        [],
      );
      final newValues = setLeaf(
        nodes,
        ['address2', 'address3'],
        {'file1': 'value3'},
      );
      expect(
        newValues,
        const Parent(
          [
            Leaf(['address1'], {'file1': 'value1'}),
            Parent(
              [
                Leaf(['address2', 'address1'], {'file1': 'value3'}),
                Leaf(['address2', 'address3'], {'file1': 'value3'}),
              ],
              ['address2'],
            ),
          ],
          [],
        ),
      );
    });

    test('setValue add to child with non existing parent', () {
      const nodes = Parent(
        [
          Leaf(['address1'], {'file1': 'value1'}),
        ],
        [],
      );
      final newValues = setLeaf(
        nodes,
        ['address2', 'address1'],
        {'file1': 'value3'},
      );
      expect(
        newValues,
        const Parent(
          [
            Leaf(['address1'], {'file1': 'value1'}),
            Parent(
              [
                Leaf(['address2', 'address1'], {'file1': 'value3'}),
              ],
              ['address2'],
            ),
          ],
          [],
        ),
      );
    });
  });
}
