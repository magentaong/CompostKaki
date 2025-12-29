import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

class CompostKakiApp extends StatelessWidget {
  const CompostKakiApp({super.key});

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
