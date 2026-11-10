import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class Onboarding3Screen extends StatelessWidget {
  const Onboarding3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Title
              Text(
                'Compete, Track\n& Improve',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textWhite,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              Text(
                'Track your performance, climb the leaderboard and become the champion.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Stats & Leaderboard Showcase Card (Fills remaining height)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Player Performance Rating',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.surfaceDark,
                            border: Border.all(color: AppTheme.primaryGreen, width: 3),
                          ),
                          child: Text(
                            '8.6',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatMiniItem(label: 'Matches', val: '24'),
                            _StatMiniItem(label: 'Goals', val: '18'),
                            _StatMiniItem(label: 'Assists', val: '12'),
                          ],
                        ),
                        const Divider(color: AppTheme.cardBorder, height: 28),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Community Leaderboard',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _LeaderboardRow(rank: '1', name: 'John Doe', score: '1,250 pts'),
                        const _LeaderboardRow(rank: '2', name: 'Alex Morgan', score: '1,100 pts'),
                        const _LeaderboardRow(rank: '3', name: 'You (Rank #3)', score: '990 pts', isUser: true),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Navigation Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Skip on Left
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.go('/login'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textGrey,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  // 3 Dots in Center
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBorder,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 24,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),

                  // Get Started on Right
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatMiniItem extends StatelessWidget {
  final String label;
  final String val;
  const _StatMiniItem({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        Text(label, style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 11)),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final String rank;
  final String name;
  final String score;
  final bool isUser;
  const _LeaderboardRow({required this.rank, required this.name, required this.score, this.isUser = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUser ? AppTheme.primaryGreen.withValues(alpha: 0.15) : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: isUser ? Border.all(color: AppTheme.primaryGreen) : null,
      ),
      child: Row(
        children: [
          Text(rank, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isUser ? AppTheme.primaryGreen : Colors.white, fontSize: 12)),
          const SizedBox(width: 12),
          Text(name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
          const Spacer(),
          Text(score, style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
