import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/widgets/bys_bottom_nav_bar.dart';
import 'package:turf_app/core/widgets/bys_profile_avatar.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String selectedCategory = 'All';
  int cartCount = 1;
  final List<Map<String, dynamic>> cartItems = [
    {'name': 'Professional Match Ball', 'price': 1299, 'qty': 1},
  ];

  final List<Map<String, dynamic>> products = [
    {'name': 'Pro Turf Football Boots', 'price': 2499, 'icon': Icons.directions_run, 'category': 'Footwear', 'rating': 4.9},
    {'name': 'BYS Training Jersey', 'price': 899, 'icon': Icons.checkroom, 'category': 'Apparel', 'rating': 4.7},
    {'name': 'FIFA Pro Match Ball', 'price': 1299, 'icon': Icons.sports_soccer, 'category': 'Equipment', 'rating': 4.8},
    {'name': 'Anti-Slip Grip Socks', 'price': 399, 'icon': Icons.layers, 'category': 'Accessories', 'rating': 4.6},
    {'name': 'Goalkeeper Pro Gloves', 'price': 1599, 'icon': Icons.front_hand, 'category': 'Equipment', 'rating': 4.8},
    {'name': 'Sports Water Bottle (1L)', 'price': 499, 'icon': Icons.local_drink, 'category': 'Accessories', 'rating': 4.5},
  ];

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          int total = cartItems.fold(0, (sum, item) => sum + ((item['price'] as int) * (item['qty'] as int)));
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Cart (${cartItems.length})', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                    IconButton(icon: const Icon(Icons.close, color: AppTheme.textGrey), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(color: AppTheme.cardBorder),
                if (cartItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(child: Text('Your cart is empty', style: GoogleFonts.poppins(color: AppTheme.textGrey))),
                  )
                else
                  ...cartItems.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                            Text('₹${item['price']} x ${item['qty']}', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primaryGreen)),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textGrey, size: 20),
                              onPressed: () {
                                setSheetState(() {
                                  if (item['qty'] > 1) {
                                    item['qty']--;
                                  } else {
                                    cartItems.remove(item);
                                  }
                                });
                                setState(() => cartCount = cartItems.length);
                              },
                            ),
                            Text('${item['qty']}', style: GoogleFonts.poppins(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen, size: 20),
                              onPressed: () {
                                setSheetState(() => item['qty']++);
                                setState(() => cartCount = cartItems.length);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                    Text('₹$total', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: cartItems.isEmpty ? null : () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order placed successfully! Delivery in 24 hrs.'), backgroundColor: AppTheme.primaryGreen),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Checkout Now', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      final existingIndex = cartItems.indexWhere((item) => item['name'] == product['name']);
      if (existingIndex >= 0) {
        cartItems[existingIndex]['qty']++;
      } else {
        cartItems.add({
          'name': product['name'],
          'price': product['price'],
          'qty': 1,
        });
      }
      cartCount = cartItems.length;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} added to cart!'),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 1),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: Colors.black,
          onPressed: _showCartSheet,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCategory == 'All'
        ? products
        : products.where((p) => p['category'] == selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text('TURF STORE', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: AppTheme.textWhite),
                onPressed: _showCartSheet,
              ),
              if (cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$cartCount',
                      style: GoogleFonts.poppins(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          const Center(child: BysProfileAvatar(size: 34)),
          const SizedBox(width: 14),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          _buildPromotions(),

          // Categories Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['All', 'Footwear', 'Apparel', 'Equipment', 'Accessories'].map((cat) {
                final isSelected = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(cat),
                    labelStyle: GoogleFonts.poppins(
                      color: isSelected ? Colors.black : AppTheme.textWhite,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.cardDark,
                    side: BorderSide(color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder),
                    onSelected: (val) => setState(() => selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Products (${filtered.length})', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final product = filtered[index];
                return _productCard(product);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BysBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildPromotions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F381E), Color(0xFF1B5E34)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('30% OFF', style: GoogleFonts.poppins(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                Text('Pro Turf Sports Gear', style: GoogleFonts.poppins(color: AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Free venue delivery within 2 hours', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.sports_soccer, size: 60, color: AppTheme.primaryGreen),
        ],
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(product['icon'] as IconData, size: 52, color: AppTheme.primaryGreen),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product['category'] as String, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 10, fontWeight: FontWeight.w600)),
                Text(
                  product['name'] as String,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textWhite),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${product['price']}', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text('${product['rating']}', style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textGrey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => _addToCart(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Add to Cart', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
