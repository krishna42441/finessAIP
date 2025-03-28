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
import 'screens/edit_profile_screen.dart';
import 'theme/app_theme.dart';
import 'config.dart';
import 'package:flutter/foundation.dart';
import 'utils/display_utils.dart';
import 'utils/performance_utils.dart';
import 'utils/motion_utils.dart';

// Global Supabase client
late final SupabaseClient supabase;

// Global navigation key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Apply system-wide settings
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.lightColorScheme.primaryContainer,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  
  // Apply high refresh rate optimizations
  DisplayUtils.optimizeForHighRefreshRate();
  
  // Apply performance optimizations
  PerformanceUtils.enablePerformanceOptimizations();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ynpiumbjcjybrcovxzlx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlucGl1bWJqY2p5YnJjb3Z4emx4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI2NzkxODksImV4cCI6MjA1ODI1NTE4OX0.td_4LhAXlwCJuayO8O8SLnkDiEusetgzl8hAXu-ss6s',
    debug: true, // Enable debug logs for auth issues
  );
  
  if (kDebugMode) {
    print("Supabase initialized with debug mode enabled");
    
    // Log refresh rate information
    print("Display optimization enabled");
  }
  
  // Set the global Supabase client
  supabase = Supabase.instance.client;
  
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

class _FitaaiAppState extends State<FitaaiApp> with SingleTickerProviderStateMixin {
  // Animation controller for app transitions
  late AnimationController _transitionController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _transitionController = AnimationController(
      vsync: this,
      duration: MotionUtils.medium,
    );
    
    // Listen for auth state changes
    supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (kDebugMode) {
        print("Auth state changed: $event");
        if (session != null) {
          print("User: ${session.user.email} (verified: ${session.user.emailConfirmedAt != null})");
        }
      }
      
      if (event == AuthChangeEvent.signedIn) {
        _navigateToHome();
      } else if (event == AuthChangeEvent.passwordRecovery) {
        // Handle password recovery flow
        if (kDebugMode) {
          print("Password recovery flow detected");
        }
      } else if (event == AuthChangeEvent.userUpdated) {
        if (kDebugMode) {
          print("User updated");
        }
      }
    });
  }
  
  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
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
      '/profile': (context) => const ProfileScreen(),
      '/edit_profile': (context) => const EditProfileScreen(),
      '/login': (context) => const LoginScreen(),
    };
    
    // Wrap the entire app in a RepaintBoundary for optimized rendering
    return RepaintBoundary(
      child: MaterialApp(
        title: 'FITAAI',
        // Use Material 3 light theme
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        home: client.auth.currentUser != null ? const HomeScreen() : const LoginScreen(),
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        // Use custom page transitions
        onGenerateRoute: (settings) {
          // For standard page transitions, use shared axis X
          if (settings.name != '/chat' && appRoutes.containsKey(settings.name)) {
            return MotionUtils.createSharedAxisX(
              pageBuilder: (context) => appRoutes[settings.name!]!(context),
            );
          }
          
          // Special handling for chat screen with container transform
          if (settings.name == '/chat') {
            final currentContext = settings.arguments as BuildContext?;
            
            // Get the central FAB position for the origin rect
            final RenderBox? box = currentContext?.findRenderObject() as RenderBox?;
            final Rect? originRect = box != null 
                ? box.localToGlobal(Offset.zero) & box.size 
                : null;
                
            return MotionUtils.createContainerTransform(
              context: currentContext ?? navigatorKey.currentContext!,
              page: ChatScreen(
                backgroundContent: RepaintBoundary(
                  child: Opacity(
                    opacity: 0.99,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              // Use a default rect if we couldn't get one from context
              originRect: originRect ?? Rect.fromCenter(
                center: Offset(
                  MediaQuery.of(currentContext ?? navigatorKey.currentContext!).size.width / 2,
                  MediaQuery.of(currentContext ?? navigatorKey.currentContext!).size.height - 80,
                ),
                width: 56,
                height: 56,
              ),
            );
          }
          
          // Add profile screen handling with a nice transition
          if (settings.name == '/profile') {
            return MotionUtils.createSharedAxisY(
              pageBuilder: (context) => const ProfileScreen(),
              forward: true,
            );
          }
          
          return null;
        },
        builder: (context, child) {
          // Apply global app optimizations
          return MediaQuery(
            // Disable font scaling for consistent UI
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child!,
          );
        },
      ),
    );
  }
}
