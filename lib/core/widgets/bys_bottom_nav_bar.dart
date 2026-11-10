import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class BysBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BysBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F0D),
        border: Border(
          top: BorderSide(
            color: AppTheme.cardBorder.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_filled,
              label: 'Home',
              route: '/home',
            ),
            _buildNavItem(
              context,
              index: 1,
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore_rounded,
              label: 'Discover',
              route: '/discover',
            ),
            _buildNavItem(
              context,
              index: 2,
              icon: Icons.emoji_events_outlined,
              activeIcon: Icons.emoji_events_rounded,
              label: 'Tournaments',
              route: '/tournaments',
            ),
            _buildNavItem(
              context,
              index: 3,
              icon: Icons.forum_outlined,
              activeIcon: Icons.forum_rounded,
              label: 'Community',
              route: '/community',
            ),
            _buildNavItem(
              context,
              index: 4,
              icon: Icons.storefront_outlined,
              activeIcon: Icons.storefront_rounded,
              label: 'Stores',
              route: '/store',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    IconData? activeIcon,
    required String label,
    required String route,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppTheme.primaryGreen : const Color(0xFF88978D);

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          context.go(route);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected && activeIcon != null ? activeIcon : icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
