import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/home/data/match_repository.dart';

class ShareMatchScreen extends StatefulWidget {
  final String matchId;
  const ShareMatchScreen({super.key, required this.matchId});

  @override
  State<ShareMatchScreen> createState() => _ShareMatchScreenState();
}

class _ShareMatchScreenState extends State<ShareMatchScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _match;

  @override
  void initState() {
    super.initState();
    _loadMatch();
  }

  Future<void> _loadMatch() async {
    try {
      final data = await MatchRepository.instance.fetchMatchDetails(widget.matchId);
      if (mounted) {
        setState(() {
          _match = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _shareDetails(String platform) {
    final teamA = _match?['team_a_name'] ?? 'Team A';
    final teamB = _match?['team_b_name'] ?? 'Team B';
    final scoreA = _match?['team_a_score'] ?? 0;
    final scoreB = _match?['team_b_score'] ?? 0;
    final venue = _match?['venue_name'] ?? 'Turf Arena';
    final date = _match?['match_date'] ?? '';

    final shareText = '🏆 $teamA $scoreA - $scoreB $teamB\n📍 $venue ${date.isNotEmpty ? "• $date" : ""}\nTrack live on Turf App!';
    Clipboard.setData(ClipboardData(text: shareText));
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Match details copied to clipboard for $platform!',
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF1E2C22),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamA = _match?['team_a_name'] ?? 'Team A';
    final teamB = _match?['team_b_name'] ?? 'Team B';
    final scoreA = _match?['team_a_score'] ?? 0;
    final scoreB = _match?['team_b_score'] ?? 0;
    final venue = _match?['venue_name'] ?? _match?['location'] ?? 'Turf Arena';
    final date = _match?['match_date'] ?? '';
    final sport = _match?['sport_type'] ?? 'Match';

    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1711),
        elevation: 0,
        title: Text(
          'Share Match',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Match Summary 🏅',
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$teamA $scoreA - $scoreB $teamB',
                      style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      '${date.isNotEmpty ? "$date • " : ""}$venue ($sport)',
                      style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppTheme.surfaceDark,
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sports_score_rounded, color: AppTheme.primaryGreen, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            '$teamA vs $teamB',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'Final: $scoreA - $scoreB',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _btn('WhatsApp', Icons.chat_rounded, Colors.green, () => _shareDetails('WhatsApp')),
                        _btn('Instagram', Icons.camera_alt_rounded, Colors.purple, () => _shareDetails('Instagram')),
                        _btn('Copy Link', Icons.link_rounded, AppTheme.primaryGreen, () => _shareDetails('Copy Link')),
                        _btn('More', Icons.share_rounded, Colors.white, () => _shareDetails('Share')),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => _shareDetails('Clipboard'),
                      icon: const Icon(Icons.copy_rounded, color: Colors.black, size: 18),
                      label: const Text('Copy Match Result', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _btn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.surfaceDark,
              radius: 24,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
