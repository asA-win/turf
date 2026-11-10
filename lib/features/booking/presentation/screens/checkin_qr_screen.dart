import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class CheckInQrScreen extends StatefulWidget {
  const CheckInQrScreen({super.key});

  @override
  State<CheckInQrScreen> createState() => _CheckInQrScreenState();
}

class _CheckInQrScreenState extends State<CheckInQrScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Check-In'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textGrey,
          tabs: const [
            Tab(text: 'QR Code'),
            Tab(text: 'Manual Code'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildQrView(),
            _buildManualView(),
          ],
        ),
      ),
    );
  }

  Widget _buildQrView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Show this QR code to the turf staff to check-in', textAlign: TextAlign.center, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.qr_code_2, size: 220, color: Colors.black),
                Text('BYS', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Booking ID: BYS2505187200', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text('Green Field Arena • 18 May 2025, 7:00 PM', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
          const SizedBox(height: 16),
          Text('Check-in available 15 mins before your slot.', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 12)),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => context.push('/support-center'),
            icon: const Icon(Icons.help_outline, color: AppTheme.textGrey),
            label: Text('Facing issues? Contact Support', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
          ),
        ],
      ),
    );
  }

  Widget _buildManualView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Tell this 6-digit code to the venue staff', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 14)),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryGreen, width: 2),
            ),
            child: Text(
              '8 4 9 2 0 1',
              style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }
}
