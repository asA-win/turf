import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/wallet/presentation/controllers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  StreamSubscription<Map<String, dynamic>>? _walletSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _walletSub = ref.read(realtimeServiceProvider).connectToChannel('booking_updates').listen((event) {
          if (mounted && event['type'] == 'wallet_updated') {
            final balance = (event['balance'] as num?)?.toDouble();
            if (balance != null) {
              // Updated live
            }
          }
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _walletSub?.cancel();
    super.dispose();
  }
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
                    ref.read(walletProvider.notifier).topUp(selectedAmount.toDouble());
                    try {
                      ref.read(dioClientProvider).post('/users/wallet/add-money?amount=$selectedAmount');
                    } catch (_) {}
                    try {
                      ref.read(realtimeServiceProvider).emitToChannel('booking_updates', {
                        'type': 'wallet_updated',
                        'amount': selectedAmount,
                      });
                    } catch (_) {}
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
                Text('Transfer to Friend', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                IconButton(icon: const Icon(Icons.close, color: AppTheme.textGrey), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.poppins(color: AppTheme.textWhite),
              decoration: InputDecoration(
                labelText: 'Friend\'s Mobile / UPI ID',
                labelStyle: GoogleFonts.poppins(color: AppTheme.textGrey),
                prefixIcon: const Icon(Icons.person_search, color: AppTheme.primaryGreen),
                fillColor: AppTheme.surfaceDark,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amtController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(color: AppTheme.textWhite),
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                labelStyle: GoogleFonts.poppins(color: AppTheme.textGrey),
                prefixIcon: const Icon(Icons.currency_rupee, color: AppTheme.primaryGreen),
                fillColor: AppTheme.surfaceDark,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final amt = double.tryParse(amtController.text.trim()) ?? 0.0;
                  final phone = phoneController.text.trim();
                  if (phone.isEmpty || amt <= 0) return;

                  final currentBal = ref.read(walletProvider).balance;
                  if (currentBal < amt) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Insufficient balance. Please top up first.')),
                    );
                    return;
                  }

                  ref.read(walletProvider.notifier).deduct(amt, 'Transfer to $phone');
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('₹${amt.toInt()} sent to $phone successfully!'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Transfer Instantly', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'BYS Wallet',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppTheme.textWhite),
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
              // Main Wallet Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF132A1C), Color(0xFF09140E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Balance', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textGrey)),
                        _rewardBadge(Icons.monetization_on, '${wallet.coins} Coins', Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${wallet.balance.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showAddMoneyModal,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text('Add Money', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showSendMoneyModal,
                            icon: const Icon(Icons.arrow_upward, size: 18, color: AppTheme.primaryGreen),
                            label: Text('Send Money', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.primaryGreen),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Quick Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _quickAction(Icons.local_offer, 'Coupons', () => context.push('/offers-promotions')),
                  _quickAction(Icons.receipt_long, 'History', () => context.push('/transactions')),
                  _quickAction(Icons.monetization_on_outlined, 'BYS Coins', () => context.push('/bys-coins')),
                  _quickAction(Icons.trending_up, 'Shares', () => context.push('/stock-shares')),
                ],
              ),

              const SizedBox(height: 32),

              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Transactions', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                  if (wallet.transactions.isNotEmpty)
                    TextButton(
                      onPressed: () => context.push('/transactions'),
                      child: Text('View All', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primaryGreen)),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Transactions List or Empty State
              if (wallet.transactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text('No Transactions Yet', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                      const SizedBox(height: 4),
                      Text('Top up your wallet to book slots with 1 click.', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12), textAlign: TextAlign.center),
                    ],
                  ),
                )
              else
                ...wallet.transactions.take(5).map((tx) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: tx.isCredit ? AppTheme.primaryGreen.withValues(alpha: 0.15) : AppTheme.errorRed.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                            color: tx.isCredit ? AppTheme.primaryGreen : AppTheme.errorRed,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tx.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                              Text(tx.date, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                            ],
                          ),
                        ),
                        Text(
                          tx.amount,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: tx.isCredit ? AppTheme.primaryGreen : AppTheme.textWhite,
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

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey, fontWeight: FontWeight.w500)),
        ],
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
          Text(text, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
        ],
      ),
    );
  }
}
