import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:collection/collection.dart';
import 'package:i18n_editor/home/model/keys_state.dart';
import 'package:i18n_editor/home/model/nodes.dart';

extension NewKeyStateTraverse on NewKeysState {
  /// Gets the children of [node].
  IList<Node> getChildren(Node node) {
    return nodeOrder
        .where((e) => parentTree[e] == node.id)
        .map((e) => nodes[e]!)
        .toIList();
  }

  /// Gets the children ids of [node].
  IList<int> getChildrenIds(int id) {
    return nodeOrder.where((e) => parentTree[e] == id).toIList();
  }

  List<int> getRootNodeIds() {
    return nodeOrder.where((e) => parentTree[e] == null).toList();
  }

  /// Gets the iterable children ids of node [id].
  List<int> getChildrenIdsIterable(int id) {
    return nodeOrder.where((e) => parentTree[e] == id).toList();
  }

  /// Checks if [node] has children.
  bool hasChildren(Node node) {
    return nodeOrder.any((e) => parentTree[e] == node.id);
  }

  /// Gets the child of [node].
  Node? getChild(Node node) {
    return nodes.values.firstWhereOrNull((e) => parentTree[e.id] == node.id);
  }

  /// Gets the parent of [node].
  Node? getParent(Node node) {
    final parentId = parentTree[node.id];
    return parentId != null ? nodes[parentId] : null;
  }

  /// Finds the first node of type [T] in the tree of [node].
  T? findNodeInTree<T extends Node>(Node node) {
    var parent = getParent(node);
    while (parent != null) {
      if (parent is T) {
        return parent;
      }
      parent = getParent(parent);
    }

    return null;
  }

  List<Object> getAddress(Node node) {
    final List<Object> address = [if (node.key != null) node.key!];
    var parent = getParent(node);
    while (parent?.key != null) {
      address.add(parent!.key!);
      parent = getParent(parent);
    }
    return address.reversed.toList();
  }

  /// Finds the first node that matches [predicate] in the tree of [node].
  Node? findNodeInTreeWhere(
    Node node,
    bool Function(Node) predicate,
  ) {
    var parent = getParent(node);
    while (parent != null) {
      if (predicate(parent)) {
        return parent;
      }
      parent = getParent(parent);
    }
    return null;
  }
}
