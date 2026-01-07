import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Top-level function for handling background messages (must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
  // Handle background message processing here if needed
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  // Initialize Supabase - replace with your actual keys
  await Supabase.initialize(
    url:
        'https://tqpjrlwdgoctacfrbanf.supabase.co', // Replace with your Supabase URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxcGpybHdkZ29jdGFjZnJiYW5mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwMTU5NTIsImV4cCI6MjA2NjU5MTk1Mn0.x94UQ4jY3FhvxxTrRzuZsVgrAL3vmi3qJ_GolN9uHxQ', // Replace with your Supabase anon key
  );

  runApp(const CompostKakiApp());
}

class CompostKakiApp extends StatefulWidget {
  const CompostKakiApp({super.key});

  @override
  State<CompostKakiApp> createState() => _CompostKakiAppState();
}

class _CompostKakiAppState extends State<CompostKakiApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    print('🔗 [MAIN] Initializing deep link handler...');
    _appLinks = AppLinks();
    _handleInitialDeepLink();
    _setupDeepLinkListener();
    print('✅ [MAIN] Deep link handler initialized');
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleInitialDeepLink() async {
    // Check for initial deep link when app opens
    print('🔗 [MAIN] Checking for initial deep link...');
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        print('🔗 [MAIN] Found initial deep link: $initialLink');
        _processDeepLink(initialLink);
      } else {
        print('🔗 [MAIN] No initial deep link found');
      }
    } catch (e) {
      print('❌ [MAIN] Error getting initial deep link: $e');
    }
    
    // Also check for recovery session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForRecoverySession();
    });
  }

  void _setupDeepLinkListener() {
    // Listen for deep links when app is already running
    print('🔗 [MAIN] Setting up deep link listener...');
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        print('🔗 [MAIN] Deep link received via stream: $uri');
        _processDeepLink(uri);
      },
      onError: (err) {
        print('❌ [MAIN] Error listening to deep links: $err');
      },
      cancelOnError: false,
    );
    print('✅ [MAIN] Deep link listener active');

    // Listen for auth state changes to detect recovery sessions
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        // User clicked reset link, navigate to reset password screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppRouter.router.go('/reset-password');
        });
      }
    });
  }

  Future<void> _processDeepLink(Uri uri) async {
    print('🔗 [DEEP LINK] Processing deep link: $uri');
    print('🔗 [DEEP LINK] Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}, Fragment: ${uri.fragment}');
    print('🔗 [DEEP LINK] Full URI: ${uri.toString()}');
    
    // UNIVERSAL LINKS / APP LINKS FLOW:
    // 1. User clicks email link → Opens https://compostkaki.vercel.app/reset-password#tokens
    // 2. iOS/Android detects app can handle this URL → Opens app directly
    // 3. App processes the HTTPS link and extracts tokens from hash
    // 4. Navigate to reset password screen with tokens
    
    // Handle HTTPS Universal Links / App Links
    if (uri.scheme == 'https' && uri.host == 'compostkaki.vercel.app') {
      print('🔗 [DEEP LINK] HTTPS Universal/App Link detected');
      
      // Handle reset-password path
      if (uri.path == '/reset-password' || uri.path.startsWith('/reset-password')) {
        print('🔗 [DEEP LINK] Reset password Universal/App Link detected');
        
        // Extract tokens from fragment (hash)
        final fragment = uri.fragment;
        print('🔗 [DEEP LINK] Fragment: $fragment');
        
        if (fragment.isNotEmpty) {
          final params = Uri.splitQueryString(fragment);
          final type = params['type'];
          final accessToken = params['access_token'];
          final refreshToken = params['refresh_token'];
          
          print('🔗 [DEEP LINK] Parsed params - type: $type, hasAccessToken: ${accessToken != null}, hasRefreshToken: ${refreshToken != null}');
          
          if (type == 'recovery' && accessToken != null && refreshToken != null) {
            print('🔗 [DEEP LINK] Found recovery tokens, navigating to reset password...');
            
            await Future.delayed(const Duration(milliseconds: 300));
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                final encodedAccessToken = Uri.encodeComponent(accessToken);
                final encodedRefreshToken = Uri.encodeComponent(refreshToken);
                
                final route = '/reset-password?access_token=$encodedAccessToken&refresh_token=$encodedRefreshToken&type=recovery';
                print('🔗 [DEEP LINK] Navigating to: $route');
                
                AppRouter.router.go(route);
                print('✅ [DEEP LINK] Navigation successful');
              } catch (e, stackTrace) {
                print('❌ [DEEP LINK] Navigation error: $e');
                print('Stack trace: $stackTrace');
                try {
                  AppRouter.router.go('/reset-password');
                } catch (navError) {
                  print('❌ [DEEP LINK] Fallback navigation also failed: $navError');
                }
              }
            });
            return;
          }
        }
      }
    }
    
    // Handle custom scheme deep link (fallback)
    if (uri.scheme == 'compostkaki') {
      print('🔗 [DEEP LINK] Valid compostkaki scheme detected');
      
      // Handle reset-password deep link
      if (uri.host == 'reset-password' || uri.path == '/reset-password') {
        print('🔗 [DEEP LINK] Reset password deep link detected');
        
        // Check if we have recovery tokens in the fragment
        final fragment = uri.fragment;
        print('🔗 [DEEP LINK] Fragment: $fragment');
        
        if (fragment.isNotEmpty) {
          // Parse the fragment to verify it's a recovery link
          final params = Uri.splitQueryString(fragment);
          final type = params['type'];
          final accessToken = params['access_token'];
          final refreshToken = params['refresh_token'];
          
          print('🔗 [DEEP LINK] Parsed params - type: $type, hasAccessToken: ${accessToken != null}, hasRefreshToken: ${refreshToken != null}');
          
          if (type == 'recovery' && accessToken != null && refreshToken != null) {
            // Navigate to reset password screen with tokens as query parameters
            // ResetPasswordScreen will handle setting the session using AuthService
            print('🔗 [DEEP LINK] Found recovery tokens, navigating to reset password...');
            
            // Navigate immediately - don't wait for post frame callback
            try {
              // URL encode the tokens to handle special characters
              final encodedAccessToken = Uri.encodeComponent(accessToken);
              final encodedRefreshToken = Uri.encodeComponent(refreshToken);
              
              final route = '/reset-password?access_token=$encodedAccessToken&refresh_token=$encodedRefreshToken&type=recovery';
              print('🔗 [DEEP LINK] Navigating to: $route');
              
              // Use WidgetsBinding to ensure we're on the main thread
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  AppRouter.router.go(route);
                  print('✅ [DEEP LINK] Navigation successful - route: $route');
                } catch (e, stackTrace) {
                  print('❌ [DEEP LINK] Navigation error in callback: $e');
                  print('Stack trace: $stackTrace');
                  // Fallback: try navigating without parameters
                  try {
                    print('🔗 [DEEP LINK] Trying fallback navigation...');
                    AppRouter.router.go('/reset-password');
                    print('✅ [DEEP LINK] Fallback navigation successful');
                  } catch (navError) {
                    print('❌ [DEEP LINK] Fallback navigation also failed: $navError');
                  }
                }
              });
              
              // Also try immediate navigation as backup
              try {
                AppRouter.router.go(route);
                print('✅ [DEEP LINK] Immediate navigation attempted');
              } catch (e) {
                print('⚠️ [DEEP LINK] Immediate navigation failed (will use callback): $e');
              }
            } catch (e, stackTrace) {
              print('❌ [DEEP LINK] Error preparing navigation: $e');
              print('Stack trace: $stackTrace');
            }
          } else {
            print('⚠️ [DEEP LINK] Missing required tokens - type: $type, accessToken: ${accessToken != null}, refreshToken: ${refreshToken != null}');
          }
        } else {
          print('⚠️ [DEEP LINK] Empty fragment, navigating to reset password anyway');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              AppRouter.router.go('/reset-password');
            } catch (e) {
              print('❌ [DEEP LINK] Error navigating: $e');
            }
          });
        }
      }
    } else {
      print('⚠️ [DEEP LINK] Unknown scheme: ${uri.scheme}');
    }
  }

  void _checkForRecoverySession() {
    // Check if we have a recovery session on app start
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;
    
    // If session exists but user email is not confirmed, it might be a recovery session
    if (session != null && session.user.emailConfirmedAt == null) {
      // Navigate to reset password screen
      AppRouter.router.go('/reset-password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => SupabaseService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: MaterialApp.router(
        title: 'CompostKaki',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}

