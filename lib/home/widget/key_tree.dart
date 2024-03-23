import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:i18n_editor/home/provider/keys_traverse.dart';
import 'package:i18n_editor/home/provider/modified_nodes_porvider.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:i18n_editor/home/provider/selected_leaf.dart';
import 'package:i18n_editor/home/widget/new_key_dialog.dart';

class KeyTree extends HookConsumerWidget {
  const KeyTree({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedId = ref.watch(selectedNodeIdProvider);
    final modifiedNodes = ref.watch(modifiedNodesProvider);
    final keys = ref.watch(keysProvider);
    final nodes = keys.value!.getRootNodeIds();
    print('rebuilding KeyTree');

    final treeController = useRef(TreeController(
      roots: nodes,
      childrenProvider: (id) {
        final nodeData = keys.value!.nodes[id];
        return switch (nodeData) {
          Parent _ => keys.value!.getChildrenIdsIterable(id),
          _ => <int>[],
        };
      },
    ));

    useEffect(() {
      treeController.value.expandAll();
      return () => treeController.value.dispose();
    }, [treeController]);

    useEffect(() {
      treeController.value.roots = nodes;
      Future.delayed(Duration.zero, () {
        if (context.mounted) {
          treeController.value.expandAll();
        }
      });

      return null;
    }, [nodes]);

    return AnimatedTreeView(
      treeController: treeController.value,
      curve: Curves.easeInOut,
      nodeBuilder: (context, entry) {
        final nodeId = entry.node;
        final node_ = keys.value!.nodes[nodeId];
        if (node_ == null) return const SizedBox();
        final isSelected = selectedId == nodeId;
        final isLeaf = node_ is Leaf;
        final isModified = (modifiedNodes[nodeId]?.length ?? 0) > 0;

        final menuItems = [
          if (!isLeaf)
            MenuItem(
              label: 'Add Key',
              icon: Icons.add,
              onSelected: () => showNewKeyDialog(
                context,
                keys.value!.getAddress(node_),
              ),
            ),
          MenuItem(
            label: 'Delete Key',
            icon: Icons.delete,
            onSelected: () {
              ref.read(keysProvider.notifier).remove(
                    node_,
                  );
            },
          ),
          // MenuItem(
          //   label: 'Move Key',
          //   icon: Icons.edit,
          //   onSelected: () {
          //     showMoveKeyDialog(
          //       context,
          //       keys.value!.getAddress(node_),
          //     );
          //   },
          // ),
        ];

        void expandOrSelectNode() {
          if (isLeaf) {
            ref.read(selectedNodeIdProvider.notifier).state = nodeId;
          } else {
            treeController.value.toggleExpansion(nodeId);
          }
        }

        return ContextMenuRegion(
          contextMenu: ContextMenu(
            entries: menuItems,
            padding: const EdgeInsets.all(2),
          ),
          child: Material(
            color: isSelected
                ? theme.colorScheme.secondaryContainer.withOpacity(0.3)
                : null,
            child: InkWell(
              splashColor: theme.colorScheme.secondaryContainer,
              highlightColor: theme.colorScheme.secondaryContainer,
              onTap: expandOrSelectNode,
              child: TreeIndentation(
                guide: const IndentGuide.connectingLines(
                  indent: 17,
                  origin: 0.7,
                ),
                entry: entry,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Badge(
                    isLabelVisible: isModified,
                    child: Row(
                      children: [
                        if (!isLeaf)
                          Icon(
                            entry.isExpanded ? Icons.folder_open : Icons.folder,
                            size: 18,
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            node_.key?.toString() ?? '_no_key_',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
