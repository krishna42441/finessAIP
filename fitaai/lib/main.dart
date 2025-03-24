import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/nutrition_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ynpiumbjcjybrcovxzlx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlucGl1bWJqY2p5YnJjb3Z4emx4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI2NzkxODksImV4cCI6MjA1ODI1NTE4OX0.td_4LhAXlwCJuayO8O8SLnkDiEusetgzl8hAXu-ss6s',
    debug: true, // Enable debug logs for auth issues
  );
  
  print("Supabase initialized with debug mode enabled");
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const FitaaiApp());
}

// Supabase client for use throughout the app
final supabase = Supabase.instance.client;

class FitaaiApp extends StatefulWidget {
  const FitaaiApp({super.key});

  @override
  State<FitaaiApp> createState() => _FitaaiAppState();
}

class _FitaaiAppState extends State<FitaaiApp> {
  @override
  void initState() {
    super.initState();
    // Listen for auth state changes
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      print("Auth state changed: $event");
      if (session != null) {
        print("User: ${session.user.email} (verified: ${session.user.emailConfirmedAt != null})");
      }
      
      if (event == AuthChangeEvent.signedIn) {
        _navigateToHome();
      } else if (event == AuthChangeEvent.passwordRecovery) {
        // Handle password recovery flow
        print("Password recovery flow detected");
      } else if (event == AuthChangeEvent.userUpdated) {
        print("User updated");
      }
    });
  }
  
  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = supabase.auth.currentUser;
    final String initialRoute;
    
    if (currentUser != null) {
      print("Current user: ${currentUser.email} (verified: ${currentUser.emailConfirmedAt != null})");
      initialRoute = '/home';
    } else {
      print("No current user, showing login");
      initialRoute = '/login';
    }
    
    return MaterialApp(
      title: 'FITAAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/chat': (context) => const ChatScreen(),
        '/workout': (context) => const WorkoutScreen(),
        '/nutrition': (context) => const NutritionScreen(),
      },
    );
  }
}
