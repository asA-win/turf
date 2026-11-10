import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';

class AvailableSportsScreen extends ConsumerStatefulWidget {
  final String turfId;
  const AvailableSportsScreen({super.key, required this.turfId});

  @override
  ConsumerState<AvailableSportsScreen> createState() => _AvailableSportsScreenState();
}

class _AvailableSportsScreenState extends ConsumerState<AvailableSportsScreen> {
  String? _selectedSport;

  IconData _iconForSport(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cricket')) return Icons.sports_cricket;
    if (lower.contains('badminton')) return Icons.sports_tennis;
    if (lower.contains('tennis')) return Icons.sports_tennis_outlined;
    if (lower.contains('basketball')) return Icons.sports_basketball;
    if (lower.contains('volleyball')) return Icons.sports_volleyball;
    return Icons.sports_soccer;
  }

  @override
  Widget build(BuildContext context) {
    final numericTurfId = int.tryParse(widget.turfId) ?? 1;
    final turfAsync = ref.watch(fetchTurfByIdProvider(numericTurfId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Available Sports'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: turfAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          error: (err, stack) => Center(
            child: Text('Failed to load sports: $err', style: GoogleFonts.poppins(color: AppTheme.textGrey)),
          ),
          data: (turf) {
            final List<String> sportsList = (turf.sportTypes != null && turf.sportTypes!.trim().isNotEmpty)
                ? turf.sportTypes!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                : ['Football', 'Cricket', 'Badminton'];

            _selectedSport ??= sportsList.first;

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: sportsList.length,
                    itemBuilder: (context, index) {
                      final sportName = sportsList[index];
                      final isSelected = sportName == _selectedSport;
                      final icon = _iconForSport(sportName);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder,
                          ),
                        ),
                        child: ListTile(
                          onTap: () => setState(() => _selectedSport = sportName),
                          leading: Icon(icon, color: AppTheme.primaryGreen),
                          title: Text(sportName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('Full Pitch Available', style: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 12)),
                          trailing: Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_off,
                            color: isSelected ? AppTheme.primaryGreen : AppTheme.textMuted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.push('/slot-selection/${widget.turfId}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('View Slots for $_selectedSport', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
