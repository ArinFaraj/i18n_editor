import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/core/settings/recent_projects.dart';
import 'package:i18n_editor/home/provider/files_provider.dart';
import 'package:i18n_editor/home/provider/keys_provider.dart';
import 'package:i18n_editor/home/provider/modified_nodes_porvider.dart';
import 'package:i18n_editor/home/provider/project_manager.dart';
import 'package:i18n_editor/home/widget/i18n_config_dialog.dart';
import 'package:i18n_editor/home/widget/menu_entry.dart';
import 'package:i18n_editor/home/widget/new_key_dialog.dart';

class HomeMenuBar extends ConsumerStatefulWidget {
  const HomeMenuBar({super.key});

  @override
  ConsumerState<HomeMenuBar> createState() => HomeMenuBarState();
}

class HomeMenuBarState extends ConsumerState<HomeMenuBar> {
  ShortcutRegistryEntry? _shortcutsEntry;

  List<MenuEntry> _getMenus() {
    final recentProjects = ref.watch(recentProjectsProvider).requireValue;
    final keysLoaded = ref.watch(keysProvider).valueOrNull != null;
    final List<MenuEntry> result = <MenuEntry>[
      MenuEntry(
        label: 'File',
        menuChildren: <MenuEntry>[
          MenuEntry(
            label: 'Save Files',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyS, control: true),
            onPressed: ref.watch(modifiedNodesProvider).isEmpty || !keysLoaded
                ? null
                : () async {
                    await ref.read(keysProvider.notifier).saveFiles();
                  },
          ),
          MenuEntry(
            label: 'Reload Files',
            shortcut:
                const SingleActivator(LogicalKeyboardKey.keyR, control: true),
            onPressed: ref.watch(keysProvider).valueOrNull == null
                ? null
                : () async {
                    ref.invalidate(filesNotifierProvider);
                  },
          ),
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
          if (ref.watch(projectManagerProvider) != null)
            MenuEntry(
              label: 'Close Project',
              shortcut:
                  const SingleActivator(LogicalKeyboardKey.keyQ, control: true),
              onPressed: () {
                ref.read(projectManagerProvider.notifier).closeProject();
              },
            ),
          // recent projects
          MenuEntry(
            label: 'Recent Projects',
            menuChildren: [
              for (int i = 0; i < recentProjects.length; i++)
                MenuEntry(
                  label: recentProjects[i],
                  shortcut: i == 0
                      ? const SingleActivator(LogicalKeyboardKey.digit1,
                          control: true)
                      : i == 1
                          ? const SingleActivator(LogicalKeyboardKey.digit2,
                              control: true)
                          : null,
                  onPressed: () {
                    ref
                        .read(projectManagerProvider.notifier)
                        .openProject(recentProjects[i]);
                  },
                ),
            ],
          ),
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
          // Quit
          MenuEntry(
            label: 'Exit',
            onPressed: () {
              exit(0);
            },
          ),
        ],
      ),
      MenuEntry(
        label: 'Edit',
        menuChildren: [
          MenuEntry(
            label: 'Add Key',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyN,
              control: true,
            ),
            onPressed: keysLoaded ? () => showNewKeyDialog(context) : null,
          ),
        ],
      )
    ];

    _shortcutsEntry?.dispose();
    _shortcutsEntry = ShortcutRegistry.of(context).addAll(
      MenuEntry.shortcuts(result),
    );
    return result;
  }

  @override
  void dispose() {
    _shortcutsEntry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Icon(
          Icons.language,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 6),
        MenuBar(
          style: const MenuStyle(
            elevation: MaterialStatePropertyAll(0.0),
            backgroundColor: MaterialStatePropertyAll(Colors.transparent),
          ),
          children: MenuEntry.build(_getMenus()),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Center(
            child: Text(
              ref.watch(projectManagerProvider) ?? '',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (ref.watch(projectManagerProvider) != null)
          Center(
            child: IconButton(
              style: IconButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.settings),
              onPressed: () {
                showI18nConfigsDialog(context, ref);
              },
            ),
          ),
        const SizedBox(width: 16),
      ],
    );
  }
}
