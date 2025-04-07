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
      
      // Try to sign in
      try {
        final response = await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        
        if (response.user != null) {
          print("Sign in successful: ${response.user?.email}");
          
          // Navigate to home screen if login successful
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          print("Sign in failed: User is null in response");
          setState(() {
            _errorMessage = 'Authentication failed. Please check your credentials.';
          });
        }
      } catch (signInError) {
        print("Sign in error: $signInError");
        
        // More specific error handling
        String errorMessage = 'Invalid email or password';
        
        if (signInError is AuthException) {
          final authError = signInError as AuthException;
          print("Auth error code: ${authError.statusCode} - ${authError.message}");
          
          if (authError.statusCode == 400) {
            if (authError.message.contains("Email not confirmed")) {
              errorMessage = 'Your email is not verified. Please check your inbox for the verification email.';
              _showResendVerificationOption(email);
            } else if (authError.message.contains("Invalid login credentials")) {
              errorMessage = 'The email or password you entered is incorrect.';
            }
          } else if (authError.statusCode == 422) {
            errorMessage = 'Invalid email format or password requirements not met.';
          }
        }
        
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      print("General error during sign-in: $e");
      setState(() {
        _errorMessage = 'An error occurred while signing in. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showResendVerificationOption(String email) {
    if (mounted) {
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
      
      // Validate all required fields
      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        setState(() {
          _errorMessage = 'All fields are required';
          _isLoading = false;
        });
        return;
      }
      
      // Validate password length
      if (password.length < 6) {
        setState(() {
          _errorMessage = 'Password must be at least 6 characters long';
          _isLoading = false;
        });
        return;
      }
      
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
      
      // Print domain info for debugging
      print("Email domain: $emailDomain");
      print("Signup attempt with email: $email, password length: ${password.length}, name: $fullName");
      
      // Register the user with Supabase
      print("Attempting to sign up with email: $email");

      try {
        // First, create the auth user
        final AuthResponse res = await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: 'io.supabase.flutterquickstart://login-callback/',
          data: {
            'full_name': fullName,
          }
        );
        
        if (res.user == null) {
          print("Sign up failed: User is null in response");
          setState(() {
            _errorMessage = 'Failed to create account. Please try again later.';
            _isLoading = false;
          });
          return;
        }
        
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
                '• Tap "Resend Email" below if you don\'t receive it';
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
          
          // Create the profile in Supabase
          try {
            await supabase.from('user_profiles').insert({
              'user_id': res.user!.id,
              'email': email,
              'full_name': fullName,
              'created_at': DateTime.now().toIso8601String(),
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
      } catch (authError) {
        print("Supabase auth error on signup: $authError");
        String errorMsg = 'Failed to create account. Please try again.';
        
        if (authError is AuthException) {
          final authException = authError as AuthException;
          print("Auth exception code: ${authException.statusCode}, message: ${authException.message}");
          
          if (authException.message.contains("already registered")) {
            errorMsg = 'This email is already registered. Please use the Sign In form or reset your password.';
          } else if (authException.message.contains("password")) {
            errorMsg = 'Password requirements not met. Please use a stronger password (min 6 characters).';
          }
        }
        
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("General error during sign-up: $e");
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
        _isLoading = false;
      });
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.backgroundColor,
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo with frosted glass effect
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 64,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'FITAAI',
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                Text(
                                  'AI-Powered Fitness Coach',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Sign Up / Sign In toggle with frosted glass effect
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: false,
                                label: Text('Sign In'),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                label: Text('Create Account'),
                              ),
                            ],
                            selected: {_isSignUp},
                            onSelectionChanged: (Set<bool> selection) {
                              setState(() {
                                _isSignUp = selection.first;
                                _errorMessage = null;
                                _successMessage = null;
                              });
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return AppTheme.primaryColor.withOpacity(0.8);
                                  }
                                  return Colors.transparent;
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Error Message
                    if (_errorMessage != null)
                      Card(
                        color: Colors.red.withOpacity(0.1),
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Success Message
                    if (_successMessage != null)
                      Card(
                        color: Colors.green.withOpacity(0.1),
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Form fields with frosted glass effect
                    if (_isSignUp)
                      FilledTextField(
                        label: 'Full Name',
                        prefixIcon: Icons.person,
                        controller: _fullNameController,
                      ),
                    
                    if (_isSignUp)
                      const SizedBox(height: 16),
                    
                    FilledTextField(
                      label: 'Email',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    FilledTextField(
                      label: 'Password',
                      prefixIcon: Icons.lock,
                      obscureText: true,
                      controller: _passwordController,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Sign In/Up Button with gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : (_isSignUp ? _signUp : _signIn),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
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
                              _isSignUp ? 'Create Account' : 'Sign In',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Forgot Password with frosted glass effect
                    if (!_isSignUp)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: TextButton(
                              onPressed: _isLoading ? null : _showResetPasswordDialog,
                              style: TextButton.styleFrom(
                                backgroundColor: AppTheme.cardColor.withOpacity(0.3),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                              ),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Privacy and Terms with frosted glass effect
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            'By using FITAAI, you agree to our Privacy Policy and Terms of Service.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
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

  // Function to handle password reset
  Future<void> _resetPassword(String email) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
        setState(() {
          _errorMessage = 'Please enter a valid email address';
          _isLoading = false;
        });
        return;
      }

      // Show immediate feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending password reset email...'))
      );
      
      print("Requesting password reset for: $email");
      
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutterquickstart://login-callback/',
      );
      
      if (!mounted) return;
      
      setState(() {
        _successMessage = 'Password reset email sent to $email.\n\n'
            '• Check your inbox and spam folders\n'
            '• Follow the link in the email to reset your password\n'
            '• You\'ll be able to set a new password';
        _errorMessage = null;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset email sent to $email'),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      print("Error sending password reset email: $e");
      
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to send reset email. Please try again later.';
        _isLoading = false;
      });
    }
  }

  // Show reset password dialog
  void _showResetPasswordDialog() {
    final resetEmailController = TextEditingController();
    
    // Pre-fill with current email if available
    if (_emailController.text.isNotEmpty) {
      resetEmailController.text = _emailController.text;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address to receive a password reset link',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPassword(resetEmailController.text.trim());
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
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