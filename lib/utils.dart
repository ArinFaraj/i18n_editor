import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yaml/yaml.dart';

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

Map<String, dynamic> convertYamlMapToMap(YamlMap yamlMap) {
  final map = <String, dynamic>{};

  for (final entry in yamlMap.entries) {
    if (entry.value is YamlMap || entry.value is Map) {
      map[entry.key.toString()] = convertYamlMapToMap(entry.value);
    } else {
      map[entry.key.toString()] = entry.value.toString();
    }
  }
  return map;
}
