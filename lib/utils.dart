import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart' as intl;
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

class Debouncer {
  final int milliseconds;
  Timer? _timer;
  Debouncer({required this.milliseconds});
  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

String extractBaseName(String path) {
  final parts = path.split(RegExp('[/\\\\]'));
  return parts[parts.length - 1];
}

TextDirection isRTL(String text) {
  final rtl = intl.Bidi.detectRtlDirectionality(text);

  return rtl ? TextDirection.rtl : TextDirection.ltr;
}

String? getMapValue(Map<String, dynamic> json, List<dynamic> address) {
  dynamic value = json;
  for (final key in address) {
    if (value is Map) {
      value = value[key];
    } else if (value is List) {
      value = value[key];
    } else {
      return null;
    }
  }
  return value;
}
