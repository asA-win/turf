import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  bool _biometrics = true;
  bool _twoFactor = true;
  bool _loginAlerts = true;

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
        child: Padding(
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
                'Add extra security to protect your account',
                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              _switchTile('Enable Biometric Login', 'Use fingerprint or face ID', _biometrics, (v) => setState(() => _biometrics = v)),
              _switchTile('Two-Factor Authentication', 'Add an extra layer for security', _twoFactor, (v) => setState(() => _twoFactor = v)),
              _switchTile('Login Alerts', 'Get notified for new logins', _loginAlerts, (v) => setState(() => _loginAlerts = v)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Secure My Account'),
              ),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text('Set Up Later', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
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
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }
}
