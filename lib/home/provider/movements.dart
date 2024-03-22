import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/utils.dart';

Parent deleteLeaf(Parent node, List<Object> address) {
  final children = node.children
      .where((child) => !listEquals(child.address, address))
      .map((child) {
    if (child is Parent) {
      return deleteLeaf(child, address);
    }
    return child;
  }).toList();

  return Parent(children, node.address);
}

Parent extractNodes(
  String baseLocalePath,
  Files files,
) {
  final filesCopy = Map<String, Map<String, dynamic>>.from(files);
  final baseJson = filesCopy.remove(baseLocalePath);

  Node extractNode(dynamic jsonValue, [List<Object> path = const []]) {
    if (jsonValue is Map) {
      final children = <Node>[];
      jsonValue.forEach((key, value) {
        final newPath = [...path, key as Object];
        children.add(extractNode(value, newPath));
      });
      return Parent(children, path);
    } else if (jsonValue is List) {
      final children = <Node>[];
      for (int i = 0; i < jsonValue.length; i++) {
        final newPath = [...path, i];
        children.add(extractNode(jsonValue[i], newPath));
      }
      return Parent(children, path);
    } else {
      final values = filesCopy.map(
        (file, data) => MapEntry(
          file,
          getMapValue(data, path),
        ),
      );

      values[baseLocalePath] = jsonValue;

      return Leaf(path, values);
    }
  }

  return extractNode(baseJson) as Parent;
}

Leaf? getLeaf(Node node, List<dynamic> address) {
  if (node is Leaf && listEquals(node.address, address)) {
    return node;
  } else if (node is Parent) {
    Leaf? result;
    for (final child in node.children) {
      result = getLeaf(child, address);
      if (result != null) return result;
    }
  }

  return null;
}

Parent setLeaf(
  Node oldNode,
  List<Object> address,
  Map<String, String?> values,
) {
  Node createNewNode(
    List<dynamic> currentAddress,
  ) {
    var index = currentAddress.length;
    Node newNode = Leaf(address, values);
    while (index < address.length - 1) {
      newNode = Parent([newNode], address.sublist(0, index + 1));
      index++;
    }
    return newNode;
  }

  Node setLeafRecursive(
    Node node,
  ) {
    if (node is Leaf && node.address.equals(address)) {
      // If the current node is the target leaf, update its values.
      return node.copyWith(values: values);
    } else if (node is Parent) {
      // If the current node is a parent, recursively update its children.
      final newChildren = <Node>[];
      var found = false;
      for (var child in node.children) {
        if (address.startsWith(child.address)) {
          found = true;
          newChildren.add(setLeafRecursive(child));
        } else {
          newChildren.add(child);
        }
      }
      // If the target leaf was not found in the children, create a new leaf or parent as needed.
      if (!found) {
        Node newNode = createNewNode(node.address);
        newChildren.add(newNode);
      }
      return Parent(newChildren, node.address);
    }
    return node;
  }

  // Check if the oldNode is a Parent and start the recursion.
  if (oldNode is Parent) {
    return setLeafRecursive(oldNode) as Parent;
  } else {
    throw Exception('The root node must be a Parent node.');
  }
}

// can be improved for better performance
Parent moveLeaf(Parent node, List<Object> fromAddress, List<Object> toAddress) {
  final leaf = getLeaf(node, fromAddress);
  if (leaf == null) return node;

  final newParent = deleteLeaf(node, fromAddress);
  return setLeaf(newParent, toAddress, leaf.values);
}

extension ListExtensions on List {
  bool equals(List list) {
    return listEquals(this, list);
  }

  bool startsWith(List list) {
    if (length < list.length) return false;
    for (int i = 0; i < list.length; i++) {
      if (this[i] != list[i]) return false;
    }
    return true;
  }
}

/// Generates a new id that is not used by any node.
int getNewId([List<int>? existing]) {
  final random = Random();
  var id = random.nextInt(9999999);

  while (existing?.contains(id) ?? false) {
    id = random.nextInt(999999999999);
  }

  return id;
}
