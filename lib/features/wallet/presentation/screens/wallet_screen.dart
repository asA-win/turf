import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double balance = 2450.0;
  int coins = 1260;
  int gems = 350;

  final List<Map<String, String>> transactions = [
    {'title': 'Booking Payment (Greenfield)', 'date': 'Today, 08:30 PM', 'amount': '-₹1,200', 'isCredit': 'false'},
    {'title': 'Cashback Received', 'date': 'Today, 08:31 PM', 'amount': '+₹100', 'isCredit': 'true'},
    {'title': 'Referral Bonus (Friend Joined)', 'date': 'Yesterday, 04:15 PM', 'amount': '+₹250', 'isCredit': 'true'},
    {'title': 'Wallet Top-Up (UPI)', 'date': '20 May, 11:20 AM', 'amount': '+₹1,000', 'isCredit': 'true'},
  ];

  void _showAddMoneyModal() {
    int selectedAmount = 1000;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add Money to Wallet', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                  IconButton(icon: const Icon(Icons.close, color: AppTheme.textGrey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Text('Select Top-Up Amount', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textGrey)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [500, 1000, 2000, 5000].map((amt) {
                  final isSel = selectedAmount == amt;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedAmount = amt),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSel ? AppTheme.primaryGreen.withValues(alpha: 0.2) : AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSel ? AppTheme.primaryGreen : AppTheme.cardBorder),
                      ),
                      child: Text('₹$amt', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isSel ? AppTheme.primaryGreen : AppTheme.textWhite)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final timeNow = DateFormat('dd MMM, hh:mm a').format(DateTime.now());
                    setState(() {
                      balance += selectedAmount;
                      transactions.insert(0, {
                        'title': 'Wallet Top-Up (Instant UPI)',
                        'date': timeNow,
                        'amount': '+₹$selectedAmount',
                        'isCredit': 'true',
                      });
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('₹$selectedAmount added to BYS Wallet successfully!'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Add ₹$selectedAmount via UPI', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSendMoneyModal() {
    final phoneController = TextEditingController();
    final amtController = TextEditingController(text: '200');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Send Money to Teammate', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                IconButton(icon: const Icon(Icons.close, color: AppTheme.textGrey), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 14),
            Text('Recipient Phone / UPI ID', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
            const SizedBox(height: 6),
            TextField(
              controller: phoneController,
              style: GoogleFonts.poppins(color: AppTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'e.g. 9876543210 or player@upi',
                hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.surfaceDark,
                prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(height: 14),
            Text('Amount (₹)', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
            const SizedBox(height: 6),
            TextField(
              controller: amtController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(color: AppTheme.textWhite),
              decoration: InputDecoration(
                hintText: 'Amount',
                filled: true,
                fillColor: AppTheme.surfaceDark,
                prefixIcon: const Icon(Icons.currency_rupee, color: AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final amt = double.tryParse(amtController.text.trim()) ?? 0;
                  if (amt > 0 && amt <= balance) {
                    final timeNow = DateFormat('dd MMM, hh:mm a').format(DateTime.now());
                    setState(() {
                      balance -= amt;
                      transactions.insert(0, {
                        'title': 'Sent to ${phoneController.text.isNotEmpty ? phoneController.text : "Teammate"}',
                        'date': timeNow,
                        'amount': '-₹${amt.toInt()}',
                        'isCredit': 'false',
                      });
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('₹${amt.toInt()} sent successfully!'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Insufficient balance or invalid amount'), backgroundColor: AppTheme.errorRed),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Send Money', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Wallet & Rewards',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppTheme.primaryGreen),
            onPressed: () => context.push('/transactions'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textGrey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${balance.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                    ),
                    const SizedBox(height: 20),

                    // Rewards sub-row (Coins & Gems)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/bys-coins'),
                          child: _rewardBadge(Icons.monetization_on, '$coins Coins', Colors.amber),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => context.push('/bys-coins'),
                          child: _rewardBadge(Icons.diamond, '$gems Gems', Colors.lightBlueAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showAddMoneyModal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.add, color: Colors.black, size: 18),
                            label: Text(
                              'Add Money',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showSendMoneyModal,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryGreen),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.send_outlined, color: AppTheme.primaryGreen, size: 18),
                            label: Text(
                              'Send',
                              style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Recent Transactions Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                  ),
                  TextButton(
                    onPressed: () => context.push('/transactions'),
                    child: Text(
                      'View All',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...transactions.map((tx) {
                final isCredit = tx['isCredit'] == 'true';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCredit ? AppTheme.primaryGreen.withValues(alpha: 0.15) : AppTheme.errorRed.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit ? AppTheme.primaryGreen : AppTheme.errorRed,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx['title']!,
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                            ),
                            Text(
                              tx['date']!,
                              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        tx['amount']!,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isCredit ? AppTheme.primaryGreen : AppTheme.textWhite,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
          ),
        ],
      ),
    );
  }
}
