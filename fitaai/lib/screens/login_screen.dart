import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../main.dart'; // Import to access the supabase client instance
import '../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSignUp = false;
  final _fullNameController = TextEditingController();
  String? _successMessage;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Clean up the email to ensure consistency
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;
      
      print("Trying to sign in with email: $email");
      
      // Check if user exists in profiles
      try {
        final userProfile = await supabase
            .from('user_profiles')
            .select('email')
            .eq('email', email)
            .maybeSingle();
        
        // If we found a profile but sign-in fails, it's likely an unverified email
        if (userProfile != null) {
          print("User profile found for email: $email");
        }
      } catch (profileError) {
        print("Error checking profile: $profileError");
      }
      
      // Try to sign in
      try {
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        
        print("Sign in successful: ${response.user?.email}");
        
        // Navigate to home screen if login successful
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      } catch (signInError) {
        print("Sign in error: $signInError");
        
        // Check if this is likely an unverified email issue
        setState(() {
          if (signInError.toString().contains("Email not confirmed") || 
              signInError.toString().contains("Invalid login credentials")) {
            _errorMessage = 'Your email may not be verified. Please check your inbox and spam folder for the verification email.';
            
            // Show resend verification option
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Need a new verification email?'),
                action: SnackBarAction(
                  label: 'Resend',
                  onPressed: () => _resendVerificationEmail(email),
                ),
                duration: const Duration(seconds: 10),
              ),
            );
          } else {
            _errorMessage = 'Invalid email or password';
          }
        });
      }
    } catch (e) {
      print("General error during sign-in: $e");
      setState(() {
        _errorMessage = 'An error occurred while signing in';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _resendVerificationEmail(String email) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check if email looks valid
      if (!email.contains('@') || !email.contains('.')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email address')),
        );
        return;
      }
      
      // Show immediate feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending verification email...'))
      );
      
      print("Attempting to resend verification email to: $email");
      
      await supabase.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      
      print("Verification email resent successfully to: $email");
      
      if (!mounted) return;
      setState(() {
        _successMessage = 'Verification email sent to $email.\n\n'
            '• Please check both inbox and spam folders\n'
            '• Email should arrive within 5 minutes\n'
            '• If using Gmail, check the "Promotions" tab';
        _errorMessage = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verification email sent to $email'),
              const SizedBox(height: 4),
              const Text('If you don\'t see it, check your spam folder or try a different email'),
            ],
          ),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Try Again',
            onPressed: () => _resendVerificationEmail(email),
          ),
        ),
      );
    } catch (e) {
      print("Failed to resend verification email: $e");
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to send verification email: ${e.toString()}';
      });
      
      // Show troubleshooting tips
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Error: ${e.toString()}'),
              const SizedBox(height: 4),
              const Text('Try a different email address or check your internet connection'),
            ],
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;
      final fullName = _fullNameController.text.trim();
      
      // Validate email format
      if (!email.contains('@') || !email.contains('.')) {
        setState(() {
          _errorMessage = 'Please enter a valid email address';
          _isLoading = false;
        });
        return;
      }
      
      // Check for common email domain issues
      final emailDomain = email.split('@').last.toLowerCase();
      
      // Basic check for disposable email domains
      final disposableDomains = [
        'mailinator.com', 'yopmail.com', 'tempmail.com', 'guerrillamail.com',
        'temp-mail.org', '10minutemail.com', 'fakeinbox.com'
      ];
      
      if (disposableDomains.contains(emailDomain)) {
        setState(() {
          _errorMessage = 'Please use a permanent email address. Temporary emails cannot receive verification emails.';
          _isLoading = false;
        });
        return;
      }
      
      // Common typos in email domains
      final commonTypos = {
        'gmial.com': 'gmail.com',
        'gmil.com': 'gmail.com',
        'gamil.com': 'gmail.com',
        'gnail.com': 'gmail.com',
        'gmal.com': 'gmail.com',
        'gmail.co': 'gmail.com',
        'gmail.vom': 'gmail.com',
        'gmail.con': 'gmail.com',
        'gmaill.com': 'gmail.com',
        'hotmail.co': 'hotmail.com',
        'hotmail.vom': 'hotmail.com',
        'hormail.com': 'hotmail.com',
        'hotnail.com': 'hotmail.com',
        'outlok.com': 'outlook.com',
        'outloo.com': 'outlook.com',
        'outlook.co': 'outlook.com',
        'yahoocom': 'yahoo.com',
        'yaho.com': 'yahoo.com',
        'yahooo.com': 'yahoo.com',
        'yaoo.com': 'yahoo.com',
      };
      
      if (commonTypos.containsKey(emailDomain)) {
        final correctDomain = commonTypos[emailDomain];
        setState(() {
          _errorMessage = 'Did you mean ${email.split('@').first}@$correctDomain?';
          _isLoading = false;
        });
        return;
      }
      
      // Well-known domains that should work reliably
      final reliableDomains = [
        'gmail.com', 'yahoo.com', 'outlook.com', 'hotmail.com', 
        'aol.com', 'icloud.com', 'protonmail.com', 'zoho.com',
        'mail.com', 'yandex.com', 'gmx.com', 'live.com'
      ];
      
      // Print domain info for debugging
      print("Email domain: $emailDomain (${reliableDomains.contains(emailDomain) ? 'reliable' : 'unknown'})");
      
      // Register the user with Supabase
      print("Trying to sign up with email: $email");

      // First, create the auth user
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      
      print("Sign up response: ${res.user?.id}");
      
      // Check if the user needs email confirmation
      if (res.user?.emailConfirmedAt == null) {
        print("Email confirmation needed for: $email");
        if (!mounted) return;
        
        // Add domain-specific instructions
        String additionalInfo = '';
        if (emailDomain == 'gmail.com') {
          additionalInfo = '\n• For Gmail, also check "Promotions" and "Updates" tabs';
        } else if (emailDomain == 'outlook.com' || emailDomain == 'hotmail.com') {
          additionalInfo = '\n• For Outlook/Hotmail, check "Junk Email" and "Other" folders';
        }
        
        // Show verification needed message with detailed instructions
        setState(() {
          _errorMessage = null;
          _successMessage = 'Account created! Verification email sent to $email\n\n'
              '• Please check both inbox and spam folders$additionalInfo\n'
              '• Email should arrive within 5 minutes\n'
              '• Tap "Resend Email" below if you don\'t receive it\n'
              '• Or use "Verify Now" for an alternative verification';
        });
        
        // Create button to resend verification
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Need help with verification?'),
                action: SnackBarAction(
                  label: 'Resend Email',
                  onPressed: () => _resendVerificationEmail(email),
                ),
                duration: const Duration(seconds: 20),
              ),
            );
          }
        });
        
        // Optionally create the profile (will succeed since we're bypassing RLS)
        try {
          await supabase.from('user_profiles').insert({
            'email': email,
            'user_id': res.user!.id,
            'full_name': fullName,
          });
          print("Profile created for user: ${res.user!.id}");
        } catch (profileError) {
          print("Error creating profile: $profileError");
          // Non-fatal error, user can still verify email
        }
      } else {
        // Email already confirmed (unusual case)
        print("Email already confirmed for: $email");
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print("Sign up error: $e");
      setState(() {
        if (e.toString().contains('already registered')) {
          _errorMessage = 'This email is already registered. Please sign in instead.';
        } else if (e.toString().contains('invalid email')) {
          _errorMessage = 'The email address appears to be invalid. Please check and try again.';
        } else if (e.toString().contains('weak password')) {
          _errorMessage = 'Please use a stronger password (at least 6 characters with numbers and letters)';
        } else {
          _errorMessage = 'An error occurred during sign up: ${e.toString()}';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      // Note: Navigation will be handled by the auth state change listener in the main app
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to sign in with Google';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.3),
                  AppTheme.backgroundColor,
                  AppTheme.backgroundColor,
                ],
                stops: const [0.0, 0.3, 1.0],
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60.0),
                    // App Logo/Title
                    Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'FITAAI',
                        style: TextStyle(
                          fontSize: 42.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40.0),
                    // Welcome text
                    Text(
                      _isSignUp ? 'Create Account' : 'Welcome back',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _isSignUp 
                          ? 'Sign up to start your fitness journey' 
                          : 'Sign in to continue tracking your fitness journey',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40.0),
                    
                    // Full Name field (only for sign up)
                    if (_isSignUp) ...[
                      FilledTextField(
                        label: 'Full Name',
                        prefixIcon: Icons.person_outline,
                        controller: _fullNameController,
                      ),
                      const SizedBox(height: 16.0),
                    ],
                    
                    // Email field
                    FilledTextField(
                      label: 'Email',
                      prefixIcon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16.0),
                    // Password field
                    FilledTextField(
                      label: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      suffixIcon: Icons.visibility_outlined,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 8.0),
                    // Error and success messages
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_successMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    // Show troubleshooting options if verification email was sent
                    if (_successMessage != null && _successMessage!.contains('Verification email sent'))
                      _buildTroubleshootingOptions(),
                    
                    const SizedBox(height: 8.0),
                    // Forgot password (only for sign in)
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                    const SizedBox(height: 24.0),
                    // Login/Sign Up button
                    FilledButton(
                      onPressed: _isLoading ? null : (_isSignUp ? _signUp : _signIn),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        backgroundColor: AppTheme.primaryColor,
                        disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                        _isSignUp ? 'Sign Up' : 'Sign In',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    // Social login options (only for sign in)
                    if (!_isSignUp) ...[
                      const Row(
                        children: [
                          Expanded(child: Divider(indent: 16, endIndent: 16)),
                          Text("OR"),
                          Expanded(child: Divider(indent: 16, endIndent: 16)),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      // Google login button
                      InkWell(
                        onTap: _signInWithGoogle,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppTheme.cardColor.withOpacity(0.3),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.g_mobiledata_rounded, color: Colors.red.shade400, size: 28),
                              const SizedBox(width: 12),
                              const Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32.0),
                    // Sign up/Sign in toggle option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp ? 'Already have an account?' : 'Don\'t have an account?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                              _errorMessage = null;
                            });
                          },
                          child: Text(_isSignUp ? 'Sign In' : 'Sign Up'),
                        ),
                      ],
                    ),
                    // Magic link alternative option
                    if (!_isSignUp) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          icon: Icon(Icons.link),
                          label: Text('Sign in with Magic Link'),
                          onPressed: () => _sendMagicLink(_emailController.text.trim()),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialLoginButton(BuildContext context, {required IconData icon, required Color color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.cardColor.withOpacity(0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
      ),
    );
  }

  // Manual email verification option
  Widget _buildTroubleshootingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          'Trouble receiving the verification email?',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            TextButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Resend Email'),
              onPressed: () => _resendVerificationEmail(_emailController.text.trim()),
            ),
            TextButton.icon(
              icon: Icon(Icons.alternate_email),
              label: Text('Try New Email'),
              onPressed: () {
                setState(() {
                  _emailController.clear();
                  _successMessage = null;
                  _errorMessage = 'Enter a different email address';
                });
              },
            ),
            TextButton.icon(
              icon: Icon(Icons.app_registration),
              label: Text('Verify Now'),
              onPressed: () => _manualVerification(_emailController.text.trim()),
            ),
          ],
        ),
      ],
    );
  }

  // Function to manually verify a user when they can't get the email
  Future<void> _manualVerification(String email) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Check if email looks valid
      if (!email.contains('@') || !email.contains('.')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email address')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Get password for temporary login
      final password = _passwordController.text.trim();
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your password')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      print("Attempting manual verification for: $email");
      
      // First try to sign in with password (this might fail if email not verified)
      try {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        
        // If we get here, user is already verified, just redirect to home
        print("User already verified, logging in");
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/home');
        return;
      } catch (signInError) {
        print("Sign-in failed during manual verification: $signInError");
        // This is expected if email not verified, continue with validation
      }
      
      // Get profile info to confirm account exists
      final userProfile = await supabase
          .from('user_profiles')
          .select('user_id, email')
          .eq('email', email)
          .maybeSingle();
      
      if (userProfile == null) {
        print("No user profile found for email: $email");
        setState(() {
          _errorMessage = 'No account found with this email. Please sign up first.';
          _isLoading = false;
        });
        return;
      }
      
      // Account exists but not verified. Create a new one-time password token
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      
      print("Password reset email sent to allow verification bypass");
      
      setState(() {
        _successMessage = 'Verification bypass initiated!\n\n'
            '1. We\'ve sent a password reset link to $email\n'
            '2. Click the link in the email (check spam folder)\n'
            '3. You\'ll be redirected to reset your password\n'
            '4. After resetting, you can log in normally';
        _errorMessage = null;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password reset email sent! Check your inbox and spam folder.'),
          duration: const Duration(seconds: 8),
        ),
      );
      
    } catch (e) {
      print("Error during manual verification: $e");
      setState(() {
        _errorMessage = 'Verification failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Function to send a magic link (no password needed)
  Future<void> _sendMagicLink(String email) async {
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print("Sending magic link to: $email");
      
      await supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      
      if (!mounted) return;
      
      setState(() {
        _successMessage = 'Magic link sent to $email\n\n'
            '• Click the link in the email to log in instantly\n'
            '• No password needed\n'
            '• Check your spam folder if not found';
        _errorMessage = null;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Magic link sent to $email'),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      print("Error sending magic link: $e");
      
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to send magic link: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
}

class FilledTextField extends StatelessWidget {
  final String label;
  final IconData prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController controller;

  const FilledTextField({
    super.key,
    required this.label,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: TextField(
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: label,
            prefixIcon: Icon(prefixIcon),
            suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
            filled: true,
            fillColor: AppTheme.cardColor.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: BorderSide(
                color: AppTheme.primaryColor.withOpacity(0.7),
                width: 1.0,
              ),
            ),
          ),
          controller: controller,
        ),
      ),
    );
  }
} 