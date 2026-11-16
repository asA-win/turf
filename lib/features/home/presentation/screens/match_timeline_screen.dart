import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/home/data/match_repository.dart';

class MatchTimelineScreen extends StatefulWidget {
  final String matchId;
  const MatchTimelineScreen({super.key, required this.matchId});

  @override
  State<MatchTimelineScreen> createState() => _MatchTimelineScreenState();
}

class _MatchTimelineScreenState extends State<MatchTimelineScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _match;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final details = await MatchRepository.instance.fetchMatchDetails(widget.matchId);
      if (mounted) {
        final rawEvents = details?['timeline_events'] ?? [];
        List<Map<String, dynamic>> parsedEvents = [];
        if (rawEvents is List) {
          for (final ev in rawEvents) {
            if (ev is Map) {
              parsedEvents.add(Map<String, dynamic>.from(ev));
            }
          }
        }
        setState(() {
          _match = details;
          _events = parsedEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load match timeline';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleA = _match?['team_a_name'] ?? 'Team A';
    final titleB = _match?['team_b_name'] ?? 'Team B';

    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1711),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Match Timeline',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
            ),
            if (_match != null)
              Text(
                '$titleA vs $titleB',
                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: GoogleFonts.poppins(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadTimeline,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('Retry', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }

    if (_events.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTimeline,
        color: AppTheme.primaryGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1F2F23)),
                    ),
                    child: const Icon(Icons.timeline_rounded, color: AppTheme.primaryGreen, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Timeline Events Yet',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Events such as goals, points, fouls, substitutions, and cards will appear here as the match progresses.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textGrey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTimeline,
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final ev = _events[index];
          final min = ev['min']?.toString() ?? ev['minute']?.toString() ?? "--'";
          final eventText = ev['event']?.toString() ?? ev['description']?.toString() ?? 'Event';
          final player = ev['player']?.toString() ?? ev['player_name']?.toString() ?? '';
          final type = ev['type']?.toString() ?? 'event';

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                child: Text(
                  min,
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
                  ),
                  if (index < _events.length - 1)
                    Container(width: 2, height: 50, color: AppTheme.cardBorder),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      _iconForType(type),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eventText,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (player.isNotEmpty)
                              Text(
                                player,
                                style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'goal':
        return const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen, size: 20);
      case 'card':
      case 'yellow_card':
        return const Icon(Icons.square, color: Colors.amber, size: 18);
      case 'red_card':
        return const Icon(Icons.square, color: Colors.redAccent, size: 18);
      case 'sub':
      case 'substitution':
        return const Icon(Icons.swap_horiz, color: Colors.blue, size: 20);
      case 'wicket':
        return const Icon(Icons.sports_cricket, color: Colors.orange, size: 20);
      default:
        return const Icon(Icons.play_circle_outline, color: AppTheme.textGrey, size: 20);
    }
  }
}
