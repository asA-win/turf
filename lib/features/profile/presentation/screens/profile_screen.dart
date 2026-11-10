import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/widgets/bys_bottom_nav_bar.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(fetchUserProfileProvider);
    final user = userAsync.valueOrNull;
    final userName = (user?.fullName != null && user!.fullName!.trim().isNotEmpty)
        ? user.fullName!.trim()
        : 'John Doe';
    final userRole = (user?.role != null && user!.role!.trim().isNotEmpty)
        ? user.role!.trim()
        : 'Striker • Jersey #7';

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textWhite),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          'Player Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textWhite),
            onPressed: () => context.push('/edit-profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // User Card Header: Profile Pic on one side, Top-Up & AI Rating on the other side
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left Side: Player Profile Picture & Identity
                    Expanded(
                      flex: 42,
                      child: GestureDetector(
                        onTap: () => context.push('/edit-profile'),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.primaryGreen, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFF152219),
                                        alignment: Alignment.center,
                                        child: Text(
                                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                          style: GoogleFonts.poppins(
                                            color: AppTheme.primaryGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 32,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Lvl 18',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              userName,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textWhite,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userRole,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppTheme.textGrey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Right Side: Top-Up Balance & AI Rating
                    Expanded(
                      flex: 58,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top-Up Balance Card
                          GestureDetector(
                            onTap: () => context.push('/wallet'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF132A1C), Color(0xFF0D1B12)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.35)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_wallet_rounded,
                                          color: AppTheme.primaryGreen,
                                          size: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Balance',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          color: AppTheme.textGrey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.add, color: Colors.black, size: 10),
                                            const SizedBox(width: 2),
                                            Text(
                                              'Top-Up',
                                              style: GoogleFonts.poppins(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '₹2,450.00',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // AI Rating Card
                          GestureDetector(
                            onTap: () => context.push('/ai-player-rating'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111E15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.35)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome,
                                          color: AppTheme.primaryGreen,
                                          size: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'AI Rating',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          color: AppTheme.textGrey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        color: AppTheme.primaryGreen,
                                        size: 10,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '8.6',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryGreen,
                                        ),
                                      ),
                                      Text(
                                        ' / 10',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10.5,
                                          color: AppTheme.textGrey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Radar Skills',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Profile Links List (My Matches & Career at top)
              _linkTile(
                Icons.sports_soccer_rounded,
                'My Matches',
                '/my-matches',
                iconColor: AppTheme.primaryGreen,
                subtitle: 'Upcoming bookings & live scoreboards',
                badge: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF6961),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _linkTile(
                Icons.emoji_events_outlined,
                'Career',
                '/career',
                iconColor: Colors.amber,
                subtitle: 'Personal records, milestones & stats',
                badge: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '48 Matches',
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              _linkTile(Icons.groups_outlined, 'My Team Squad', '/team-management'),
              _linkTile(
                Icons.account_balance_wallet_outlined,
                'My Wallet & Rewards',
                '/wallet',
                badge: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '₹2,450.00',
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              _linkTile(Icons.card_giftcard_outlined, 'Referral & Earn', '/referral'),
              _linkTile(Icons.history, 'Booking History', '/my-bookings'),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: ListTile(
                  onTap: () => context.go('/login'),
                  leading: const Icon(Icons.logout, color: AppTheme.errorRed),
                  title: Text(
                    'Logout',
                    style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.errorRed, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BysBottomNavBar(currentIndex: -1),
    );
  }

  Widget _linkTile(
    IconData icon,
    String title,
    String route, {
    Color? iconColor,
    String? subtitle,
    Widget? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: ListTile(
        onTap: () => context.push(route),
        leading: Icon(icon, color: iconColor ?? AppTheme.primaryGreen),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textWhite, fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null) badge,
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppTheme.textGrey),
          ],
        ),
      ),
    );
  }
}
