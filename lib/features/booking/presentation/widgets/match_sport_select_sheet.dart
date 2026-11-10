import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/booking/domain/models/booking.dart';

class MatchSportSelectSheet extends StatefulWidget {
  final Booking? booking;
  final String? turfName;
  final String? bookingId;

  const MatchSportSelectSheet({
    super.key,
    this.booking,
    this.turfName,
    this.bookingId,
  });

  static Future<void> show(
    BuildContext context, {
    Booking? booking,
    String? turfName,
    String? bookingId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MatchSportSelectSheet(
        booking: booking,
        turfName: turfName ?? booking?.turf?.name ?? 'Turf Match',
        bookingId: bookingId ?? booking?.id.toString() ?? '1',
      ),
    );
  }

  @override
  State<MatchSportSelectSheet> createState() => _MatchSportSelectSheetState();
}

class _MatchSportSelectSheetState extends State<MatchSportSelectSheet> {
  String _selectedSport = 'football';
  late final TextEditingController _teamAController;
  late final TextEditingController _teamBController;

  // Settings
  int _cricketOvers = 8;
  int _footballHalfMinutes = 20;
  int _badmintonPoints = 21;
  final int _basketballQuarterMinutes = 10;

  final List<Map<String, dynamic>> _sports = [
    {
      'id': 'football',
      'name': 'Football',
      'icon': Icons.sports_soccer,
      'color': Color(0xFF00E676),
      'subtitle': 'Goals, Clock, Cards & Fouls',
    },
    {
      'id': 'cricket',
      'name': 'Box Cricket',
      'icon': Icons.sports_cricket,
      'color': Color(0xFFFFA000),
      'subtitle': 'Runs, Overs, Wickets & Ball by Ball',
    },
    {
      'id': 'badminton',
      'name': 'Badminton',
      'icon': Icons.sports_tennis,
      'color': Color(0xFF29B6F6),
      'subtitle': 'Sets, Rally Points & Service tracker',
    },
    {
      'id': 'basketball',
      'name': 'Basketball',
      'icon': Icons.sports_basketball,
      'color': Color(0xFFFF7043),
      'subtitle': 'Quarters, 1pt / 2pt / 3pt Points',
    },
    {
      'id': 'tennis',
      'name': 'Tennis / Pickleball',
      'icon': Icons.sports_handball,
      'color': Color(0xFFAB47BC),
      'subtitle': 'Sets, Games & Rally points',
    },
  ];

  @override
  void initState() {
    super.initState();
    _teamAController = TextEditingController(text: 'Team Alpha');
    _teamBController = TextEditingController(text: 'Team Beta');

    // Auto-detect sport if available in turf sportTypes
    final sportTypes = widget.booking?.turf?.sportTypes?.toLowerCase() ?? '';
    if (sportTypes.contains('cricket')) {
      _selectedSport = 'cricket';
    } else if (sportTypes.contains('badminton')) {
      _selectedSport = 'badminton';
    } else if (sportTypes.contains('basketball')) {
      _selectedSport = 'basketball';
    } else if (sportTypes.contains('tennis')) {
      _selectedSport = 'tennis';
    }
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  void _startMatch() {
    Navigator.pop(context);

    final config = <String, dynamic>{
      'sport': _selectedSport,
      'turfName': widget.turfName ?? 'Turf Match',
      'bookingId': widget.bookingId ?? '1',
      'teamA': _teamAController.text.trim().isEmpty ? 'Team A' : _teamAController.text.trim(),
      'teamB': _teamBController.text.trim().isEmpty ? 'Team B' : _teamBController.text.trim(),
      'cricketOvers': _cricketOvers,
      'footballHalfMinutes': _footballHalfMinutes,
      'badmintonPoints': _badmintonPoints,
      'basketballQuarterMinutes': _basketballQuarterMinutes,
    };

    context.push('/scoreboard', extra: config);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: bottomInset + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.cardBorder, width: 1.5),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.scoreboard_rounded, color: AppTheme.primaryGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Match Scoreboard',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      Text(
                        widget.turfName ?? 'Select game & teams to start',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sport Selection Header
            Text(
              '1. WHICH SPORT ARE YOU PLAYING?',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),

            // Sports List
            ..._sports.map((sport) {
              final isSelected = _selectedSport == sport['id'];
              final color = sport['color'] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.12) : AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : AppTheme.cardBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  onTap: () => setState(() => _selectedSport = sport['id']),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(sport['icon'] as IconData, color: color, size: 20),
                  ),
                  title: Text(
                    sport['name'] as String,
                    style: GoogleFonts.poppins(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppTheme.textWhite : AppTheme.textGrey,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    sport['subtitle'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : AppTheme.textMuted,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: color, size: 22)
                      : const Icon(Icons.circle_outlined, color: Colors.white24, size: 22),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Team Names Section
            Text(
              '2. TEAMS / PLAYERS',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Team 1', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _teamAController,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Team A',
                          hintStyle: GoogleFonts.poppins(color: Colors.white38),
                          filled: true,
                          fillColor: AppTheme.cardDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.primaryGreen),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.only(top: 18),
                  child: Text(
                    'VS',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Team 2', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _teamBController,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Team B',
                          hintStyle: GoogleFonts.poppins(color: Colors.white38),
                          filled: true,
                          fillColor: AppTheme.cardDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.primaryGreen),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Sport-specific quick format selector
            if (_selectedSport == 'cricket') ...[
              Text(
                '3. MATCH OVERS',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [4, 6, 8, 10, 12, 15, 20].map((overs) {
                    final isSel = _cricketOvers == overs;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$overs Overs'),
                        selected: isSel,
                        onSelected: (selected) {
                          if (selected) setState(() => _cricketOvers = overs);
                        },
                        selectedColor: AppTheme.primaryGreen,
                        backgroundColor: AppTheme.cardDark,
                        labelStyle: GoogleFonts.poppins(
                          color: isSel ? Colors.black : Colors.white,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: isSel ? AppTheme.primaryGreen : AppTheme.cardBorder,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else if (_selectedSport == 'football') ...[
              Text(
                '3. HALF DURATION',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [15, 20, 25, 30, 45].map((mins) {
                    final isSel = _footballHalfMinutes == mins;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$mins Mins / Half'),
                        selected: isSel,
                        onSelected: (selected) {
                          if (selected) setState(() => _footballHalfMinutes = mins);
                        },
                        selectedColor: AppTheme.primaryGreen,
                        backgroundColor: AppTheme.cardDark,
                        labelStyle: GoogleFonts.poppins(
                          color: isSel ? Colors.black : Colors.white,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: isSel ? AppTheme.primaryGreen : AppTheme.cardBorder,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else if (_selectedSport == 'badminton') ...[
              Text(
                '3. POINTS PER SET',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [15, 21, 30].map((pts) {
                  final isSel = _badmintonPoints == pts;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$pts Points'),
                      selected: isSel,
                      onSelected: (selected) {
                        if (selected) setState(() => _badmintonPoints = pts);
                      },
                      selectedColor: AppTheme.primaryGreen,
                      backgroundColor: AppTheme.cardDark,
                      labelStyle: GoogleFonts.poppins(
                        color: isSel ? Colors.black : Colors.white,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSel ? AppTheme.primaryGreen : AppTheme.cardBorder,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // Start Live Match Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _startMatch,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                label: Text(
                  'Start Live Scoreboard',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
