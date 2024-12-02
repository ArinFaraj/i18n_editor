import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:i18n_editor/home/provider/keys_traverse.dart';
import 'package:i18n_editor/home/provider/modified_nodes_porvider.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:i18n_editor/home/provider/selected_leaf.dart';
import 'package:i18n_editor/home/widget/new_key_dialog.dart';

class KeyTree extends StatefulHookConsumerWidget {
  const KeyTree({super.key});

  @override
  ConsumerState<KeyTree> createState() => _KeyTreeState();
}

class _KeyTreeState extends ConsumerState<KeyTree> {
  late final TreeController<int> treeController;
  @override
  void initState() {
    super.initState();

    final rootNodes = ref.read(filteredKeysProvider).value?.getRootNodeIds();
    treeController = TreeController(
      roots: rootNodes ?? [],
      parentProvider: (id) =>
          ref.read(filteredKeysProvider).value!.parentTree[id],
      childrenProvider: (id) {
        final keys = ref.read(filteredKeysProvider).value;

        final nodes = switch (keys!.nodes[id]) {
          Parent _ => keys.getChildrenIdsIterable(id),
          _ => <int>[],
        };

        return nodes;
      },
      defaultExpansionState: true,
    );
  }

  @override
  dispose() {
    treeController.dispose();
    super.dispose();
  }

  Future<void> updateTree() async {
    final keys = ref.read(filteredKeysProvider);
    treeController.roots = keys.value?.getRootNodeIds() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedId = ref.watch(selectedNodeIdProvider);
    final modifiedNodes = ref.watch(modifiedNodesProvider);

    final files = ref.watch(filesNotifierProvider).valueOrNull;
    ref.listen(filteredKeysProvider, (_, __) => updateTree());
    final filter = ref.watch(filterProvider);
    final isFiltering = filter != '';
    final controller = useTextEditingController(text: filter);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SearchBar(
            controller: controller,
            trailing: [
              if (isFiltering)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    ref.read(filterProvider.notifier).state = '';
                    controller.clear();
                  },
                )
            ],
            hintText: 'Filter',
            onChanged: (value) {
              ref.read(filterProvider.notifier).state = value;
            },
          ),
        ),
        Expanded(
          child: AnimatedTreeView(
            treeController: treeController,
            curve: Curves.easeInOut,
            nodeBuilder: (context, entry) {
              final keys = ref.read(filteredKeysProvider);
              final nodeId = entry.node;
              final node_ = keys.value!.nodes[nodeId];
              if (node_ == null) return const SizedBox();
              final isSelected = selectedId == nodeId;
              final isLeaf = node_ is Leaf;
              final filledLanguages = !isLeaf
                  ? null
                  : node_.values.values
                      .where((e) => e?.isNotEmpty ?? false)
                      .toList();

              final hasValuesForAllLanguages =
                  !isLeaf ? true : filledLanguages?.length == files?.length;
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
                MenuItem(
                  label: 'Move Key',
                  icon: Icons.edit,
                  onSelected: () {
                    showMoveKeyDialog(
                      context,
                      node_,
                      keys.value!.getAddress(node_),
                    );
                  },
                ),
              ];

              void expandOrSelectNode() {
                if (isLeaf) {
                  ref.read(selectedNodeIdProvider.notifier).state = nodeId;
                } else {
                  treeController.toggleExpansion(nodeId);
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
                          textColor: hasValuesForAllLanguages
                              ? Colors.green
                              : Colors.red,
                          isLabelVisible:
                              !hasValuesForAllLanguages || isModified,
                          child: Row(
                            children: [
                              if (!isLeaf)
                                Icon(
                                  entry.isExpanded
                                      ? Icons.folder_open
                                      : Icons.folder,
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
          ),
        ),
      ],
    );
  }
}

final filterProvider = StateProvider<String>((ref) => '');
