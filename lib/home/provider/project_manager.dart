import 'dart:io';

import 'package:i18n_editor/core/settings/recent_projects.dart';
import 'package:i18n_editor/core/toast/toast_provider.dart';
import 'package:i18n_editor/home/provider/i18n_configs_provider.dart';
import 'package:riverpod/riverpod.dart';

typedef Project = String;

class ProjectManagerNotifier extends Notifier<Project?> {
  @override
  Project? build() => null;

  void openProject(String project) async {
    final recentProjects = List<String>.from(
      ref.read(recentProjectsProvider).requireValue,
    );

    if (await Directory(project).exists()) {
      state = project;
      recentProjects
        ..remove(project)
        ..insert(0, project);
    } else {
      ref.read(toastProvider.notifier).show(
            'Directory does not exist',
            type: ToastType.warning,
          );
      recentProjects.remove(project);
    }

    ref.read(recentProjectsProvider.notifier).set(recentProjects);
  }

  Future<void> closeProject() async {
    if (state == null) return;
    final oldState = state;
    final i18nConfigs = await ref.read(i18nConfigsProvider.future);
    state = null;

    if (i18nConfigs == null) {
      final recentProjects = List<String>.from(
        ref.read(recentProjectsProvider).requireValue,
      );

      recentProjects.remove(oldState);

      ref.read(recentProjectsProvider.notifier).set(recentProjects);
    }
  }
}

final projectManagerProvider =
    NotifierProvider<ProjectManagerNotifier, Project?>(
  ProjectManagerNotifier.new,
  name: 'projectManager',
);
