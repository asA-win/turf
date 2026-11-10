import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/features/auth/presentation/controllers/auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Real-time live validation state
  Timer? _debounceTimer;
  bool? _isEmailAvailable;
  bool _isCheckingEmail = false;
  String _emailMessage = '';

  String _passwordStrength = '';
  Color _passwordStrengthColor = Colors.grey;
  double _passwordStrengthPercent = 0.0;
  bool _passwordsMatch = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _usernameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onEmailChanged(String val) {
    final email = val.trim();
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() {
        _isEmailAvailable = null;
        _isCheckingEmail = false;
        _emailMessage = '';
      });
      return;
    }

    setState(() {
      _isCheckingEmail = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final dio = ref.read(dioClientProvider);
        final response = await dio.get('/users/check-availability', queryParameters: {'email': email});
        if (!mounted) return;
        final data = response.data as Map<String, dynamic>;
        setState(() {
          _isCheckingEmail = false;
          _isEmailAvailable = data['available'] as bool? ?? true;
          _emailMessage = data['message'] as String? ?? '';
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isCheckingEmail = false;
        });
      }
    });
  }

  void _onPasswordChanged(String val) {
    setState(() {
      if (val.isEmpty) {
        _passwordStrength = '';
        _passwordStrengthPercent = 0.0;
      } else if (val.length < 6) {
        _passwordStrength = 'Weak (min 6 characters)';
        _passwordStrengthColor = Colors.redAccent;
        _passwordStrengthPercent = 0.33;
      } else if (val.length >= 6 && (!val.contains(RegExp(r'[0-9]')) || !val.contains(RegExp(r'[A-Za-z]')))) {
        _passwordStrength = 'Fair (mix letters & numbers)';
        _passwordStrengthColor = Colors.amber;
        _passwordStrengthPercent = 0.66;
      } else {
        _passwordStrength = 'Strong password';
        _passwordStrengthColor = AppTheme.primaryGreen;
        _passwordStrengthPercent = 1.0;
      }
      _passwordsMatch = _confirmPasswordController.text.isNotEmpty && val == _confirmPasswordController.text;
    });
  }

  void _onConfirmPasswordChanged(String val) {
    setState(() {
      _passwordsMatch = val.isNotEmpty && val == _passwordController.text;
    });
  }

  void _signUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final contact = _contactController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || contact.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    await ref.read(authControllerProvider.notifier).signUp(
      email, 
      password, 
      username, 
      contact,
    );
    
    if (mounted) {
      final state = ref.read(authControllerProvider);
      state.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
        data: (_) {
          context.go('/home');
        },
      );
    }
  }

  void _loginWithGoogle() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (mounted) {
      final state = ref.read(authControllerProvider);
      state.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
        data: (_) {
          context.go('/home');
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                'Sign - Up',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: 'Username',
                  prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryGreen),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: _onEmailChanged,
                decoration: InputDecoration(
                  hintText: 'Email Id',
                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryGreen),
                  suffixIcon: _isCheckingEmail
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                          ),
                        )
                      : (_isEmailAvailable != null
                          ? Icon(
                              _isEmailAvailable! ? Icons.check_circle : Icons.cancel,
                              color: _isEmailAvailable! ? AppTheme.primaryGreen : Colors.redAccent,
                            )
                          : null),
                ),
              ),
              if (_emailMessage.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isEmailAvailable == true ? '✓ $_emailMessage' : '✗ $_emailMessage',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _isEmailAvailable == true ? AppTheme.primaryGreen : Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Contact Number',
                  prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primaryGreen),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: _onPasswordChanged,
                decoration: InputDecoration(
                  hintText: 'New Password',
                  prefixIcon: const Icon(Icons.key_outlined, color: AppTheme.primaryGreen),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppTheme.primaryGreen,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              if (_passwordStrength.isNotEmpty) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _passwordStrengthPercent,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _passwordStrength,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _passwordStrengthColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                onChanged: _onConfirmPasswordChanged,
                decoration: InputDecoration(
                  hintText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.key_outlined, color: AppTheme.primaryGreen),
                  suffixIcon: _passwordsMatch
                      ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen)
                      : IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.primaryGreen,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                ),
              ),
              if (_confirmPasswordController.text.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _passwordsMatch ? '✓ Passwords match' : '✗ Passwords do not match',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _passwordsMatch ? AppTheme.primaryGreen : Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _signUp,
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign-Up'),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already Have Account? "),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text('Others Ways to sign-in'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _socialIcon(Icons.facebook, Colors.blue, onTap: () {}),
                  const SizedBox(width: 24),
                  _socialIcon(Icons.g_mobiledata, Colors.red, size: 48, onTap: _loginWithGoogle),
                  const SizedBox(width: 24),
                  _socialIcon(Icons.apple, Colors.black, onTap: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon, Color color, {double size = 32, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}
