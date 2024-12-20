import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/keys_traverse.dart';
import 'package:i18n_editor/home/provider/movements.dart';

typedef NewKeysState = ({
  IMap<int, Node> nodes,
  IMap<int, int> parentTree,
  IList<int> nodeOrder,
});

extension NewKeyStateExt on NewKeysState {
  NewKeysState copyWith({
    IMap<int, Node>? nodes,
    IMap<int, int>? parentTree,
    IList<int>? nodeOrder,
  }) =>
      (
        nodes: nodes ?? this.nodes,
        parentTree: parentTree ?? this.parentTree,
        nodeOrder: nodeOrder ?? this.nodeOrder,
      );

  NewKeysState addNode(
    Node node, {
    required int? parentId,
    int? beforeId,
    int? afterId,
  }) {
    final nodeId = node.id;

    final IList<int> order;

    if (beforeId != null) {
      final index = nodeOrder.indexOf(beforeId);
      order = nodeOrder.insert(index, nodeId);
    } else if (afterId != null) {
      final index = nodeOrder.indexOf(afterId) + 1;
      order = nodeOrder.insert(index, nodeId);
    } else {
      order = nodeOrder.add(nodeId);
    }

    var result = copyWith(
      nodes: nodes.add(nodeId, node),
      parentTree:
          parentId != null ? parentTree.add(nodeId, parentId) : parentTree,
      nodeOrder: order,
    );

    return result;
  }

  /// Removes [node] from the tree.
  /// and remove empty parent nodes
  NewKeysState removeNode(Node node) {
    var newOrder = nodeOrder;
    var newNodes = nodes;
    var newParentTree = parentTree;

    void remove(Node node, {bool removeParent = true}) {
      final id = node.id;
      newOrder = newOrder.remove(id);
      newNodes = newNodes.remove(id);
      newParentTree = newParentTree.remove(id);

      if (node is! Leaf) {
        for (final child in getChildren(node)) {
          remove(child, removeParent: false);
        }
      }

      if (removeParent) {
        final parentId = parentTree[id];
        if (parentId != null) {
          final parentNode = newNodes[parentId];
          if (parentNode != null && parentNode is Parent) {
            final remainingChildren = newParentTree.keys
                .where((key) => newParentTree[key] == parentId)
                .toList();
            if (remainingChildren.isEmpty) {
              remove(parentNode);
            }
          }
        }
      }
    }

    remove(node);

    return copyWith(
      nodes: newNodes,
      parentTree: newParentTree,
      nodeOrder: newOrder,
    );
  }

  /// Moves [node] to [newParentId] and inserts it before [beforeId] or after [afterId].
  /// If [newParentId] is null, [node] will be moved to the root.
  NewKeysState moveNode(
    Node node, {
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

  NewKeysState updateNode(Node currentNode, Node newNode) {
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

  NewKeysState moveNodeToAddress(Node node, List<String> address) {
    assert(address.isNotEmpty, 'Address cannot be empty');
    NewKeysState result = this;

    Node findOrCreateParentChain(List<String> address, [int? parentId]) {
      final rootNodes = result.nodeOrder
          .where((element) => result.parentTree[element] == parentId)
          .toList();
      Node? parentNode;
      for (final nodeId in rootNodes) {
        final node = result.nodes[nodeId]!;
        if (node.key == address.first) {
          parentNode = node;
          break;
        }
      }
      if (parentNode == null) {
        parentNode = Parent(
          getNewId(result.nodeOrder.toList()),
          key: address.first,
        );
        result = result.addNode(
          parentNode,
          parentId: parentId,
        );
        assert(result.nodes.containsKey(parentNode.id));
      }
      if (address.length == 1) {
        return parentNode;
      } else {
        return findOrCreateParentChain(
          address.sublist(1),
          parentNode.id,
        );
      }
    }

    final newParent = address.length > 1
        ? findOrCreateParentChain(address.sublist(0, address.length - 1))
        : null;

    // Update the node's key to match the last part of the address
    final updatedNode = node.copyWith(key: address.last);

    // Remove the node from its current position in the tree
    // final oldParentId = result.parentTree[node.id];
    result = result.copyWith(
      parentTree: result.parentTree.remove(node.id),
      nodeOrder: result.nodeOrder.remove(node.id),
    );

    // Add the updated node to its new position
    result = result.copyWith(
      nodes: result.nodes.add(updatedNode.id, updatedNode),
      parentTree: newParent != null
          ? result.parentTree.add(updatedNode.id, newParent.id)
          : result.parentTree,
      nodeOrder: result.nodeOrder.add(updatedNode.id),
    );

    // Update the parent of all immediate children
    if (node is Parent) {
      final childrenIds = result.parentTree.entries
          .where((entry) => entry.value == node.id)
          .map((entry) => entry.key)
          .toList();

      for (final childId in childrenIds) {
        result = result.copyWith(
          parentTree: result.parentTree.add(childId, updatedNode.id),
        );
      }
    }

    return result;
  }

  (NewKeysState, int) addLeafAtAddress(
    List<String> address, {
    Map<String, String?> values = const {},
  }) {
    assert(address.isNotEmpty, 'Address cannot be empty');
    NewKeysState result = this;
    Node findOrCreateParentChain(List<String> address, [int? parentId]) {
      final rootNodes = result.nodeOrder
          .where((element) => result.parentTree[element] == parentId)
          .toList();
      Node? parentNode;
      for (final nodeId in rootNodes) {
        final node = result.nodes[nodeId]!;
        if (node.key == address.first) {
          parentNode = node;
          break;
        }
      }
      if (parentNode == null) {
        parentNode = Parent(
          getNewId(result.nodeOrder.toList()),
          key: address.first,
        );
        result = result.addNode(
          parentNode,
          parentId: parentId,
        );
        assert(result.nodes.containsKey(parentNode.id));
      }
      if (address.length == 1) {
        return parentNode;
      } else {
        return findOrCreateParentChain(
          address.sublist(1),
          parentNode.id,
        );
      }
    }

    final parent = address.length != 1
        ? findOrCreateParentChain(address.sublist(0, address.length - 1))
        : null;

    final newNode = Leaf(
      getNewId(nodeOrder.toList()),
      key: address.last,
      values: values,
    );

    return (
      result.addNode(
        newNode,
        parentId: parent?.id,
      ),
      newNode.id
    );
  }
}
