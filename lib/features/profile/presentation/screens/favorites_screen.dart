import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/favorite_repository.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(fetchMyFavoritesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text('My Favorites', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: favoritesAsync.when(
        data: (favorites) => favorites.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('No favorites yet', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 18)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final turf = favorites[index].turf;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 60,
                          height: 60,
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen),
                        ),
                      ),
                      title: Text(turf.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(turf.location),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () async {
                          await ref.read(favoriteRepositoryProvider).toggleFavorite(turf.id);
                          ref.invalidate(fetchMyFavoritesProvider);
                        },
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
