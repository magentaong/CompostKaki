import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _showPasswordField = false;
  bool _obscurePassword = true;

  Future<void> _checkEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final emailExists =
          await authService.checkEmailExists(_emailController.text);

      if (emailExists) {
        // Email exists, show password field
        if (mounted) {
          setState(() {
            _showPasswordField = true;
            _obscurePassword = true;
            _isLoading = false;
          });
        }
      } else {
        // Email doesn't exist, go to signup
        if (mounted) {
          context.push(
              '/signup?email=${Uri.encodeComponent(_emailController.text)}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Something went wrong. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final response = await authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.user != null && mounted) {
        context.go('/main');
      } else {
        setState(() {
          _error = response.session == null
              ? 'Invalid email or password'
              : 'Sign in failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().contains('Invalid login credentials')
              ? 'Invalid email or password'
              : 'Sign in failed. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryGreenLight, AppTheme.backgroundGray],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/logo.png',
                      width: 64,
                      height: 64,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.eco,
                          size: 64,
                          color: AppTheme.primaryGreen,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'CompostKaki',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Grow your community, one compost at a time!',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field (shown after email check)
                    if (_showPasswordField)
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Continue/Sign In button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _showPasswordField
                                ? _signIn
                                : _checkEmail,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                _showPasswordField ? 'Sign In' : 'Continue',
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Forgot password link - always visible, centered
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Navigate to reset password screen with email pre-filled if available
                          final email = _emailController.text.trim();
                          if (email.isNotEmpty) {
                            context.push('/reset-password?email=${Uri.encodeComponent(email)}');
                          } else {
                            context.push('/reset-password');
                          }
                        },
                        child: const Text('Forgot password?'),
                      ),
                    ),

                    if (_showPasswordField) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showPasswordField = false;
                              _passwordController.clear();
                              _error = null;
                            });
                          },
                          child: const Text('← Back to email'),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // OR divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppTheme.textGray.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: AppTheme.textGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppTheme.textGray.withOpacity(0.3),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: TextButton(
                        onPressed: () {
                          context.push(
                              '/signup?email=${Uri.encodeComponent(_emailController.text)}');
                        },
                        child: const Text(
                            "New to CompostKaki? Create an account!"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

