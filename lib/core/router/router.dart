import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:i18n_editor/core/router/paths.dart';
import 'package:i18n_editor/home_page.dart';

final routerProvider = Provider(
  (ref) => GoRouter(
    routes: [
      GoRoute(
        path: AppPaths.home.goRoute,
        builder: (context, state) => const HomePage(),
      ),
    ],
  ),
);
