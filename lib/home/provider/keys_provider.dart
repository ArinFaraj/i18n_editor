import 'package:i18n_editor/home/provider/base_json_provider.dart';
import 'package:riverpod/riverpod.dart';

final selectedNode = StateProvider<JsonString?>(
  (ref) => null,
  name: 'selectedNode',
);
final baseLocaleKeysProvider = FutureProvider<List<Node>?>(
  (ref) async {
    final baseJson = await ref.watch(baseLocaleJsonProvider.future);

    if (baseJson == null) return null;

    return extractNodes(baseJson);
  },
  name: 'baseLocaleKeys',
);

sealed class Node {
  const Node(this.address);

  /// List of keys to get to this node
  final List<dynamic> address;
}

class JsonString extends Node {
  const JsonString(this.value, super.address);
  final String value;

  @override
  String toString() => '$value $address';
}

class JsonObject extends Node {
  const JsonObject(this.children, super.address);
  final List<Node> children;
}

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
    nodes.add(JsonString(json.toString(), path));
  }

  return nodes;
}
