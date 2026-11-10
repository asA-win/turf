import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/admin/presentation/controllers/user_management_controller.dart';
import 'package:turf_app/features/auth/domain/models/user_profile.dart';

class ManageUsersScreen extends ConsumerWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(fetchAllUsersProvider);
    final controllerState = ref.watch(userManagementControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
                  return _userCard(context, ref, user);
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

  Widget _userCard(BuildContext context, WidgetRef ref, UserProfile user) {
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
          onSelected: (newRole) {
            ref.read(userManagementControllerProvider.notifier).updateUserRole(user.id, newRole);
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
