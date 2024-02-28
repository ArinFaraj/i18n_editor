import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Future<Directory?> selectADirectory(BuildContext context) async {
  final result = await showDialog<Directory>(
    context: context,
    builder: (context) {
      return HookBuilder(builder: (context) {
        final cwd = useState<Directory>(Directory.current);
        final dirs = useMemoized(
          () => cwd.value.listSync().whereType<Directory>().toList(),
          [cwd.value],
        );

        return AlertDialog(
          title: const Text('pick a folder'),
          content: SizedBox(
            // height: 200,
            width: 500,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text('Current: '),
                Text(cwd.value.path),
                ListTile(
                  title: const Text('..'),
                  onTap: () {
                    cwd.value = cwd.value.parent;
                  },
                ),
                for (final dir in dirs)
                  ListTile(
                    title: Text(dir.path),
                    onTap: () {
                      cwd.value = dir;
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, cwd.value);
              },
              child: const Text('OK'),
            ),
          ],
        );
      });
    },
  );

  return result;
}
