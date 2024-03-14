import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/core/settings/recent_projects.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:i18n_editor/home/widget/menu_entry.dart';

class HomeMenuBar extends ConsumerStatefulWidget {
  const HomeMenuBar({
    super.key,
  });

  @override
  ConsumerState<HomeMenuBar> createState() => _MyMenuBarState();
}

class _MyMenuBarState extends ConsumerState<HomeMenuBar> {
  ShortcutRegistryEntry? _shortcutsEntry;

  @override
  void dispose() {
    _shortcutsEntry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MenuBar(
            children: [
              ...MenuEntry.build(_getMenus()),
              const SizedBox(width: 16),
              Center(
                child: Text(
                  ref.watch(projectManagerProvider) ?? 'No Project Opened',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<MenuEntry> _getMenus() {
    final List<MenuEntry> result = <MenuEntry>[
      MenuEntry(
        label: 'File',
        menuChildren: <MenuEntry>[
          MenuEntry(
            label: 'Open Folder',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyO, control: true),
            onPressed: () async {
              final dir = await FilePicker.platform.getDirectoryPath();
              if (dir == null) return;
              ref.read(projectManagerProvider.notifier).openProject(dir);
            },
          ),
          // recent projects
          MenuEntry(label: 'Recent Projects', menuChildren: [
            for (final project
                in ref.watch(recentProjectsProvider).requireValue)
              MenuEntry(
                label: project,
                onPressed: () {
                  ref
                      .read(projectManagerProvider.notifier)
                      .openProject(project);
                },
              ),
          ]),
          MenuEntry(
            label: 'About',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'i18n Editor',
                applicationVersion: '1.0.0',
              );
            },
          ),
        ],
      ),
    ];
    _shortcutsEntry?.dispose();
    _shortcutsEntry =
        ShortcutRegistry.of(context).addAll(MenuEntry.shortcuts(result));
    return result;
  }
}
