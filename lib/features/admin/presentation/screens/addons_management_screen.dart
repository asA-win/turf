import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class AddonsManagementScreen extends StatefulWidget {
  const AddonsManagementScreen({super.key});

  @override
  State<AddonsManagementScreen> createState() => _AddonsManagementScreenState();
}

class _AddonsManagementScreenState extends State<AddonsManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> addons = [
    {'name': 'Flood Lights', 'price': '₹200 / Hour', 'active': true},
    {'name': 'Match Ball (Per Piece)', 'price': '₹50', 'active': true},
    {'name': 'Bib Set (10 Bibs)', 'price': '₹80', 'active': true},
    {'name': 'Mineral Water (Pack of 12)', 'price': '₹200', 'active': true},
    {'name': 'Official Referee', 'price': '₹500 / Match', 'active': false},
    {'name': 'First Aid Kit & Ice Pack', 'price': '₹100 / Match', 'active': true},
  ];

  final List<Map<String, dynamic>> amenities = [
    {'name': 'Changing Rooms & Showers', 'price': 'Included', 'active': true},
    {'name': 'Dedicated Free Parking', 'price': 'Included', 'active': true},
    {'name': 'Spectator Stand Seating', 'price': 'Included', 'active': true},
    {'name': 'Hi-Speed WiFi', 'price': 'Included', 'active': true},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add New Item', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Item Name', fillColor: AppTheme.surfaceDark),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Price (e.g. ₹100 / Hour)', fillColor: AppTheme.surfaceDark),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = priceCtrl.text.trim();
              if (name.isNotEmpty && price.isNotEmpty) {
                setState(() {
                  if (_tabController.index == 0) {
                    addons.add({'name': name, 'price': price, 'active': true});
                  } else {
                    amenities.add({'name': name, 'price': price, 'active': true});
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name added successfully!'), backgroundColor: AppTheme.primaryGreen),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.black),
            child: Text('Add', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Add-ons & Amenities'),
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
            Tab(text: 'Add-ons'),
            Tab(text: 'Amenities'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(addons),
                  _buildList(amenities),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: Text(
                    _tabController.index == 0 ? 'Add New Add-on' : 'Add New Amenity',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final a = list[index];
        final isAct = a['active'] as bool;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: ListTile(
            title: Text(a['name'] as String, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(a['price'] as String, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 12)),
            trailing: Switch(
              value: isAct,
              onChanged: (v) => setState(() => a['active'] = v),
              activeColor: AppTheme.primaryGreen,
            ),
          ),
        );
      },
    );
  }
}
