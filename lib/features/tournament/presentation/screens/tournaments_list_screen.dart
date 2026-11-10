import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/widgets/bys_bottom_nav_bar.dart';
import 'package:turf_app/core/widgets/bys_profile_avatar.dart';
import 'package:turf_app/features/tournament/data/tournament_repository.dart';

class TournamentsListScreen extends ConsumerStatefulWidget {
  const TournamentsListScreen({super.key});

  @override
  ConsumerState<TournamentsListScreen> createState() => _TournamentsListScreenState();
}

class _TournamentsListScreenState extends ConsumerState<TournamentsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Location / Area State
  String _userCurrentArea = 'Koramangala';
  final List<String> _availableAreas = [
    'All Areas',
    'Koramangala',
    'HSR Layout',
    'Bellandur',
    'Indiranagar',
    'Sarjapur',
    'BTM Layout',
    'Electronic City',
    'Whitefield',
  ];

  // Primary Filters
  String _selectedSport = 'All';
  String _selectedStatus = 'All';
  String _selectedArea = 'All Areas';
  double _maxDistanceKm = 999.0;
  String _selectedEntryFeeFilter = 'All';
  String _selectedFormat = 'All';

  // Quick Filter Toggles
  bool _quickNearMe = false;
  bool _quickFreeEntry = false;
  bool _quickFastFilling = false;
  bool _quickLiveOnly = false;
  bool _quickWeekendOnly = false;
  bool _quickHighPrize = false;

  // Sorting
  String _sortBy = 'Distance: Nearest';

  final List<String> _sportsFilter = [
    'All',
    'Football',
    'Cricket',
    'Badminton',
    'Basketball',
    'Tennis',
  ];

  final List<String> _statusFilter = [
    'All',
    'Open Entry',
    'Ongoing (Live)',
    'Upcoming',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    TournamentRepository.instance.addListener(_onRepositoryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TournamentRepository.instance.syncWithBackend(ref.read(dioClientProvider));
    });
  }

  @override
  void dispose() {
    TournamentRepository.instance.removeListener(_onRepositoryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onRepositoryChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedSport != 'All') count++;
    if (_selectedStatus != 'All') count++;
    if (_selectedArea != 'All Areas') count++;
    if (_maxDistanceKm < 999.0) count++;
    if (_selectedEntryFeeFilter != 'All') count++;
    if (_selectedFormat != 'All') count++;
    if (_quickNearMe) count++;
    if (_quickFreeEntry) count++;
    if (_quickFastFilling) count++;
    if (_quickLiveOnly) count++;
    if (_quickWeekendOnly) count++;
    if (_quickHighPrize) count++;
    return count;
  }

  void _resetAllFilters() {
    setState(() {
      _selectedSport = 'All';
      _selectedStatus = 'All';
      _selectedArea = 'All Areas';
      _maxDistanceKm = 999.0;
      _selectedEntryFeeFilter = 'All';
      _selectedFormat = 'All';
      _quickNearMe = false;
      _quickFreeEntry = false;
      _quickFastFilling = false;
      _quickLiveOnly = false;
      _quickWeekendOnly = false;
      _quickHighPrize = false;
      _sortBy = 'Distance: Nearest';
      _searchController.clear();
    });
  }

  List<Map<String, dynamic>> _getFilteredTournaments() {
    final query = _searchController.text.trim().toLowerCase();
    final all = TournamentRepository.instance.tournaments.isNotEmpty
        ? TournamentRepository.instance.tournaments
        : TournamentRepository.initialTournaments;

    final filtered = all.where((t) {
      // 1. Sport
      if (_selectedSport != 'All' && t['sport'] != _selectedSport) return false;

      // 2. Status
      if (_selectedStatus != 'All' && t['status'] != _selectedStatus) return false;

      // 3. Area
      if (_selectedArea != 'All Areas' && t['area'] != _selectedArea) return false;

      // 4. Distance
      final dist = (t['distanceKm'] as num?)?.toDouble() ?? 5.0;
      if (_maxDistanceKm < 999.0 && dist > _maxDistanceKm) return false;
      if (_quickNearMe && dist > 5.0) return false;

      // 5. Entry Fee
      final fee = (t['entryFeeAmount'] as num?)?.toInt() ?? 0;
      if (_quickFreeEntry && fee > 0) return false;
      if (_selectedEntryFeeFilter == 'Free' && fee > 0) return false;
      if (_selectedEntryFeeFilter == 'Under 1500' && fee >= 1500) return false;
      if (_selectedEntryFeeFilter == '1500-3000' && (fee < 1500 || fee > 3000)) return false;
      if (_selectedEntryFeeFilter == 'Above 3000' && fee <= 3000) return false;

      // 6. Format
      if (_selectedFormat != 'All' &&
          !((t['format'] as String? ?? '').toLowerCase().contains(_selectedFormat.toLowerCase()))) {
        return false;
      }

      // 7. Quick Toggles
      if (_quickFastFilling && (t['isFillingFast'] != true)) return false;
      if (_quickLiveOnly && t['status'] != 'Ongoing (Live)') return false;
      if (_quickWeekendOnly && t['isWeekend'] != true) return false;
      if (_quickHighPrize && ((t['prizePoolAmount'] as num?)?.toInt() ?? 0) < 500000) return false;

      // 8. Text Search
      if (query.isNotEmpty) {
        final name = (t['name'] as String? ?? '').toLowerCase();
        final venue = (t['venue'] as String? ?? '').toLowerCase();
        final area = (t['area'] as String? ?? '').toLowerCase();
        final sport = (t['sport'] as String? ?? '').toLowerCase();
        final organizer = (t['organizer'] as String? ?? '').toLowerCase();
        final format = (t['format'] as String? ?? '').toLowerCase();

        final match = name.contains(query) ||
            venue.contains(query) ||
            area.contains(query) ||
            sport.contains(query) ||
            organizer.contains(query) ||
            format.contains(query);
        if (!match) return false;
      }

      return true;
    }).toList();

    // Sorting
    filtered.sort((a, b) {
      if (_sortBy == 'Distance: Nearest') {
        final distA = (a['distanceKm'] as num?)?.toDouble() ?? 99.0;
        final distB = (b['distanceKm'] as num?)?.toDouble() ?? 99.0;
        return distA.compareTo(distB);
      } else if (_sortBy == 'Prize: High to Low') {
        final pA = (a['prizePoolAmount'] as num?)?.toInt() ?? 0;
        final pB = (b['prizePoolAmount'] as num?)?.toInt() ?? 0;
        return pB.compareTo(pA);
      } else if (_sortBy == 'Spots Left') {
        final leftA = ((a['totalSpots'] as num?)?.toInt() ?? 16) - ((a['spotsFilled'] as num?)?.toInt() ?? 0);
        final leftB = ((b['totalSpots'] as num?)?.toInt() ?? 16) - ((b['spotsFilled'] as num?)?.toInt() ?? 0);
        return leftA.compareTo(leftB);
      } else if (_sortBy == 'Fee: Low to High') {
        final feeA = (a['entryFeeAmount'] as num?)?.toInt() ?? 0;
        final feeB = (b['entryFeeAmount'] as num?)?.toInt() ?? 0;
        return feeA.compareTo(feeB);
      }
      return 0;
    });

    return filtered;
  }

  void _showSortSheet() {
    final sortOptions = [
      {'title': 'Distance: Nearest First', 'key': 'Distance: Nearest', 'icon': Icons.near_me_rounded},
      {'title': 'Prize Pool: High to Low', 'key': 'Prize: High to Low', 'icon': Icons.emoji_events_rounded},
      {'title': 'Entry Fee: Low to High', 'key': 'Fee: Low to High', 'icon': Icons.payments_rounded},
      {'title': 'Spots Left: Filling Fast', 'key': 'Spots Left', 'icon': Icons.bolt_rounded},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E1711),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sort Tournaments',
                  style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sortOptions.map((opt) {
              final isSelected = _sortBy == opt['key'];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: isSelected ? const Color(0xFF16251A) : Colors.transparent,
                leading: Icon(opt['icon'] as IconData, color: isSelected ? AppTheme.primaryGreen : Colors.white60),
                title: Text(
                  opt['title'] as String,
                  style: GoogleFonts.poppins(
                    color: isSelected ? AppTheme.primaryGreen : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryGreen, size: 20) : null,
                onTap: () {
                  setState(() => _sortBy = opt['key'] as String);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    double tempDistance = _maxDistanceKm;
    String tempSport = _selectedSport;
    String tempStatus = _selectedStatus;
    String tempArea = _selectedArea;
    String tempFee = _selectedEntryFeeFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1711),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.85,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filters',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'Fine-tune tournaments by distance, sport, & format',
                          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8E9E94)),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          tempDistance = 999.0;
                          tempSport = 'All';
                          tempStatus = 'All';
                          tempArea = 'All Areas';
                          tempFee = 'All';
                        });
                      },
                      child: Text('Reset', style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF1E2F22), height: 24),

                // Scrollable filters
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Distance Radius
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Distance Radius', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                            Text(
                              tempDistance >= 999.0 ? 'Any Distance' : 'Within ${tempDistance.toInt()} km',
                              style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildChoicePill('Any Distance', tempDistance >= 999.0, () => setModalState(() => tempDistance = 999.0)),
                            _buildChoicePill('< 3 km', tempDistance == 3.0, () => setModalState(() => tempDistance = 3.0)),
                            _buildChoicePill('< 5 km (Near Me)', tempDistance == 5.0, () => setModalState(() => tempDistance = 5.0)),
                            _buildChoicePill('< 10 km', tempDistance == 10.0, () => setModalState(() => tempDistance = 10.0)),
                            _buildChoicePill('< 20 km', tempDistance == 20.0, () => setModalState(() => tempDistance = 20.0)),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 2. City / Neighborhood
                        Text('Neighborhood / Area', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableAreas.map((area) {
                            return _buildChoicePill(area, tempArea == area, () => setModalState(() => tempArea = area));
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // 3. Sport
                        Text('Sport Category', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _sportsFilter.map((sport) {
                            return _buildChoicePill(sport, tempSport == sport, () => setModalState(() => tempSport = sport));
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // 4. Registration Status
                        Text('Status', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _statusFilter.map((status) {
                            return _buildChoicePill(status, tempStatus == status, () => setModalState(() => tempStatus = status));
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // 5. Entry Fee
                        Text('Entry Fee', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildChoicePill('All Fees', tempFee == 'All', () => setModalState(() => tempFee = 'All')),
                            _buildChoicePill('🆓 Free Entry Only', tempFee == 'Free', () => setModalState(() => tempFee = 'Free')),
                            _buildChoicePill('Under ₹1,500', tempFee == 'Under 1500', () => setModalState(() => tempFee = 'Under 1500')),
                            _buildChoicePill('₹1,500 - ₹3,000', tempFee == '1500-3000', () => setModalState(() => tempFee = '1500-3000')),
                            _buildChoicePill('Above ₹3,000', tempFee == 'Above 3000', () => setModalState(() => tempFee = 'Above 3000')),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _maxDistanceKm = tempDistance;
                        _selectedSport = tempSport;
                        _selectedStatus = tempStatus;
                        _selectedArea = tempArea;
                        _selectedEntryFeeFilter = tempFee;
                        if (tempDistance == 5.0) _quickNearMe = true;
                        if (tempDistance > 5.0 && _quickNearMe) _quickNearMe = false;
                        if (tempFee == 'Free') _quickFreeEntry = true;
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Apply Filters', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChoicePill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : const Color(0xFF142418),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : const Color(0xFF223827),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }

  void _showChangeLocationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101912),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: AppTheme.primaryGreen, size: 22),
            const SizedBox(width: 8),
            Text('Select Your Location', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _availableAreas.where((a) => a != 'All Areas').map((area) {
            final isCurrent = _userCurrentArea == area;
            return ListTile(
              dense: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              tileColor: isCurrent ? const Color(0xFF182D1D) : Colors.transparent,
              title: Text(
                area,
                style: GoogleFonts.poppins(color: isCurrent ? AppTheme.primaryGreen : Colors.white, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
              ),
              trailing: isCurrent ? const Icon(Icons.check, color: AppTheme.primaryGreen, size: 18) : null,
              onTap: () {
                setState(() {
                  _userCurrentArea = area;
                  _selectedArea = area;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Location updated to $area. Showing tournaments nearby!'),
                    backgroundColor: AppTheme.primaryGreen,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRegisterDialog(Map<String, dynamic> tournament) {
    context.push('/tournament-register', extra: tournament);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredTournaments();
    final filterCount = _activeFiltersCount;

    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C140F),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tournaments',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            Text(
              'Browse city championships & cups',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF8E9E94),
              ),
            ),
          ],
        ),
        actions: [
          // 1. Prominent "Create Tournament" option in Top Right as requested
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: () async {
                await context.push('/create-tournament');
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.add_rounded, size: 16, color: Colors.black),
              label: Text(
                'Create',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.groups_outlined, color: AppTheme.primaryGreen),
            tooltip: 'My Teams',
            onPressed: () => context.push('/team-management'),
          ),
          const BysProfileAvatar(size: 32),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/create-tournament');
          if (mounted) setState(() {});
        },
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_circle, color: Colors.black, size: 20),
        label: Text('Create Tournament', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Location Bar (Quick Neighborhood Switcher for Nearby finding)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFF09120B),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.primaryGreen, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      'Location: ',
                      style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 11),
                    ),
                    GestureDetector(
                      onTap: _showChangeLocationDialog,
                      child: Row(
                        children: [
                          Text(
                            '$_userCurrentArea, Bangalore',
                            style: GoogleFonts.poppins(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryGreen, size: 16),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Quick Near Me indicator
                    GestureDetector(
                      onTap: () {
                        setState(() => _quickNearMe = !_quickNearMe);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _quickNearMe ? AppTheme.primaryGreen : const Color(0xFF142418),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me, size: 11, color: _quickNearMe ? Colors.black : AppTheme.primaryGreen),
                            const SizedBox(width: 4),
                            Text(
                              '< 5 km',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _quickNearMe ? Colors.black : AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Search Bar & Filter / Sort Buttons Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Search Input
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF101912),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF1E2F22)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Color(0xFF6F8275), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5),
                                decoration: InputDecoration(
                                  hintText: 'Search tournaments, sports, areas...',
                                  hintStyle: GoogleFonts.poppins(color: const Color(0xFF6F8275), fontSize: 12.5),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                child: const Icon(Icons.close, color: Colors.white54, size: 16),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Filter Modal Button (with counter badge)
                    GestureDetector(
                      onTap: _showFilterBottomSheet,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: filterCount > 0 ? const Color(0xFF162E1D) : const Color(0xFF101912),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: filterCount > 0 ? AppTheme.primaryGreen : const Color(0xFF1E2F22),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: filterCount > 0 ? AppTheme.primaryGreen : Colors.white70,
                            ),
                            if (filterCount > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$filterCount',
                                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Sort Button
                    GestureDetector(
                      onTap: _showSortSheet,
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF101912),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF1E2F22)),
                        ),
                        child: const Icon(Icons.swap_vert_rounded, size: 20, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // One-Tap Quick Filters Row
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildQuickChip(
                      label: '📍 Near Me (< 5km)',
                      isActive: _quickNearMe,
                      onTap: () => setState(() => _quickNearMe = !_quickNearMe),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                      label: '🆓 Free Entry',
                      isActive: _quickFreeEntry,
                      onTap: () => setState(() => _quickFreeEntry = !_quickFreeEntry),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                      label: '🔥 Fast Filling',
                      isActive: _quickFastFilling,
                      onTap: () => setState(() => _quickFastFilling = !_quickFastFilling),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                      label: '⚡ Live Today',
                      isActive: _quickLiveOnly,
                      onTap: () => setState(() => _quickLiveOnly = !_quickLiveOnly),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                      label: '📅 This Weekend',
                      isActive: _quickWeekendOnly,
                      onTap: () => setState(() => _quickWeekendOnly = !_quickWeekendOnly),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickChip(
                      label: '🏆 ₹5L+ Prize',
                      isActive: _quickHighPrize,
                      onTap: () => setState(() => _quickHighPrize = !_quickHighPrize),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Sports Filter Chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _sportsFilter.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final sport = _sportsFilter[index];
                    final isSelected = _selectedSport == sport;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedSport = sport),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryGreen : const Color(0xFF101912),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1B2C20),
                          ),
                        ),
                        child: Text(
                          sport,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.black : const Color(0xFFCFDBD2),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Status Horizontal Bar
              SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _statusFilter.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final status = _statusFilter[index];
                    final isSelected = _selectedStatus == status;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedStatus = status),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1E3524) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.6) : Colors.white12,
                          ),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryGreen : const Color(0xFF8E9E94),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Active filter tags row
              if (filterCount > 0 || _searchController.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('Active Filters:', style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 11)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_quickNearMe)
                                _buildActiveTag('Near Me (<5km)', () => setState(() => _quickNearMe = false)),
                              if (_quickFreeEntry)
                                _buildActiveTag('Free Entry', () => setState(() => _quickFreeEntry = false)),
                              if (_quickFastFilling)
                                _buildActiveTag('Fast Filling', () => setState(() => _quickFastFilling = false)),
                              if (_selectedSport != 'All')
                                _buildActiveTag(_selectedSport, () => setState(() => _selectedSport = 'All')),
                              if (_selectedStatus != 'All')
                                _buildActiveTag(_selectedStatus, () => setState(() => _selectedStatus = 'All')),
                              if (_selectedArea != 'All Areas')
                                _buildActiveTag(_selectedArea, () => setState(() => _selectedArea = 'All Areas')),
                              if (_maxDistanceKm < 999.0)
                                _buildActiveTag('< ${_maxDistanceKm.toInt()}km', () => setState(() => _maxDistanceKm = 999.0)),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: _resetAllFilters,
                                child: Text(
                                  'Clear All',
                                  style: GoogleFonts.poppins(
                                    color: Colors.redAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Spotlight Featured Banner (if all filters default)
              if (filterCount == 0 && _searchController.text.isEmpty && filtered.isNotEmpty) ...[
                _buildSpotlightBanner(context, filtered.first),
                const SizedBox(height: 20),
              ],

              // Section Header with count and current sort
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Tournaments (${filtered.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    GestureDetector(
                      onTap: _showSortSheet,
                      child: Row(
                        children: [
                          const Icon(Icons.sort_rounded, size: 14, color: AppTheme.primaryGreen),
                          const SizedBox(width: 4),
                          Text(
                            _sortBy,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Tournaments List or Empty State
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.location_off_outlined, color: Colors.white24, size: 56),
                        const SizedBox(height: 14),
                        Text(
                          'No tournaments found matching filters',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try increasing distance radius, selecting "All Areas", or clearing sport filters.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 12),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _resetAllFilters,
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.black),
                          label: Text('Reset Filters', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (int i = 0; i < filtered.length; i++) ...[
                        if (i > 0) const SizedBox(height: 16),
                        _buildTournamentCard(context, filtered[i]),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BysBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildQuickChip({required String label, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryGreen : const Color(0xFF101912),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.primaryGreen : const Color(0xFF1E2F22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.black : Colors.white,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check, size: 12, color: Colors.black),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTag(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF16251A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.white)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 12, color: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }

  // Hero Spotlight Banner
  Widget _buildSpotlightBanner(BuildContext context, Map<String, dynamic> spotlight) {
    final name = spotlight['name'] as String? ?? 'Featured Tournament';
    final format = spotlight['format'] as String? ?? '';
    final venue = spotlight['venue'] as String? ?? '';
    final prizePool = spotlight['prizePool'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () {
          context.push('/tournament-hub', extra: spotlight);
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF0F381E), Color(0xFF184E2B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFD600).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFD600), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'FEATURED CHAMPIONSHIP',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFD600),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.emoji_events, color: Color(0xFFFFD600), size: 26),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$format • $venue',
                      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFB5C8BC)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prize Pool',
                              style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF8E9E94)),
                            ),
                            Text(
                              prizePool,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            context.push('/tournament-hub', extra: spotlight);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Hub & Fixtures',
                                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Individual Tournament Card
  Widget _buildTournamentCard(BuildContext context, Map<String, dynamic> tournament) {
    final badgeColor = tournament['badgeColor'] as Color? ?? AppTheme.primaryGreen;
    final accentColor = tournament['accentColor'] as Color? ?? AppTheme.primaryGreen;
    final spotsFilled = (tournament['spotsFilled'] as num?)?.toInt() ?? 0;
    final totalSpots = (tournament['totalSpots'] as num?)?.toInt() ?? 16;
    final progress = totalSpots > 0 ? (spotsFilled / totalSpots).clamp(0.0, 1.0) : 0.0;
    final distKm = (tournament['distanceKm'] as num?)?.toDouble() ?? 3.0;
    final isNearby = distKm <= 3.0;
    final createdByYou = tournament['createdBy'] == 'You';
    final imageUrl = (tournament['image'] as String? ?? '').trim();
    final name = tournament['name'] as String? ?? 'Tournament';
    final format = tournament['format'] as String? ?? '';
    final venue = tournament['venue'] as String? ?? '';
    final dates = tournament['dates'] as String? ?? '';
    final prizePool = tournament['prizePool'] as String? ?? '';
    final entryFee = tournament['entryFee'] as String? ?? 'Free Entry';
    final sport = tournament['sport'] as String? ?? 'Sports';
    final statusBadge = tournament['statusBadge'] as String? ?? 'OPEN';
    final sportIcon = tournament['sportIcon'] as IconData? ?? Icons.sports;
    final entryFeeAmount = (tournament['entryFeeAmount'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: () {
        context.push('/tournament-hub', extra: tournament);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF101912),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: createdByYou
                ? AppTheme.primaryGreen.withValues(alpha: 0.8)
                : const Color(0xFF1B2C20),
            width: createdByYou ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image with Overlays
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Status Badge Top Left
                Positioned(
                  top: 10,
                  left: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: badgeColor, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              statusBadge,
                              style: GoogleFonts.poppins(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (createdByYou) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'YOUR TOURNAMENT',
                            style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Sport Chip Top Right
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(sportIcon, size: 12, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          sport,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Prize Pool Overlay Bottom Left
                Positioned(
                  bottom: 8,
                  left: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events, size: 14, color: Color(0xFFFFD600)),
                      const SizedBox(width: 4),
                      Text(
                        'Prize: $prizePool',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD600),
                        ),
                      ),
                    ],
                  ),
                ),
                // Entry Fee Overlay Bottom Right
                Positioned(
                  bottom: 8,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entryFee,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: entryFeeAmount == 0 ? AppTheme.primaryGreen : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Tournament Info Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Distance Tag badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isNearby ? const Color(0xFF183B22) : const Color(0xFF142418),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isNearby ? AppTheme.primaryGreen : const Color(0xFF223827),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.near_me,
                              size: 11,
                              color: isNearby ? AppTheme.primaryGreen : const Color(0xFF8E9E94),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '$distKm km away',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isNearby ? AppTheme.primaryGreen : const Color(0xFFCFDBD2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    format,
                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8E9E94)),
                  ),
                  const SizedBox(height: 8),

                  // Venue & Dates Row
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.primaryGreen),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue,
                          style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFFCFDBD2)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF8E9E94)),
                      const SizedBox(width: 4),
                      Text(
                        dates,
                        style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF8E9E94)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Registration Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$spotsFilled / $totalSpots Teams Registered',
                            style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          Text(
                            '${(progress * 100).toInt()}% Filled',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: progress >= 1.0 ? Colors.redAccent : AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: const Color(0xFF1E3023),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1.0 ? Colors.redAccent : AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Actions Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            context.push('/tournament-hub', extra: tournament);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF284230)),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'View Hub & Fixtures',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (tournament['status'] != 'Completed')
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showRegisterDialog(tournament),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              'Register Team',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 130,
      color: const Color(0xFF152219),
      child: const Center(
        child: Icon(Icons.emoji_events, size: 40, color: AppTheme.primaryGreen),
      ),
    );
  }
}
