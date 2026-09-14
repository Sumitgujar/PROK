import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import 'constants.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final loc = state.matchedLocation;
      final isLoggingIn = loc == AppRoutes.login;
      final isSplash = loc == AppRoutes.splash;

      if (isSplash) return null; // let splash decide
      if (!auth.isAuthenticated && !isLoggingIn) return AppRoutes.login;
      if (auth.isAuthenticated && isLoggingIn) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.dashboard, builder: (_, __) => const DashboardScreen()),
      GoRoute(
        path: AppRoutes.attendance,
        builder: (_, __) => const _PlaceholderScreen(title: 'Attendance'),
      ),
      GoRoute(
        path: AppRoutes.documents,
        builder: (_, __) => const _PlaceholderScreen(title: 'Documents'),
      ),
      GoRoute(
        path: AppRoutes.scholarships,
        builder: (_, __) => const _PlaceholderScreen(title: 'Scholarships'),
      ),
      GoRoute(
        path: AppRoutes.courses,
        builder: (_, __) => const _PlaceholderScreen(title: 'Courses'),
      ),
    ],
  );
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('$title — coming in Stage 2',
            style: const TextStyle(fontSize: 18, color: Colors.grey)),
      ),
    );
  }
}
