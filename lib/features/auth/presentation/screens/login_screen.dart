import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  int _selectedTab = 0; // 0 for Phone, 1 for Email
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onContinue() async {
    if (_selectedTab == 0) {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter phone number')),
        );
        return;
      }
      // Send real-time OTP before navigating
      await ref.read(authControllerProvider.notifier).sendOtp(phone);
      if (!mounted) return;
      // Navigate to OTP verification
      context.push('/otp-verification', extra: phone);
    } else {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email address')),
        );
        return;
      }

      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter password')),
        );
        return;
      }

      await ref.read(authControllerProvider.notifier).login(email, password);
      if (!mounted) return;
      final state = ref.read(authControllerProvider);
      state.whenOrNull(
        error: (err, st) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err.toString()),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        },
        data: (_) async {
          final profile = await ref.read(fetchUserProfileProvider.future);
          if (!mounted) return;
          if (profile?.role == 'admin') {
            context.go('/analytics-dashboard');
          } else if (profile?.role == 'owner') {
            context.go('/venue-owner-dashboard');
          } else {
            context.go('/home');
          }
        },
      );
    }
  }

  void _loginWithGoogle() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    final state = ref.read(authControllerProvider);
    state.whenOrNull(
      error: (err, st) {
        final errStr = err.toString();
        if (errStr.contains('cancelled') || errStr.contains('canceled')) {
          return;
        }
        if (errStr.contains('10') || errStr.contains('sign_in_failed') || errStr.contains('ApiException')) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.cardDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text('Google Sign-In Note', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To authenticate with Google OAuth, your Firebase Project requires the Android SHA-1 certificate fingerprint to be added in Firebase Console:\n\nSHA-1:\n32:DF:CB:EC:42:AF:75:28:7D:E2:96:71:44:76:2E:C5:48:FF:85:19\n\nYou can also log in immediately using Phone OTP or Email & Password without any setup!',
                    style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12.5),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK, Got it'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errStr),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      },
      data: (_) async {
        final profile = await ref.read(fetchUserProfileProvider.future);
        if (!mounted) return;
        if (profile?.role == 'admin') {
          context.go('/analytics-dashboard');
        } else if (profile?.role == 'owner') {
          context.go('/venue-owner-dashboard');
        } else {
          context.go('/home');
        }
      },
    );
  }

  void _showForgotPasswordModal() {
    final messenger = ScaffoldMessenger.of(context);
    final emailPhoneCtrl = TextEditingController(text: _emailController.text.trim());
    final codeCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    int step = 1; // 1: enter identifier, 2: enter code & new password
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step == 1 ? 'Forgot Password' : 'Enter Verification Code',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step == 1
                    ? 'Enter your registered email or phone to receive a real-time recovery code.'
                    : 'A verification code was sent to ${emailPhoneCtrl.text.trim()}. Enter it below along with your new password.',
                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (step == 1) ...[
                TextField(
                  controller: emailPhoneCtrl,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email or Phone',
                    prefixIcon: Icon(Icons.contact_mail_outlined, color: AppTheme.primaryGreen),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final id = emailPhoneCtrl.text.trim();
                            if (id.isEmpty) return;
                            setModalState(() => isSubmitting = true);
                            try {
                              final dio = ref.read(dioClientProvider);
                              await dio.post('/auth/forgot-password', data: {'identifier': id});
                              setModalState(() {
                                isSubmitting = false;
                                step = 2;
                              });
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              messenger.showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Send Recovery Code'),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: codeCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: '6-Digit Code',
                    prefixIcon: Icon(Icons.pin, color: AppTheme.primaryGreen),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock, color: AppTheme.primaryGreen),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final code = codeCtrl.text.trim();
                            final newPass = newPassCtrl.text.trim();
                            if (code.isEmpty || newPass.isEmpty) return;
                            setModalState(() => isSubmitting = true);
                            try {
                              final dio = ref.read(dioClientProvider);
                              await dio.post('/auth/reset-password', data: {
                                'identifier': emailPhoneCtrl.text.trim(),
                                'code': code,
                                'new_password': newPass,
                              });
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Password reset successfully! You can now login.'),
                                  backgroundColor: AppTheme.primaryGreen,
                                ),
                              );
                              _passwordController.text = newPass;
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              messenger.showSnackBar(
                                SnackBar(content: Text('Reset failed: $e'), backgroundColor: AppTheme.errorRed),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Reset Password'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AsyncLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Welcome Back! 👋',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Login or signup to continue',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 32),

              // Tab Switcher (Phone vs Email)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? AppTheme.primaryGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Phone Number',
                            style: GoogleFonts.poppins(
                              color: _selectedTab == 0 ? Colors.black : AppTheme.textGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? AppTheme.primaryGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Email & Password',
                            style: GoogleFonts.poppins(
                              color: _selectedTab == 1 ? Colors.black : AppTheme.textGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              if (_selectedTab == 0) ...[
                // Phone Input Field
                Text(
                  'Phone Number',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(color: AppTheme.textWhite, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('🇮🇳', style: TextStyle(fontSize: 20)),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                  ),
                ),
              ] else ...[
                // Email Input Field
                Text(
                  'Email Address',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    hintText: 'user@example.com',
                    hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Password Input Field
                Text(
                  'Password',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textWhite,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: GoogleFonts.poppins(color: AppTheme.textWhite),
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGreen),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppTheme.primaryGreen,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.cardBorder),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordModal,
                    child: Text(
                      'Forgot Password?',
                      style: GoogleFonts.poppins(
                        color: AppTheme.primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        _selectedTab == 0 ? 'Continue with Phone' : 'Login with Email',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ),

              const SizedBox(height: 32),
              // Divider "or continue with"
              Row(
                children: [
                  const Expanded(child: Divider(color: AppTheme.cardBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'or continue with',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppTheme.cardBorder)),
                ],
              ),
              const SizedBox(height: 24),
              // Social Auth Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 24),
                      label: Text(
                        'Google',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/home'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.cardBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.person_outline, color: AppTheme.primaryGreen, size: 20),
                      label: Text(
                        'Guest',
                        style: GoogleFonts.poppins(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Footer link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: GoogleFonts.poppins(color: AppTheme.textGrey),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/signup'),
                    child: Text(
                      'Sign up',
                      style: GoogleFonts.poppins(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

