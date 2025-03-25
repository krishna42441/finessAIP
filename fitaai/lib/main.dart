import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/workout_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/progress_screen.dart';
import 'theme/app_theme.dart';
import 'config.dart';
import 'package:flutter/foundation.dart';

// Global Supabase client
late final SupabaseClient supabase;

// Global navigation key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ynpiumbjcjybrcovxzlx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlucGl1bWJqY2p5YnJjb3Z4emx4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI2NzkxODksImV4cCI6MjA1ODI1NTE4OX0.td_4LhAXlwCJuayO8O8SLnkDiEusetgzl8hAXu-ss6s',
    debug: true, // Enable debug logs for auth issues
  );
  
  print("Supabase initialized with debug mode enabled");
  
  // Set the global Supabase client
  supabase = Supabase.instance.client;
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Check if Gemini API key is set
  if (AppConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY') {
    if (kDebugMode) {
      print('WARNING: Gemini API key not set. AI plan generation will not work.');
      print('Please update the API key in config.dart');
    }
  } else {
    if (kDebugMode) {
      print('Gemini API key is set. AI plan generation should work.');
    }
  }
  
  runApp(const FitaaiApp());
}

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
    // Use the global navigator key instead of BuildContext
    navigatorKey.currentState?.pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    final client = supabase;
    final Map<String, WidgetBuilder> appRoutes = {
      '/home': (context) => const HomeScreen(),
      '/workout': (context) => const WorkoutScreen(),
      '/nutrition': (context) => const NutritionScreen(),
      '/progress': (context) => const ProgressScreen(),
      '/login': (context) => const LoginScreen(),
    };
    
    return MaterialApp(
      title: 'FITAAI',
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: client.auth.currentUser != null ? const HomeScreen() : const LoginScreen(),
      routes: appRoutes,
      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final currentContext = settings.arguments as BuildContext?;
          
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              // Get the current route widget
              final currentRoute = ModalRoute.of(currentContext ?? context);
              final currentWidget = currentRoute?.settings.name != null
                  ? appRoutes[currentRoute!.settings.name!]?.call(context)
                  : null;
              
              return ChatScreen(
                backgroundContent: RepaintBoundary(
                  child: Opacity(
                    opacity: 0.99,
                    child: currentWidget ?? Container(),
                  ),
                ),
              );
            },
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            opaque: false,
            barrierColor: Colors.transparent,
            fullscreenDialog: true,
          );
        }
        return null;
      },
    );
  }
}
