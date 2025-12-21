import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/supabase_service.dart';
import 'services/auth_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
