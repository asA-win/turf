import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/auth/presentation/controllers/auth_controller.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  bool _isDeleting = false;

  void _onDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text(
          'Confirm Permanent Deletion',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you absolutely sure you want to permanently delete your account and all associated data?',
          style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.delete('/users/me');
      await ref.read(authControllerProvider.notifier).logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      context.go('/welcome');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Delete Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.errorRed.withOpacity(0.15),
                ),
                child: const Icon(Icons.delete_forever, size: 64, color: AppTheme.errorRed),
              ),
              const SizedBox(height: 20),
              Text(
                "We're sad to see you go! 😔",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete your account? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This will permanently delete:',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    _bullet('Your profile and personal data'),
                    _bullet('All your bookings and history'),
                    _bullet('Wallet balance and transactions'),
                    _bullet('Team and chat data'),
                  ],
                ),
              ),
              const Spacer(),
              if (_isDeleting)
                const CircularProgressIndicator(color: AppTheme.errorRed)
              else
                ElevatedButton(
                  onPressed: _onDeleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                  ),
                  child: Text('Delete My Account', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.pop(),
                child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppTheme.errorRed, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12))),
        ],
      ),
    );
  }
}
