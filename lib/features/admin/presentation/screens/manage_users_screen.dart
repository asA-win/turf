import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/admin/presentation/controllers/user_management_controller.dart';
import 'package:turf_app/features/auth/domain/models/user_profile.dart';

class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> {
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  @override
  void initState() {
    super.initState();
    try {
      _wsSub = ref.read(realtimeServiceProvider).connectToChannel('booking_updates').listen((_) {
        if (mounted) {
          ref.invalidate(fetchAllUsersProvider);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(fetchAllUsersProvider);
    final controllerState = ref.watch(userManagementControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Manage Users', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryGreen, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'LIVE',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: usersAsync.when(
        data: (users) => Column(
          children: [
            if (controllerState is AsyncLoading)
              const LinearProgressIndicator(color: AppTheme.primaryGreen),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _userCard(context, user);
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _userCard(BuildContext context, UserProfile user) {
    final role = user.role ?? 'user';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(role).withValues(alpha: 0.1),
          child: Icon(Icons.person, color: _getRoleColor(role)),
        ),
        title: Text(user.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email ?? 'No email'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(role),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                role.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (newRole) async {
            await ref.read(userManagementControllerProvider.notifier).updateUserRole(user.id, newRole);
            try {
              ref.read(realtimeServiceProvider).emit('booking_updates', {
                'type': 'user_role_updated',
                'user_id': user.id,
                'role': newRole,
              });
            } catch (_) {}
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'user', child: Text('Make User')),
            const PopupMenuItem(value: 'owner', child: Text('Make Owner')),
            const PopupMenuItem(value: 'admin', child: Text('Make Admin')),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'owner':
        return Colors.blue;
      default:
        return AppTheme.primaryGreen;
    }
  }
}
