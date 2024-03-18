import 'package:flutter_test/flutter_test.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';

void main() {
  group('KeysNotifier', () {
    test('setValue update existing root value', () {
      const nodes = JsonObject([
        JsonString(['address1'], {'file1': 'value1'}),
      ], []);

      final newValues = setJsonStringValue(
        nodes,
        ['address1'],
        {'file1': 'value2'},
      );
      expect(
        newValues,
        const JsonObject([
          JsonString(['address1'], {'file1': 'value2'}),
        ], []),
      );
    });

    test('setValue update existing child value', () {
      const nodes = JsonObject([
        JsonString(['address1'], {'file1': 'value1'}),
        JsonObject(
          [
            JsonString(['address2', 'address3'], {'file1': 'value3'}),
          ],
          ['address2'],
        ),
      ], []);

      final newValues = setJsonStringValue(
        nodes,
        ['address2', 'address3'],
        {'file1': 'value4'},
      );
      expect(
        newValues,
        const JsonObject([
          JsonString(['address1'], {'file1': 'value1'}),
          JsonObject(
            [
              JsonString(['address2', 'address3'], {'file1': 'value4'}),
            ],
            ['address2'],
          ),
        ], []),
      );
    });
    test('setValue add to root', () {
      const nodes = JsonObject([
        JsonString(['address1'], {'file1': 'value1'}),
      ], []);

      final newValues = setJsonStringValue(
        nodes,
        ['address2'],
        {'file1': 'value2'},
      );

      expect(
        newValues,
        const JsonObject([
          JsonString(['address1'], {'file1': 'value1'}),
          JsonString(['address2'], {'file1': 'value2'}),
        ], []),
      );
    });
    test('setValue add to child with existing parent', () {
      const nodes = JsonObject([
        JsonString(['address1'], {'file1': 'value1'}),
        JsonObject(
          [
            JsonString(['address2', 'address1'], {'file1': 'value3'}),
          ],
          ['address2'],
        ),
      ], []);
      final newValues = setJsonStringValue(
        nodes,
        ['address2', 'address3'],
        {'file1': 'value3'},
      );
      expect(
          newValues,
          const JsonObject([
            JsonString(['address1'], {'file1': 'value1'}),
            JsonObject(
              [
                JsonString(['address2', 'address3'], {'file1': 'value3'}),
              ],
              ['address2'],
            ),
          ], []));
    });

    test('setValue add to child with non existing parent', () {
      const nodes = JsonObject([
        JsonString(['address1'], {'file1': 'value1'}),
      ], []);
      final newValues = setJsonStringValue(
        nodes,
        ['address2', 'address1'],
        {'file1': 'value3'},
      );
      expect(
        newValues,
        const JsonObject([
          JsonString(['address1'], {'file1': 'value1'}),
          JsonObject(
            [
              JsonString(['address2', 'address1'], {'file1': 'value3'}),
            ],
            ['address2'],
          ),
        ], []),
      );
    });
  });
}
