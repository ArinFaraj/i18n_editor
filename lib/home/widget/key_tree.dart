import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/home/model/nodes.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:i18n_editor/home/provider/modified_nodes_porvider.dart';
import 'package:i18n_editor/home/widget/new_key_dialog.dart';

Widget buildKeyTree(List<Node> nodes, WidgetRef ref, [int depth = 0]) {
  if (depth == 0) {
    if (nodes.first case JsonObject(address: const [])) {
      return buildKeyTree((nodes.first as JsonObject).children, ref);
    }
  }

  return ListView.builder(
    shrinkWrap: true,
    itemCount: nodes.length,
    itemBuilder: (context, index) {
      final node = nodes[index];

      return Stack(
        children: [
          if (depth != 0)
            Positioned(
              top: 0,
              left: depth * 18,
              bottom: 0,
              child: const VerticalDivider(width: 0),
            ),
          switch (node) {
            JsonString node_ => ListTile(
                title: Padding(
                  padding: EdgeInsets.only(left: depth * 16),
                  child: Badge(
                    isLabelVisible: (ref
                                .watch(modifiedNodesProvider)[node_.address]
                                ?.length ??
                            0) >
                        0,
                    child: Text(
                      node_.address.last.toString(),
                    ),
                  ),
                ),
                selected: ref.watch(selectedAddressProvider) == node_.address,
                dense: true,
                onTap: () {
                  ref.read(selectedAddressProvider.notifier).state =
                      node_.address;
                },
              ),
            JsonObject node_ => ExpansionTile(
                initiallyExpanded: true,
                dense: true,
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    showNewKeyDialog(context, node_.address);
                  },
                ),
                title: Padding(
                  padding: EdgeInsets.only(left: depth * 16),
                  child: Text(
                    node_.address.last.toString(),
                  ),
                ),
                children: [
                  buildKeyTree(node_.children, ref, depth + 1),
                ],
              ),
          },
        ],
      );
    },
  );
}
