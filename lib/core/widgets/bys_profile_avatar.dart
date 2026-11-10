import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';

/// A reusable round profile avatar widget displayed in the top corner of the app,
/// just like leading modern apps (e.g. YouTube, Play Store, Twitter/X).
/// Tapping it navigates directly to the Player Profile screen (`/profile`).
class BysProfileAvatar extends ConsumerWidget {
  final double size;
  final VoidCallback? onTap;
  final bool showBadge;

  const BysProfileAvatar({
    super.key,
    this.size = 36,
    this.onTap,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? userName;
    try {
      final userAsync = ref.watch(fetchUserProfileProvider);
      userName = userAsync.valueOrNull?.fullName;
    } catch (_) {
      userName = null;
    }

    return GestureDetector(
      onTap: onTap ?? () => context.push('/profile'),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryGreen,
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF1A291E),
                  alignment: Alignment.center,
                  child: Text(
                    (userName != null && userName.isNotEmpty)
                        ? userName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: size * 0.45,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.backgroundBlack,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
