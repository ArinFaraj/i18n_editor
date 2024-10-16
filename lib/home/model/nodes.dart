sealed class Node {
  final Object? key;
  final int id;

  Node(this.id, {required this.key});

  @override
  String toString() {
    return 'NewNode{key: $key}';
  }

  Node copyWith({Object? key});
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
  Parent copyWith({Object? key}) {
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
    Object? key,
    Map<String, String?>? values,
  }) {
    return Leaf(
      id,
      key: key ?? this.key,
      values: values ?? this.values,
    );
  }
}
