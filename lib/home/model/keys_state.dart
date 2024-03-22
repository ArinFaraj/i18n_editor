import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/keys_traverse.dart';

typedef NewKeysState = ({
  IMap<int, NewNode> nodes,
  IMap<int, int> parentTree,
  IList<int> nodeOrder,
});

extension NewKeyStateExt on NewKeysState {
  NewKeysState copyWith({
    IMap<int, NewNode>? nodes,
    IMap<int, int>? parentTree,
    IList<int>? nodeOrder,
  }) =>
      (
        nodes: nodes ?? this.nodes,
        parentTree: parentTree ?? this.parentTree,
        nodeOrder: nodeOrder ?? this.nodeOrder,
      );

  NewKeysState addNode(
    NewNode node, {
    required int? parentId,
    int? beforeId,
    int? afterId,
  }) {
    final nodeId = node.id;

    final IList<int> anodeOrder;

    if (beforeId != null) {
      final index = nodeOrder.indexOf(beforeId);
      anodeOrder = nodeOrder.insert(index, nodeId);
    } else if (afterId != null) {
      final index = nodeOrder.indexOf(afterId) + 1;
      anodeOrder = nodeOrder.insert(index, nodeId);
    } else {
      anodeOrder = nodeOrder.add(nodeId);
    }

    var result = copyWith(
      nodes: nodes.add(nodeId, node),
      parentTree:
          parentId != null ? parentTree.add(nodeId, parentId) : parentTree,
      nodeOrder: anodeOrder,
    );

    return result;
  }

  /// Removes [node] from the tree.
  NewKeysState removeNode(NewNode node) {
    var rnodeOrder = nodeOrder;
    var rnodes = nodes;
    var rparentOf = parentTree;

    // we could remove the parent node if it has no children
    void remove(NewNode node) {
      final id = node.id;
      rnodeOrder = rnodeOrder.remove(id);
      rnodes = rnodes.remove(id);
      rparentOf = rparentOf.remove(id);

      if (node is! NewLeaf) {
        for (final child in getChildren(node)) {
          remove(child);
        }
      }
    }

    remove(node);

    return copyWith(
      nodes: rnodes,
      parentTree: rparentOf,
      nodeOrder: rnodeOrder,
    );
  }

  /// Moves [node] to [newParentId] and inserts it before [beforeId] or after [afterId].
  /// If [newParentId] is null, [node] will be moved to the root.
  NewKeysState moveNode(
    NewNode node, {
    required int? newParentId,
    int? beforeId,
    int? afterId,
  }) {
    var newNodeOrder = nodeOrder;
    var newParentTree = parentTree;

    final id = node.id;
    if (newParentId != null) {
      newParentTree = newParentTree.add(id, newParentId);
    } else {
      newParentTree = newParentTree.remove(id);
    }
    if (beforeId != null) {
      newNodeOrder = newNodeOrder.remove(id);
      final index = newNodeOrder.indexOf(beforeId);
      newNodeOrder = newNodeOrder.insert(index, id);
    } else if (afterId != null) {
      newNodeOrder = newNodeOrder.remove(id);
      final index = newNodeOrder.indexOf(afterId) + 1;
      newNodeOrder = newNodeOrder.insert(index, id);
    }

    return copyWith(
      parentTree: newParentTree,
      nodeOrder: newNodeOrder,
    );
  }

  NewKeysState updateNode(NewNode currentNode, NewNode newNode) {
    return copyWith(
      parentTree: parentTree.map(
        (key, value) => MapEntry(
          key == currentNode.id ? newNode.id : key,
          value == currentNode.id ? newNode.id : value,
        ),
      ),
      nodes: nodes.remove(currentNode.id).add(newNode.id, newNode),
      nodeOrder: nodeOrder.replaceFirst(from: currentNode.id, to: newNode.id),
    );
  }
}
