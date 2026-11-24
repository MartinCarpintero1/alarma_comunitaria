import 'dart:async';

import 'package:alarma_comunitaria/screens/alert/alert_confirmation_screen.dart';
import 'package:alarma_comunitaria/screens/alert/alert_sent_screen.dart';
import 'package:alarma_comunitaria/screens/alert/alert_type_screen.dart';
import 'package:alarma_comunitaria/screens/alert/location_confirmation_screen.dart';
import 'package:alarma_comunitaria/screens/alert/my_alerts_screen.dart';
import 'package:alarma_comunitaria/screens/auth/login_screen.dart';
import 'package:alarma_comunitaria/screens/auth/register_screen.dart';
import 'package:alarma_comunitaria/screens/claim/claims_screen.dart';
import 'package:alarma_comunitaria/screens/guide/user_guide_screen.dart';
import 'package:alarma_comunitaria/screens/history/history_screen.dart';
import 'package:alarma_comunitaria/screens/home/home_screen.dart';
import 'package:alarma_comunitaria/screens/map/emergency_map_screen.dart';
import 'package:alarma_comunitaria/screens/profile/profile_screen.dart';
import 'package:alarma_comunitaria/screens/settings/settings_screen.dart';
import 'package:alarma_comunitaria/screens/splash/splash_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: Firebase.apps.isEmpty
        ? ChangeNotifier()
        : GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    redirect: (_, state) {
      if (Firebase.apps.isEmpty) return null;
      final isAuthenticated = FirebaseAuth.instance.currentUser != null;
      final isPublicRoute = state.matchedLocation == '/splash' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!isAuthenticated && !isPublicRoute) return '/login';
      if (isAuthenticated &&
          (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/guide', builder: (_, _) => const UserGuideScreen()),
      GoRoute(path: '/alert-type', builder: (_, _) => const AlertTypeScreen()),
      GoRoute(
        path: '/location-confirmation',
        builder: (_, _) => const LocationConfirmationScreen(),
      ),
      GoRoute(
        path: '/alert-confirmation',
        builder: (_, _) => const AlertConfirmationScreen(),
      ),
      GoRoute(path: '/alert-sent', builder: (_, _) => const AlertSentScreen()),
      GoRoute(path: '/map', builder: (_, _) => const EmergencyMapScreen()),
      GoRoute(path: '/my-alerts', builder: (_, _) => const MyAlertsScreen()),
      GoRoute(path: '/claims', builder: (_, _) => const ClaimsScreen()),
      GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
