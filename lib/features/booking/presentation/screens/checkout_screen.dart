import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/domain/models/slot.dart';
import 'package:turf_app/features/turf_details/domain/models/turf.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const CheckoutScreen({super.key, this.data});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool useWallet = false;
  final TextEditingController _couponController = TextEditingController(text: 'TURF100');

  @override
  Widget build(BuildContext context) {
    final isTournament = widget.data?['isTournamentBooking'] == true || widget.data?['tournament'] != null;
    final tournament = widget.data?['tournament'] as Map<String, dynamic>?;
    final turf = widget.data?['turf'] as Turf?;
    final slot = widget.data?['slot'] as Slot?;

    final turfName = isTournament
        ? (tournament?['name'] as String? ?? 'Tournament Registration')
        : (turf?.name ?? 'Turf Arena');
    final location = isTournament
        ? (tournament?['venue'] as String? ?? 'Bengaluru')
        : (turf?.location ?? 'Bengaluru');
    final price = (widget.data?['price'] as num?)?.toDouble() ?? (turf?.pricePerHour ?? 1200.0);
    
    final timeStr = isTournament
        ? (tournament?['dates'] as String? ?? 'Scheduled Tournament Fixture')
        : (slot != null
            ? '${DateFormat('EEE, dd MMM').format(slot.startTime.toLocal())} • ${DateFormat('hh:mm a').format(slot.startTime.toLocal())} - ${DateFormat('hh:mm a').format(slot.endTime.toLocal())}'
            : 'Today • 08:00 PM - 09:00 PM');

    final total = useWallet ? (price - 100.0) : price;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Turf Booking Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            turfName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textWhite,
                            ),
                          ),
                          Text(
                            location,
                            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                          ),
                          const Divider(color: AppTheme.cardBorder, height: 24),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, color: AppTheme.primaryGreen, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  timeStr,
                                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textWhite),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                isTournament
                                    ? '${tournament?['sport'] ?? 'Tournament'} • ${widget.data?['teamName'] ?? 'Team'}'
                                    : (turf?.sportTypes ?? 'Football'),
                                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textWhite),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Coupon Row
                    Text(
                      'Offers & Coupons',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer_outlined, color: AppTheme.primaryGreen, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _couponController,
                              style: GoogleFonts.poppins(color: AppTheme.textWhite, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: 'Enter coupon code',
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Coupon TURF100 applied! Saved ₹100')),
                              );
                            },
                            child: Text(
                              'APPLY',
                              style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Wallet Toggle Option
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primaryGreen, size: 20),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Use Wallet Balance',
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                                  ),
                                  Text(
                                    'Available: ₹200',
                                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch(
                            value: useWallet,
                            activeColor: AppTheme.primaryGreen,
                            onChanged: (val) => setState(() => useWallet = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Price Breakdown Details
                    Text(
                      'Price Details',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                    ),
                    const SizedBox(height: 12),
                    _priceRow('Slot Price', '₹${price.toInt()}'),
                    if (useWallet) _priceRow('Wallet Credits', '-₹100', isDiscount: true),
                    const Divider(color: AppTheme.cardBorder, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                        ),
                        Text(
                          '₹${total.toInt()}',
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Proceed Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.push('/payment', extra: {
                    'turf': turf,
                    'slot': slot,
                    'totalPrice': total,
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Proceed to Pay',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, String amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textGrey),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDiscount ? AppTheme.primaryGreen : AppTheme.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}
