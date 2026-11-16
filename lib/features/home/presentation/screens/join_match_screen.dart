import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';
import 'package:turf_app/features/home/data/match_repository.dart';

class JoinMatchScreen extends ConsumerStatefulWidget {
  const JoinMatchScreen({super.key});

  @override
  ConsumerState<JoinMatchScreen> createState() => _JoinMatchScreenState();
}

class _JoinMatchScreenState extends ConsumerState<JoinMatchScreen> {
  String _selectedSport = 'All';

  final List<String> _sportsFilter = ['All', 'Football', 'Cricket', 'Badminton', 'Basketball', 'Tennis'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
    });
  }

  void _loadMatches() {
    final dio = ref.read(dioClientProvider);
    final user = ref.read(currentUserProvider);
    MatchRepository.instance.fetchMatches(dio: dio, currentUserId: user?.id);
  }

  @override
  Widget build(BuildContext context) {
    final repo = MatchRepository.instance;
    final user = ref.watch(currentUserProvider);
    final userId = user?.id;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final all = repo.allMatches;
        final scheduledMatches = all.where((m) => m['status'] != 'completed' && m['status'] != 'cancelled').toList();

        final filtered = _selectedSport == 'All'
            ? scheduledMatches
            : scheduledMatches.where((m) => m['sport']?.toString().toLowerCase() == _selectedSport.toLowerCase()).toList();

        return Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          appBar: AppBar(
            backgroundColor: const Color(0xFF0E1711),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join Open Matches',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Explore scheduled matches • Pick your team & play',
                  style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF8E9E94)),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
                tooltip: 'Refresh',
                onPressed: _loadMatches,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // 1. Sport Filter Chips
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _sportsFilter.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final sport = _sportsFilter[index];
                      final isSelected = _selectedSport == sport;
                      final count = sport == 'All'
                          ? scheduledMatches.length
                          : scheduledMatches.where((m) => m['sport']?.toString().toLowerCase() == sport.toLowerCase()).length;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedSport = sport),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryGreen : const Color(0xFF101912),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1B2C20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                sport,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.black : const Color(0xFFCFDBD2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF1C2D22),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.black : AppTheme.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // 2. Matches List
                Expanded(
                  child: repo.isLoading && scheduledMatches.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                      : RefreshIndicator(
                          color: AppTheme.primaryGreen,
                          backgroundColor: const Color(0xFF101912),
                          onRefresh: () async => _loadMatches(),
                          child: filtered.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.sports_soccer_outlined, color: Colors.white24, size: 56),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No open matches in $_selectedSport',
                                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Be the first to create and host a match in this category!',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 12),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await context.push('/create-match');
                                            _loadMatches();
                                          },
                                          icon: const Icon(Icons.add, color: Colors.black, size: 18),
                                          label: Text('Host Match Now', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final match = filtered[index];
                                    return _buildMatchCard(context, match, userId);
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchCard(BuildContext context, Map<String, dynamic> match, int? currentUserId) {
    final maxPlayers = (match['maxPlayers'] as num? ?? 10).toInt();
    final currentPlayers = (match['currentPlayers'] as num? ?? 1).toInt();
    final spotsLeft = (maxPlayers - currentPlayers).clamp(0, maxPlayers);
    final isFull = spotsLeft == 0;
    final hasJoined = match['hasJoined'] == true;
    final isCreator = match['isCreator'] == true;
    final fee = (match['pricePerPlayer'] as num? ?? 0).toDouble();

    final progress = (currentPlayers / maxPlayers).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasJoined ? AppTheme.primaryGreen.withValues(alpha: 0.6) : AppTheme.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Sport Chip + Spots Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${match['sport']} • ${match['format']}',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFull ? Colors.redAccent.withValues(alpha: 0.15) : const Color(0xFFFF9800).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isFull ? 'MATCH FULL' : '$spotsLeft SPOTS LEFT',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isFull ? Colors.redAccent : const Color(0xFFFFB74D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Teams Matchup Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Text(
                  match['teamA']?.toString() ?? 'Team Alpha',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2E20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'VS',
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ),
              Expanded(
                child: Text(
                  match['teamB']?.toString() ?? 'Team Beta',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Capacity Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$currentPlayers/$maxPlayers Players Joined',
                style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF8E9E94)),
              ),
              Text(
                fee > 0 ? '₹${fee.toInt()} / player' : 'FREE ENTRY',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: fee > 0 ? const Color(0xFF00E5FF) : AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFF1E2E22),
              valueColor: AlwaysStoppedAnimation<Color>(isFull ? Colors.redAccent : AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(height: 12),

          const Divider(color: Color(0xFF1E3224), height: 1),
          const SizedBox(height: 12),

          // Venue & Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match['turfName']?.toString() ?? 'Play Arena',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${match['date']} • ${match['location']}',
                      style: GoogleFonts.poppins(fontSize: 10.5, color: AppTheme.textGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              if (hasJoined)
                ElevatedButton.icon(
                  onPressed: () => context.push('/match-details/${match['backendId']}'),
                  icon: const Icon(Icons.check, size: 14, color: Colors.black),
                  label: Text('Joined', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )
              else if (isFull)
                OutlinedButton(
                  onPressed: () => context.push('/match-details/${match['backendId']}'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF263D2D)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: Text('Full • View', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60)),
                )
              else
                ElevatedButton(
                  onPressed: () => _showJoinDialog(match),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Join Match',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(Map<String, dynamic> match) {
    String chosenTeam = 'A';
    final roleController = TextEditingController(text: 'Player');
    final jerseyController = TextEditingController(text: '7');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final teamAName = match['teamA']?.toString() ?? 'Team Alpha';
          final teamBName = match['teamB']?.toString() ?? 'Team Beta';

          return AlertDialog(
            backgroundColor: const Color(0xFF101912),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1E3224))),
            title: Text(
              'Join Match Roster',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose Your Team', style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 11)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Text(teamAName, maxLines: 1, overflow: TextOverflow.ellipsis),
                          selected: chosenTeam == 'A',
                          selectedColor: AppTheme.primaryGreen,
                          onSelected: (v) => setDialogState(() => chosenTeam = 'A'),
                          labelStyle: GoogleFonts.poppins(
                            color: chosenTeam == 'A' ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: Text(teamBName, maxLines: 1, overflow: TextOverflow.ellipsis),
                          selected: chosenTeam == 'B',
                          selectedColor: const Color(0xFF00E5FF),
                          onSelected: (v) => setDialogState(() => chosenTeam = 'B'),
                          labelStyle: GoogleFonts.poppins(
                            color: chosenTeam == 'B' ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Position / Role', style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 11)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: roleController,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.cardDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      hintText: 'e.g. Striker, Midfielder, Batsman',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Jersey Number (Optional)', style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 11)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: jerseyController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.cardDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      hintText: 'e.g. 10',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white60)),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        try {
                          final dio = ref.read(dioClientProvider);
                          final user = ref.read(currentUserProvider);

                          await MatchRepository.instance.joinMatch(
                            match['backendId'],
                            dio: dio,
                            team: chosenTeam,
                            playerName: user?.fullName ?? user?.name ?? 'Player',
                            playerRole: roleController.text.trim(),
                            jerseyNumber: jerseyController.text.trim(),
                            currentUserId: user?.id,
                          );

                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Successfully joined $chosenTeam (${chosenTeam == 'A' ? teamAName : teamBName})!'),
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                            );
                            _loadMatches();
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to join: $e'), backgroundColor: Colors.redAccent),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text('Confirm & Join', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
}
