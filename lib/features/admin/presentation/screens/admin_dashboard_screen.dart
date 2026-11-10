import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/domain/models/turf.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';
import 'package:turf_app/core/providers/api_client.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turfsAsync = ref.watch(fetchTurfsProvider(null, null));
    final statsAsync = ref.watch(fetchTurfStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Live Booking Requests',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_active_outlined),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => context.push('/live-booking-requests'),
          ),
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            statsAsync.when(
              data: (stats) => _buildStatGrid(context, stats),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading stats: $err'),
            ),
            const SizedBox(height: 32),
            Text('Manage Turfs', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            turfsAsync.when(
              data: (turfs) => _buildTurfList(context, ref, turfs),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-turf'),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Turf', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _statCard('Total Turfs', '${stats['active_turfs']}', Icons.sports_soccer, Colors.blue),
        _statCard('Total Bookings', '${stats['total_bookings']}', Icons.calendar_today, Colors.orange),
        _statCard('Revenue', 'Rs. ${stats['total_revenue']}', Icons.payments, Colors.green),
        _statCard(
          'Active Users', 
          'Manage', 
          Icons.people, 
          Colors.purple,
          onTap: () => context.push('/admin/users'),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color),
                if (onTap != null) const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurfList(BuildContext context, WidgetRef ref, List<Turf> turfs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: turfs.length,
      itemBuilder: (context, index) {
        final turf = turfs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              child: Icon(Icons.sports_soccer, color: Colors.white),
            ),
            title: Text(turf.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(turf.location),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    context.push('/add-turf', extra: turf);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Turf?'),
                        content: const Text('Are you sure you want to delete this turf?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      try {
                        await ref.read(dioClientProvider).delete('/turfs/${turf.id}');
                        ref.invalidate(fetchTurfsProvider(null, null));
                        ref.invalidate(fetchTurfStatsProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
