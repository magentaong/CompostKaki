import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/main/main_screen.dart';
import '../screens/bin/bin_detail_screen.dart';
import '../screens/bin/add_bin_screen.dart';
import '../screens/bin/log_activity_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isAuthenticated = authService.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/signup';
      
      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }
      if (isAuthenticated && isLoginRoute) {
        return '/main';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return SignupScreen(email: email);
        },
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/bin/:id',
        builder: (context, state) {
          final binId = state.pathParameters['id']!;
          return BinDetailScreen(binId: binId);
        },
      ),
      GoRoute(
        path: '/bin/:id/log',
        builder: (context, state) {
          final binId = state.pathParameters['id']!;
          return LogActivityScreen(binId: binId);
        },
      ),
      GoRoute(
        path: '/add-bin',
        builder: (context, state) => const AddBinScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}

