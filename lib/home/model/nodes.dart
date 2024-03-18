import 'package:equatable/equatable.dart';

sealed class Node extends Equatable {
  const Node(this.address);

  final List<dynamic> address;
}

class JsonString extends Node {
  const JsonString(super.address, this.values);
  final Map<String, String?> values;

  JsonString copyWith({Map<String, String?>? values}) {
    return JsonString(address, values ?? this.values);
  }

  JsonString updateFileValue(String file, String? value) {
    return copyWith(
      values: Map.from(values)..[file] = value,
    );
  }

  @override
  String toString() {
    return 'JsonStr{$address, $values}';
  }

  @override
  List<Object?> get props => [address, values];
}

class JsonObject extends Node {
  const JsonObject(this.children, super.address);
  final List<Node> children;

  @override
  List<Object?> get props => [children, address];
}
