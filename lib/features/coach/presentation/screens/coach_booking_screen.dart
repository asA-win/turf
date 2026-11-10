import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class CoachBookingScreen extends StatefulWidget {
  const CoachBookingScreen({super.key});

  @override
  State<CoachBookingScreen> createState() => _CoachBookingScreenState();
}

class _CoachBookingScreenState extends State<CoachBookingScreen> {
  String searchQuery = '';
  String selectedCategory = 'All';

  final List<Map<String, dynamic>> coaches = [
    {
      'name': 'Rahul Sharma',
      'role': 'Football Head Coach',
      'category': 'Football',
      'rating': '4.8',
      'reviews': 86,
      'price': '₹1,500/session',
      'experience': '8 years exp • UEFA B',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
    },
    {
      'name': 'David Martinez',
      'role': 'AFC Certified Tactical Coach',
      'category': 'Football',
      'rating': '4.7',
      'reviews': 54,
      'price': '₹1,350/session',
      'experience': '6 years exp • AFC Pro',
      'avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
    },
    {
      'name': 'Vikram Singh',
      'role': 'Cricket Bowling & Tactics',
      'category': 'Cricket',
      'rating': '4.9',
      'reviews': 112,
      'price': '₹1,200/session',
      'experience': '10 years exp • BCCI L2',
      'avatar': 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=100',
    },
    {
      'name': 'Ananya Roy',
      'role': 'Tennis & Badminton Pro',
      'category': 'Racquet',
      'rating': '4.8',
      'reviews': 67,
      'price': '₹1,100/session',
      'experience': '5 years exp • Certified',
      'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
    },
    {
      'name': 'Marcus Vance',
      'role': 'Athletic Fitness & Agility',
      'category': 'Fitness',
      'rating': '4.6',
      'reviews': 43,
      'price': '₹900/session',
      'experience': '4 years exp • CSCS',
      'avatar': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
    },
  ];

  void _showBookingModal(Map<String, dynamic> coach) {
    String selectedSlot = 'Today • 06:00 PM';
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
                  Text('Book Coaching Session', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                  IconButton(icon: const Icon(Icons.close, color: AppTheme.textGrey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(radius: 24, backgroundImage: NetworkImage(coach['avatar'])),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coach['name'], style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                      Text(coach['role'], style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey)),
                    ],
                  ),
                  const Spacer(),
                  Text(coach['price'], style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Select Training Slot', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Today • 06:00 PM',
                  'Today • 07:30 PM',
                  'Tomorrow • 06:30 AM',
                  'Tomorrow • 05:00 PM',
                ].map((slot) {
                  final isSel = selectedSlot == slot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: isSel,
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.surfaceDark,
                    labelStyle: GoogleFonts.poppins(
                      color: isSel ? Colors.black : AppTheme.textWhite,
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(color: isSel ? AppTheme.primaryGreen : AppTheme.cardBorder),
                    onSelected: (val) => setModalState(() => selectedSlot = slot),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Session booked with ${coach['name']} for $selectedSlot!'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Confirm Coaching Session', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = coaches.where((c) {
      final matchesSearch = c['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          c['role'].toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == 'All' || c['category'] == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Coach Booking',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val),
                style: GoogleFonts.poppins(color: AppTheme.textWhite),
                decoration: InputDecoration(
                  hintText: 'Search coaches by name, sport...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                  fillColor: AppTheme.cardDark,
                ),
              ),
            ),

            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: ['All', 'Football', 'Cricket', 'Racquet', 'Fitness'].map((cat) {
                  final isSel = selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSel,
                      label: Text(cat),
                      labelStyle: GoogleFonts.poppins(
                        color: isSel ? Colors.black : AppTheme.textWhite,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      selectedColor: AppTheme.primaryGreen,
                      backgroundColor: AppTheme.cardDark,
                      side: BorderSide(color: isSel ? AppTheme.primaryGreen : AppTheme.cardBorder),
                      onSelected: (val) => setState(() => selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Coaches List
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('No coaches found matching "$searchQuery"', style: GoogleFonts.poppins(color: AppTheme.textGrey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final coach = filtered[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: NetworkImage(coach['avatar']!),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          coach['name']!,
                                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                                        ),
                                        Text(
                                          coach['role']!,
                                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${coach['rating']} (${coach['reviews']} reviews)',
                                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    coach['price']!,
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(coach['experience']!, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted)),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: () => _showBookingModal(coach),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGreen,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text(
                                    'Book a Session',
                                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
