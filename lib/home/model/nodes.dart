sealed class Node {
  final String? key;
  final int id;

  Node(this.id, {required this.key});

  @override
  String toString() {
    return 'NewNode{key: $key}';
  }

  Node copyWith({String? key});
}

class Parent extends Node {
  Parent(
    super.id, {
    required super.key,
  });
  @override
  String toString() {
    return 'Parent{key: $key}';
  }

  @override
  Parent copyWith({String? key}) {
    return Parent(
      id,
      key: key ?? this.key,
    );
  }
}

class Leaf extends Node {
  final Map<String, String?> values;
  Leaf(
    super.id, {
    required super.key,
    required this.values,
  });

  @override
  String toString() {
    return 'Leaf{key: $key, values: $values}';
  }

  @override
  Leaf copyWith({
    String? key,
    Map<String, String?>? values,
  }) {
    return Leaf(
      id,
      key: key ?? this.key,
      values: values ?? this.values,
    );
  }
}
