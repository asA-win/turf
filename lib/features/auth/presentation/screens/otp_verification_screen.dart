import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const OtpVerificationScreen({super.key, this.phoneNumber = '+91 98765 43210'});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final List<String> _otpDigits = ['', '', '', '', '', ''];
  int _currentIndex = 0;
  Timer? _timer;
  int _secondsRemaining = 45;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Auto-trigger OTP send on screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).sendOtp(widget.phoneNumber);
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resendOtp() async {
    _startCountdown();
    final success = await ref.read(authControllerProvider.notifier).sendOtp(widget.phoneNumber);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success 
              ? '⚡ A new real-time OTP was sent to ${widget.phoneNumber}'
              : 'Failed to send OTP. Please try again.',
        ),
        backgroundColor: success ? AppTheme.primaryGreen : AppTheme.errorRed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onKeyPress(String val) async {
    if (_isVerifying) return;

    if (val == 'backspace') {
      if (_currentIndex > 0) {
        setState(() {
          if (_otpDigits[_currentIndex].isEmpty && _currentIndex > 0) {
            _currentIndex--;
          }
          _otpDigits[_currentIndex] = '';
        });
      } else {
        setState(() {
          _otpDigits[0] = '';
        });
      }
    } else {
      if (_currentIndex < 6) {
        setState(() {
          _otpDigits[_currentIndex] = val;
          if (_currentIndex < 5) _currentIndex++;
        });
      }
    }

    if (_otpDigits.every((d) => d.isNotEmpty)) {
      final code = _otpDigits.join();
      setState(() => _isVerifying = true);

      final verified = await ref.read(authControllerProvider.notifier).verifyOtp(
        widget.phoneNumber,
        code,
      );

      if (!mounted) return;
      setState(() => _isVerifying = false);

      if (verified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Phone verified successfully!'),
            backgroundColor: AppTheme.primaryGreen,
            duration: Duration(seconds: 1),
          ),
        );
        final profile = await ref.read(fetchUserProfileProvider.future);
        if (!mounted) return;
        if (profile?.role == 'admin') {
          context.go('/analytics-dashboard');
        } else if (profile?.role == 'owner') {
          context.go('/venue-owner-dashboard');
        } else {
          context.go('/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Invalid or expired code. Please enter valid OTP.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        setState(() {
          for (int i = 0; i < 6; i++) {
            _otpDigits[i] = '';
          }
          _currentIndex = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify Your Number',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the 6-digit code sent to ${widget.phoneNumber}',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textGrey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // OTP Box Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        final isFilled = _otpDigits[index].isNotEmpty;
                        final isCurrent = index == _currentIndex;
                        return Container(
                          width: 48,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent
                                  ? AppTheme.primaryGreen
                                  : (isFilled ? AppTheme.primaryGreen.withOpacity(0.5) : AppTheme.cardBorder),
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _otpDigits[index],
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: _secondsRemaining == 0 ? _resendOtp : null,
                        child: Text.rich(
                          TextSpan(
                            text: "Didn't receive code? ",
                            style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                            children: [
                              TextSpan(
                                text: _secondsRemaining > 0
                                    ? 'Resend in 00:${_secondsRemaining.toString().padLeft(2, '0')}'
                                    : 'Resend Now',
                                style: GoogleFonts.poppins(
                                  color: _secondsRemaining > 0 ? AppTheme.primaryGreen : Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_isVerifying)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Custom Keypad
            Container(
              color: AppTheme.surfaceDark,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  _keypadRow(['1', '2', '3']),
                  _keypadRow(['4', '5', '6']),
                  _keypadRow(['7', '8', '9']),
                  _keypadRow(['', '0', 'backspace']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _keypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) return const SizedBox(width: 80, height: 60);
        return SizedBox(
          width: 80,
          height: 60,
          child: InkWell(
            onTap: () => _onKeyPress(key),
            borderRadius: BorderRadius.circular(30),
            child: Center(
              child: key == 'backspace'
                  ? const Icon(Icons.backspace_outlined, color: Colors.white)
                  : Text(
                      key,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
