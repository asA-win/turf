import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';
import 'package:turf_app/features/home/data/match_repository.dart';

class MatchDetailsScreen extends ConsumerStatefulWidget {
  final String matchId;
  const MatchDetailsScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends ConsumerState<MatchDetailsScreen> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetails();
    });
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider);
      final user = ref.read(currentUserProvider);
      await MatchRepository.instance.fetchMatchDetails(widget.matchId, dio: dio, currentUserId: user?.id);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = MatchRepository.instance;
    final user = ref.watch(currentUserProvider);
    final userId = user?.id;
    final match = repo.getMatchById(widget.matchId);

    if (_isLoading && match == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF070B08),
        appBar: AppBar(backgroundColor: const Color(0xFF0E1711), elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    if (match == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF070B08),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0E1711),
          title: Text('Match Details', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text('Match not found or deleted', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                child: const Text('Back to Matches'),
              ),
            ],
          ),
        ),
      );
    }

    final isCreator = match['isCreator'] == true;
    final hasJoined = match['hasJoined'] == true;
    final userTeam = match['userTeam']?.toString();
    final isCompleted = match['isCompleted'] == true;
    final isLive = match['isLive'] == true;

    final teamA = match['teamA']?.toString() ?? 'Team Alpha';
    final teamB = match['teamB']?.toString() ?? 'Team Beta';
    final scoreA = match['scoreA']?.toString() ?? '0';
    final scoreB = match['scoreB']?.toString() ?? '0';
    final venue = match['turfName']?.toString() ?? 'Play Arena';
    final location = match['location']?.toString() ?? 'Sarjapur, Bangalore';
    final sport = match['sport']?.toString() ?? 'Football';
    final format = match['format']?.toString() ?? '5v5';
    final fee = (match['pricePerPlayer'] as num? ?? 0).toDouble();
    final maxPlayers = (match['maxPlayers'] as num? ?? 10).toInt();
    final participants = (match['participants'] as List? ?? []).cast<Map<String, dynamic>>();

    final teamAPlayers = participants.where((p) => p['team'] == 'A').toList();
    final teamBPlayers = participants.where((p) => p['team'] == 'B').toList();

    final config = Map<String, dynamic>.from(match['scoreboardConfig'] as Map? ?? {});
    config['id'] = match['backendId'];
    config['backendId'] = match['backendId'];
    config['isCreator'] = isCreator;
    config['isViewOnly'] = !isCreator;

    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1711),
        elevation: 0,
        title: Text(
          match['title']?.toString() ?? 'Match Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppTheme.primaryGreen),
            tooltip: 'Match Stats',
            onPressed: () => context.push('/stats', extra: match),
          ),
          if (isCreator)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              tooltip: 'Delete Match',
              onPressed: () => _confirmDelete(match['backendId']),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isLive
                      ? Colors.redAccent.withValues(alpha: 0.15)
                      : (isCompleted ? AppTheme.primaryGreen.withValues(alpha: 0.15) : const Color(0xFF16251B)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLive ? Colors.redAccent : (isCompleted ? AppTheme.primaryGreen : const Color(0xFF263D2D)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isLive ? Icons.radio_button_checked : (isCompleted ? Icons.check_circle : Icons.schedule),
                          size: 16,
                          color: isLive ? Colors.redAccent : (isCompleted ? AppTheme.primaryGreen : const Color(0xFF00E5FF)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isLive
                              ? 'MATCH IN PROGRESS (LIVE)'
                              : (isCompleted ? 'MATCH COMPLETED' : 'UPCOMING MATCH'),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isLive ? Colors.redAccent : (isCompleted ? AppTheme.primaryGreen : const Color(0xFF00E5FF)),
                          ),
                        ),
                      ],
                    ),
                    if (isCreator)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'HOST',
                          style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      )
                    else if (hasJoined)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'TEAM $userTeam',
                          style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Match Scoreboard Header Box
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF101912),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF1E3224)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(teamA, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(
                                isLive || isCompleted ? scoreA : '-',
                                style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF1E2F22), borderRadius: BorderRadius.circular(8)),
                          child: Text('VS', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 12)),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(teamB, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white70)),
                              const SizedBox(height: 4),
                              Text(
                                isLive || isCompleted ? scoreB : '-',
                                style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFF1E3224)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _infoSnippet(Icons.sports, sport),
                        _infoSnippet(Icons.group_outlined, format),
                        _infoSnippet(Icons.calendar_today, match['date']?.toString() ?? 'Today'),
                        _infoSnippet(Icons.currency_rupee, fee > 0 ? '₹${fee.toInt()}' : 'Free'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Venue Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF101912),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1B2C20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.stadium_outlined, color: AppTheme.primaryGreen, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(venue, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                          Text(location, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Rosters Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Match Squad Rosters', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                  Text(
                    '${participants.length}/$maxPlayers Joined',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Team A Roster
              _buildRosterSection(teamA, 'A', teamAPlayers, AppTheme.primaryGreen),
              const SizedBox(height: 14),

              // Team B Roster
              _buildRosterSection(teamB, 'B', teamBPlayers, const Color(0xFF00E5FF)),
              const SizedBox(height: 24),

              // Primary Actions
              if (isCreator) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/scoreboard', extra: config);
                    },
                    icon: const Icon(Icons.edit_note_rounded, color: Colors.black, size: 20),
                    label: Text(
                      'Manage Scoreboard & Events',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ] else if (hasJoined) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push('/scoreboard', extra: config);
                        },
                        icon: const Icon(Icons.visibility_rounded, color: Colors.black, size: 18),
                        label: Text(
                          'View Live Scoreboard',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        onPressed: () => _leaveMatch(match['backendId']),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Leave Match',
                          style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: participants.length >= maxPlayers ? null : () => _showJoinDialog(match),
                    icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.black, size: 18),
                    label: Text(
                      participants.length >= maxPlayers ? 'Match Roster Full' : 'Join Match Roster',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // View Stats Button
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/stats', extra: match),
                  icon: const Icon(Icons.analytics_outlined, color: Colors.white, size: 18),
                  label: Text('Full Match Analytics & Events', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E3224)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoSnippet(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 16),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(color: const Color(0xFFCFDBD2), fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildRosterSection(String teamName, String teamCode, List<Map<String, dynamic>> players, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1B2C20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$teamName (Team $teamCode)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: accentColor)),
              Text('${players.length} Players', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          if (players.isEmpty)
            Text('No players joined yet.', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11.5))
          else
            Column(
              children: players.map((p) {
                final role = p['playerRole']?.toString() ?? 'Player';
                final jersey = p['jerseyNumber']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: accentColor.withValues(alpha: 0.2),
                        child: Text(
                          jersey.isNotEmpty ? jersey : p['playerName']?[0]?.toUpperCase() ?? 'P',
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p['playerName']?.toString() ?? 'Player',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(role, style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF8E9E94))),
                    ],
                  ),
                );
              }).toList(),
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
                            _loadDetails();
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

  void _leaveMatch(dynamic matchId) async {
    try {
      final dio = ref.read(dioClientProvider);
      final user = ref.read(currentUserProvider);
      await MatchRepository.instance.leaveMatch(matchId, dio: dio, currentUserId: user?.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left match roster')),
        );
        _loadDetails();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _confirmDelete(dynamic matchId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101912),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Match', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete this match?', style: GoogleFonts.poppins(color: const Color(0xFFCFDBD2), fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white60))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final dio = ref.read(dioClientProvider);
                await MatchRepository.instance.deleteMatch(matchId, dio: dio);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Match deleted successfully')));
                  context.pop();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
