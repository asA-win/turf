import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  final List<Map<String, String>> leaderboard = const [
    {'rank': '1', 'name': 'Rahul Sharma', 'points': '₹2,500', 'referrals': '25 invites'},
    {'rank': '2', 'name': 'Priya Menon', 'points': '₹1,950', 'referrals': '19 invites'},
    {'rank': '3', 'name': 'Alex Johnson', 'points': '₹1,200', 'referrals': '12 invites'},
    {'rank': '4', 'name': 'Vikram Singh', 'points': '₹800', 'referrals': '8 invites'},
  ];

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Referral code "$code" copied to clipboard!'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Share Referral Link', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                IconButton(icon: const Icon(Icons.close, color: AppTheme.textGrey), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _shareOption(ctx, Icons.chat, 'WhatsApp', const Color(0xFF25D366)),
                _shareOption(ctx, Icons.send, 'Telegram', const Color(0xFF0088CC)),
                _shareOption(ctx, Icons.sms_outlined, 'SMS', Colors.orange),
                _shareOption(ctx, Icons.link, 'Copy Link', AppTheme.primaryGreen),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Your friend gets ₹150 off their first turf booking, and you get ₹100 straight to your wallet!',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _shareOption(BuildContext context, IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Clipboard.setData(const ClipboardData(text: 'https://turf.app/ref/BYS2024'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Referral link shared via $label! Link copied.'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textWhite, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Referral & Earn',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Gift Box Illustration Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF132A1C), Color(0xFF0F3E22)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.card_giftcard, size: 64, color: AppTheme.primaryGreen),
                    const SizedBox(height: 12),
                    Text(
                      'Refer Friends & Win Cash',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Earn ₹100 instant cash for every friend who books a turf',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Referral Code Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'BYS2024',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite, letterSpacing: 2),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: AppTheme.primaryGreen, size: 20),
                            onPressed: () => _copyCode(context, 'BYS2024'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Earnings Summary Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        children: [
                          Text('Friends Invited', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
                          const SizedBox(height: 4),
                          Text('12', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        children: [
                          Text('Total Earned', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
                          const SizedBox(height: 4),
                          Text('₹1,200', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Leaderboard Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Top Referrers Leaderboard',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                ),
              ),
              const SizedBox(height: 12),
              ...leaderboard.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: item['rank'] == '1' ? Colors.amber : (item['rank'] == '2' ? Colors.grey : Colors.brown),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            item['rank']!,
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name']!,
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                            ),
                            Text(
                              item['referrals']!,
                              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item['points']!,
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Invite CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _showShareOptions(context),
                  icon: const Icon(Icons.share, color: Colors.black, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  label: Text(
                    'Invite Friends Now',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
