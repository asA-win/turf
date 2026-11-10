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

  final addons = [
    {'name': 'Flood Lights', 'price': '₹200 / Hour', 'active': true},
    {'name': 'Ball (Per Piece)', 'price': '₹50', 'active': true},
    {'name': 'Bib Set', 'price': '₹80', 'active': true},
    {'name': 'Water Bottle (1 Litre)', 'price': '₹20', 'active': true},
    {'name': 'Referee', 'price': '₹500 / Match', 'active': false},
    {'name': 'First Aid Kit', 'price': '₹100 / Match', 'active': true},
  ];

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
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: addons.length,
                itemBuilder: (context, index) {
                  final a = addons[index];
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('Add New Add-on'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
