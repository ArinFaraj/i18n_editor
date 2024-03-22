import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:collection/collection.dart';
import 'package:i18n_editor/home/model/keys_state.dart';
import 'package:i18n_editor/home/model/nodes.dart';

extension NewKeyStateTraverse on NewKeysState {
  /// Gets the children of [node].
  IList<NewNode> getChildren(NewNode node) {
    return nodeOrder
        .where((e) => parentTree[e] == node.id)
        .map((e) => nodes[e]!)
        .toIList();
  }

  /// Gets the children ids of [node].
  IList<int> getChildrenIds(NewNode node) {
    return nodeOrder.where((e) => parentTree[e] == node.id).toIList();
  }

  /// Checks if [node] has children.
  bool hasChildren(NewNode node) {
    return nodeOrder.any((e) => parentTree[e] == node.id);
  }

  /// Gets the child of [node].
  NewNode? getChild(NewNode node) {
    return nodes.values
        .firstWhereOrNull((e) => parentTree[e.id] == node.id);
  }

  /// Gets the parent of [node].
  NewNode? getParent(NewNode node) {
    final parentId = parentTree[node.id];
    return parentId != null ? nodes[parentId] : null;
  }

  /// Finds the first node of type [T] in the tree of [node].
  T? findnodeInTree<T extends NewNode>(NewNode node) {
    var parent = getParent(node);
    while (parent != null) {
      if (parent is T) {
        return parent;
      }
      parent = getParent(parent);
    }

    return null;
  }

  /// Finds the first node that matches [predicate] in the tree of [node].
  NewNode? findnodeInTreeWhere(
    NewNode node,
    bool Function(NewNode) predicate,
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
