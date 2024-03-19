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
    final treeController = useRef(
      TreeController(
        roots: nodes,
        childrenProvider: (node) => switch (node) {
          Leaf _ => [],
          Parent parent => parent.children,
        },
      ),
    );

    useEffect(
      () {
        treeController.value.expandAll();
        return () => treeController.value.dispose();
      },
      [treeController],
    );

    useEffect(() {
      treeController.value.roots = nodes;

      return null;
    }, [nodes]);

    return AnimatedTreeView(
      treeController: treeController.value,
      curve: Curves.easeInOut,
      nodeBuilder: (context, entry) {
        final node_ = entry.node;
        final isLeaf = node_ is Leaf;
        final selected = ref.watch(selectedAddressProvider) == node_.address;

        return ContextMenuRegion(
          contextMenu: ContextMenu(
            entries: [
              // const MenuHeader(text: "Context Menu"),
              if (!isLeaf)
                MenuItem(
                  label: 'Add Key',
                  icon: Icons.add,
                  onSelected: () {
                    showNewKeyDialog(context, node_.address);
                  },
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
              const MenuDivider(),
              MenuItem.submenu(
                label: 'Edit',
                icon: Icons.edit,
                items: [
                  MenuItem(
                    label: 'Undo',
                    value: "Undo",
                    icon: Icons.undo,
                    onSelected: () {
                      // implement undo
                    },
                  ),
                  MenuItem(
                    label: 'Redo',
                    value: 'Redo',
                    icon: Icons.redo,
                    onSelected: () {
                      // implement redo
                    },
                  ),
                ],
              ),
            ],
            // position: const Offset(300, 300),
            padding: const EdgeInsets.all(8.0),
          ),
          child: Material(
            color: selected
                ? Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.3)
                : null,
            child: InkWell(
              splashColor: Theme.of(context).colorScheme.secondaryContainer,
              highlightColor: Theme.of(context).colorScheme.secondaryContainer,
              child: TreeIndentation(
                entry: entry,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Badge(
                    isLabelVisible: (ref
                                .watch(modifiedNodesProvider)[node_.address]
                                ?.length ??
                            0) >
                        0,
                    child: Row(
                      children: [
                        isLeaf
                            ? const Icon(Icons.arrow_right, size: 18)
                            : entry.isExpanded
                                ? const Icon(Icons.folder_open, size: 18)
                                : const Icon(Icons.folder, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.node.address.last.toString(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              onTap: () {
                if (isLeaf) {
                  ref.read(selectedAddressProvider.notifier).state =
                      node_.address;
                } else {
                  treeController.value.toggleExpansion(entry.node);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
