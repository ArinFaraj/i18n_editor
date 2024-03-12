import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MenuEntry {
  const MenuEntry(
      {required this.label, this.shortcut, this.onPressed, this.menuChildren})
      : assert(menuChildren == null || onPressed == null,
            'onPressed is ignored if menuChildren are provided');
  final String label;

  final MenuSerializableShortcut? shortcut;
  final VoidCallback? onPressed;
  final List<MenuEntry>? menuChildren;

  static List<Widget> build(List<MenuEntry> selections) {
    Widget buildSelection(MenuEntry selection) {
      if (selection.menuChildren != null) {
        return SubmenuButton(
          menuChildren: MenuEntry.build(selection.menuChildren!),
          child: Text(selection.label),
        );
      }
      return MenuItemButton(
        shortcut: selection.shortcut,
        onPressed: selection.onPressed,
        child: Text(selection.label),
      );
    }

    return selections.map<Widget>(buildSelection).toList();
  }

  static Map<MenuSerializableShortcut, Intent> shortcuts(
      List<MenuEntry> selections) {
    final Map<MenuSerializableShortcut, Intent> result =
        <MenuSerializableShortcut, Intent>{};
    for (final MenuEntry selection in selections) {
      if (selection.menuChildren != null) {
        result.addAll(MenuEntry.shortcuts(selection.menuChildren!));
      } else {
        if (selection.shortcut != null && selection.onPressed != null) {
          result[selection.shortcut!] =
              VoidCallbackIntent(selection.onPressed!);
        }
      }
    }
    return result;
  }
}

class MyMenuBar extends StatefulWidget {
  const MyMenuBar({
    super.key,
  });

  @override
  State<MyMenuBar> createState() => _MyMenuBarState();
}

class _MyMenuBarState extends State<MyMenuBar> {
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
            children: MenuEntry.build(_getMenus()),
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
                // final Directory? directory = await selectADirectory(context);
                // openedDirectory.value = directory;
              }),
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
    // (Re-)register the shortcuts with the ShortcutRegistry so that they are
    // available to the entire application, and update them if they've changed.
    _shortcutsEntry?.dispose();
    _shortcutsEntry =
        ShortcutRegistry.of(context).addAll(MenuEntry.shortcuts(result));
    return result;
  }
}
