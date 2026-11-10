import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class AccountSecurityScreen extends ConsumerStatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  ConsumerState<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends ConsumerState<AccountSecurityScreen> {
  bool _biometrics = true;
  bool _twoFactor = true;
  bool _loginAlerts = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _biometrics = prefs.getBool('sec_biometrics') ?? true;
        _twoFactor = prefs.getBool('sec_twoFactor') ?? true;
        _loginAlerts = prefs.getBool('sec_loginAlerts') ?? true;
        _isLoading = false;
      });
    }
  }

  void _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sec_biometrics', _biometrics);
    await prefs.setBool('sec_twoFactor', _twoFactor);
    await prefs.setBool('sec_loginAlerts', _loginAlerts);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Security settings updated successfully'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
    context.pop();
  }

  void _openChangePasswordModal() {
    final messenger = ScaffoldMessenger.of(context);
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();
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
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Password',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: oldPassController,
                  obscureText: true,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryGreen),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPassController,
                  obscureText: true,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock, color: AppTheme.primaryGreen),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => isSubmitting = true);
                            try {
                              final dio = ref.read(dioClientProvider);
                              await dio.post('/auth/change-password', data: {
                                'old_password': oldPassController.text.trim(),
                                'new_password': newPassController.text.trim(),
                              });
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Password changed successfully!'),
                                  backgroundColor: AppTheme.primaryGreen,
                                ),
                              );
                            } catch (e) {
                              setModalState(() => isSubmitting = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Failed to change password: $e'),
                                  backgroundColor: AppTheme.errorRed,
                                ),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Update Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Account Security'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryGreen.withOpacity(0.15),
                        ),
                        child: const Icon(Icons.security, size: 64, color: AppTheme.primaryGreen),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Secure Your Account',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Manage biometric access, two-factor authentication, and credentials.',
                      style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    _switchTile(
                      'Enable Biometric Login',
                      'Use fingerprint or face recognition',
                      _biometrics,
                      (v) => setState(() => _biometrics = v),
                    ),
                    _switchTile(
                      'Two-Factor Authentication',
                      'Require OTP code during new device logins',
                      _twoFactor,
                      (v) => setState(() => _twoFactor = v),
                    ),
                    _switchTile(
                      'Login Alerts',
                      'Receive live push notifications on new sign-ins',
                      _loginAlerts,
                      (v) => setState(() => _loginAlerts = v),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.cardBorder),
                      ),
                      tileColor: AppTheme.cardDark,
                      leading: const Icon(Icons.password, color: AppTheme.primaryGreen),
                      title: Text(
                        'Change Password',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Update your account login password',
                        style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textGrey),
                      onTap: _openChangePasswordModal,
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _savePreferences,
                      child: const Text('Save Security Settings'),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                Text(subtitle, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppTheme.primaryGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
