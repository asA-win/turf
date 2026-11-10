import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class PromoCodeScreen extends StatefulWidget {
  const PromoCodeScreen({super.key});

  @override
  State<PromoCodeScreen> createState() => _PromoCodeScreenState();
}

class _PromoCodeScreenState extends State<PromoCodeScreen> {
  final TextEditingController _codeController = TextEditingController(text: 'BYS10');
  bool _applied = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Promo Code'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: 'Enter Promo Code',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => setState(() => _applied = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      minimumSize: const Size(90, 52),
                    ),
                    child: Text('Apply', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (_applied) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 18),
                    const SizedBox(width: 6),
                    Text('Promo code applied successfully!', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    _priceRow('Turf Booking', '₹1600'),
                    _priceRow('Extras', '₹920'),
                    _priceRow('Subtotal', '₹2520'),
                    _priceRow('Promo Discount (BYS10)', '- ₹252', isGreen: true),
                    _priceRow('Platform Fee', '₹48'),
                    const Divider(color: AppTheme.cardBorder, height: 24),
                    _priceRow('Total Amount', '₹2316', isBold: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('You saved ₹232 on this booking!', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.push('/checkout'),
                child: const Text('Proceed to Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceRow(String label, String val, {bool isGreen = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: isBold ? Colors.white : AppTheme.textGrey, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 15 : 13)),
          Text(val, style: GoogleFonts.poppins(color: isGreen ? AppTheme.primaryGreen : Colors.white, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 13)),
        ],
      ),
    );
  }
}
