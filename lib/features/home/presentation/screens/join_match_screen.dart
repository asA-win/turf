import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class JoinMatchScreen extends StatefulWidget {
  const JoinMatchScreen({super.key});

  @override
  State<JoinMatchScreen> createState() => _JoinMatchScreenState();
}

class _JoinMatchScreenState extends State<JoinMatchScreen> {
  String selectedSport = 'All';

  final List<Map<String, dynamic>> matches = [
    {
      'id': 1,
      'sport': 'Football',
      'time': 'Today • 7:00 PM',
      'format': '5v5 Match',
      'team1': 'TURF TITANS',
      'team2': 'KICKERS UNITED',
      'venue': 'Play Arena',
      'location': 'Koramangala, Bengaluru',
      'spotsLeft': 3,
      'totalSpots': 10,
      'joinedCount': 7,
      'joined': '7/10 Joined',
      'price': '₹150 / player',
    },
    {
      'id': 2,
      'sport': 'Football',
      'time': 'Today • 8:30 PM',
      'format': '7v7 Match',
      'team1': 'STRIKERS FC',
      'team2': 'GOAL DIGGERS',
      'venue': 'Greenfield Arena',
      'location': 'HSR Layout, Bengaluru',
      'spotsLeft': 2,
      'totalSpots': 14,
      'joinedCount': 12,
      'joined': '12/14 Joined',
      'price': '₹180 / player',
    },
    {
      'id': 3,
      'sport': 'Cricket',
      'time': 'Tomorrow • 6:30 AM',
      'format': 'Box Cricket 6v6',
      'team1': 'BLASTER XI',
      'team2': 'ROYAL CHALKS',
      'venue': 'Turf Nation',
      'location': 'Electronic City, Bengaluru',
      'spotsLeft': 4,
      'totalSpots': 12,
      'joinedCount': 8,
      'joined': '8/12 Joined',
      'price': '₹120 / player',
    },
    {
      'id': 4,
      'sport': 'Badminton',
      'time': 'Today • 9:00 PM',
      'format': 'Doubles Match',
      'team1': 'SMASH KINGS',
      'team2': 'DROP SHOTS',
      'venue': 'Victory Turf',
      'location': 'Bellandur, Bengaluru',
      'spotsLeft': 1,
      'totalSpots': 4,
      'joinedCount': 3,
      'joined': '3/4 Joined',
      'price': '₹100 / player',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = selectedSport == 'All'
        ? matches
        : matches.where((m) => m['sport'] == selectedSport).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Join Turf & Matches',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Turfs with spaces remaining • Split & play',
              style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF8E9E94)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sport Filters Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ['All', 'Football', 'Cricket', 'Badminton'].map((sport) {
                    final isSelected = selectedSport == sport;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Text(sport),
                        labelStyle: GoogleFonts.poppins(
                          color: isSelected ? Colors.black : AppTheme.textWhite,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        selectedColor: AppTheme.primaryGreen,
                        backgroundColor: AppTheme.cardDark,
                        side: const BorderSide(color: AppTheme.cardBorder),
                        onSelected: (val) => setState(() => selectedSport = sport),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Matches List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sports_soccer, color: Color(0xFF4C5E53), size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No open turfs found for $selectedSport',
                            style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final match = filtered[index];
                        final spotsLeft = match['spotsLeft'] as int;
                        final totalSpots = match['totalSpots'] as int;
                        final joinedCount = match['joinedCount'] as int;
                        final progress = joinedCount / totalSpots;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: Time + Spots Left badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, color: AppTheme.primaryGreen, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        match['time'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppTheme.primaryGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                                        width: 0.6,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.flash_on, color: Color(0xFFFF9800), size: 10),
                                        const SizedBox(width: 2),
                                        Text(
                                          '$spotsLeft SPOTS LEFT',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFFFB74D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Match Teams or Format
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: Text(
                                      match['team1'],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textWhite,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'VS',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      match['team2'],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textWhite,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Progress Bar of Capacity
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${match['joined']} • ${(progress * 100).toInt()}% Filled',
                                    style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF8E9E94)),
                                  ),
                                  Text(
                                    match['price'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF00E5FF),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 4,
                                  backgroundColor: const Color(0xFF1E2E22),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                                ),
                              ),
                              const SizedBox(height: 12),

                              const Divider(color: AppTheme.cardBorder, height: 1),
                              const SizedBox(height: 12),

                              // Venue & Join CTA Button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          match['venue'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: AppTheme.textWhite,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${match['format']} • ${match['location']}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: AppTheme.textGrey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () => context.push('/slot-selection/${match['id']}'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00E5FF),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Join Now',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
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
