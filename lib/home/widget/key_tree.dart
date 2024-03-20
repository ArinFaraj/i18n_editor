import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:i18n_editor/home/provider/modified_nodes_porvider.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:i18n_editor/home/provider/selected_leaf.dart';
import 'package:i18n_editor/home/widget/new_key_dialog.dart';

class KeyTree extends HookConsumerWidget {
  const KeyTree(this.nodes, {super.key});
  final List<Node> nodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final modifiedNodes = ref.watch(modifiedNodesProvider);
    final treeController = useRef(TreeController(
      roots: nodes,
      childrenProvider: (node) => switch (node) {
        Leaf _ => [],
        Parent parent => parent.children,
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
        final node_ = entry.node;
        final isSelected = selectedAddress == node_.address;
        final isLeaf = node_ is Leaf;
        final isModified = (modifiedNodes[node_.address]?.length ?? 0) > 0;

        final menuItems = [
          if (!isLeaf)
            MenuItem(
              label: 'Add Key',
              icon: Icons.add,
              onSelected: () => showNewKeyDialog(context, node_.address),
            ),
          MenuItem(
            label: 'Delete Key',
            icon: Icons.delete,
            onSelected: () {
              ref.read(keysProvider.notifier).removeLeaf(
                    node_.address,
                  );
            },
          ),
          MenuItem(
            label: 'Move Key',
            icon: Icons.edit,
            onSelected: () {
              showMoveKeyDialog(
                context,
                node_.address,
              );
            },
          ),
        ];

        void expandOrSelectNode() {
          if (isLeaf) {
            ref.read(selectedAddressProvider.notifier).state = node_.address;
          } else {
            treeController.value.toggleExpansion(node_);
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
                            node_.address.last.toString(),
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
