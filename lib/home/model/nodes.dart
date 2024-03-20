import 'package:equatable/equatable.dart';

sealed class Node extends Equatable {
  const Node(this.address);

  final List<Object> address;
}

class Leaf extends Node {
  const Leaf(super.address, this.values);
  final Map<String, String?> values;

  Leaf copyWith({Map<String, String?>? values}) {
    return Leaf(address, values ?? this.values);
  }

  Leaf updateFileValue(String file, String? value) {
    return copyWith(
      values: Map.from(values)..[file] = value,
    );
  }

  @override
  String toString() {
    return 'Leaf{$address, $values}';
  }

  @override
  List<Object?> get props => [address];
}

class Parent extends Node {
  const Parent(this.children, super.address);
  final List<Node> children;

  @override
  List<Object?> get props => [address];
}
