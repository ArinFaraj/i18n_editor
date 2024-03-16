import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:i18n_editor/home/provider/modified_nodes_porvider.dart';

Widget buildKeyTree(List<Node> nodes, WidgetRef ref, [int depth = 0]) {
  return ListView.builder(
    shrinkWrap: true,
    itemCount: nodes.length,
    itemBuilder: (context, index) {
      final node = nodes[index];
      if (node case JsonObject(address: const [])) {
        return buildKeyTree(node.children, ref);
      }

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
                    isLabelVisible: ref
                        .watch(modifiedNodesProvider)
                        .containsKey(node_.address),
                    child: Text(
                      node_.address.last.toString(),
                    ),
                  ),
                ),
                selected: ref.watch(selectedNode)?.address == node_.address,
                dense: true,
                onTap: () {
                  ref.read(selectedNode.notifier).state = node_;
                },
              ),
            JsonObject node_ => ExpansionTile(
                initiallyExpanded: true,
                dense: true,
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
