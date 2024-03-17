sealed class Node {
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
}

class JsonObject extends Node {
  const JsonObject(this.children, super.address);
  final List<Node> children;
}
