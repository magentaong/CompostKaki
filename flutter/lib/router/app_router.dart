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
import '../screens/profile/edit_profile_screen.dart';
import '../screens/educational/guides_list_screen.dart';
import '../screens/educational/guide_detail_screen.dart';
import '../screens/educational/tips_screen.dart';
import '../screens/bin/bin_chat_conversation_screen.dart';
import '../screens/bin/bin_food_waste_guide_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/auth/reset_password_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    onException: (context, state, exception) {
      // Ignore errors from custom URL schemes (compostkaki://)
      // These are handled by app_links package, not GoRouter
      final errorString = exception.toString();
      if (errorString.contains('Origin is only applicable to schemes http and https') ||
          errorString.contains('compostkaki://')) {
        print('⚠️ [ROUTER] Ignoring custom scheme URI error (handled by deep link handler)');
        // Don't rethrow - this error is expected and harmless
        return;
      }
      // Re-throw other exceptions
      print('❌ [ROUTER] Unhandled router exception: $exception');
      throw exception;
    },
    redirect: (context, state) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final isAuthenticated = authService.isAuthenticated;
      final location = state.matchedLocation;
      final isLoginRoute = location == '/login' || location == '/signup';
      final isResetPasswordRoute = location == '/reset-password' || location.startsWith('/reset-password');

      print('🔄 [ROUTER] Redirect check - location: $location, isAuthenticated: $isAuthenticated, isResetPasswordRoute: $isResetPasswordRoute');

      // Always allow reset-password route (for password reset flow)
      if (isResetPasswordRoute) {
        print('✅ [ROUTER] Allowing reset-password route');
        return null; // Allow navigation
      }

      // Unauthenticated users: redirect to login unless on login/signup
      if (!isAuthenticated && !isLoginRoute) {
        print('🔄 [ROUTER] Redirecting unauthenticated user to login');
        return '/login';
      }
      // Authenticated users: redirect away from login/signup
      if (isAuthenticated && isLoginRoute) {
        print('🔄 [ROUTER] Redirecting authenticated user away from login');
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
        path: '/reset-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          // Don't use ValueKey to allow MainScreen to preserve state
          return MainScreen(
            initialTab: tab == 'tasks' ? 1 : 0,
          );
        },
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
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/guides',
        builder: (context, state) => const GuidesListScreen(),
      ),
      GoRoute(
        path: '/guides/:id',
        builder: (context, state) {
          final guideId = state.pathParameters['id']!;
          return GuideDetailScreen(guideId: guideId);
        },
      ),
      GoRoute(
        path: '/tips',
        builder: (context, state) => const TipsScreen(),
      ),
      GoRoute(
        path: '/bin/:id/chat',
        builder: (context, state) {
          final binId = state.pathParameters['id']!;
          return BinChatConversationScreen(binId: binId);
        },
      ),
      GoRoute(
        path: '/bin/:id/guides',
        builder: (context, state) {
          final binId = state.pathParameters['id']!;
          // We'll need to check if user is owner - for now pass false
          return BinFoodWasteGuideScreen(binId: binId, isOwner: false);
        },
      ),
    ],
  );
}
