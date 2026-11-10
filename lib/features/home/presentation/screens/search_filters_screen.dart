import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class SearchFiltersScreen extends StatefulWidget {
  const SearchFiltersScreen({super.key});

  @override
  State<SearchFiltersScreen> createState() => _SearchFiltersScreenState();
}

class _SearchFiltersScreenState extends State<SearchFiltersScreen> {
  String _selectedSport = 'Football';
  String _selectedTurfType = 'Outdoor';
  String _selectedAvailability = 'All';
  String _selectedSortBy = 'Recommended';
  String _selectedPricePreset = '₹1000 - ₹2000';
  RangeValues _priceRange = const RangeValues(300, 3000);

  final Map<String, bool> _facilities = {
    'Parking': true,
    'Washroom': true,
    'Flood Lights': true,
    'Lounge': false,
    'Refreshments': true,
    'Changing Room': false,
    'First Aid': false,
    'Wi-Fi': false,
    'AC Facility': false,
  };

  final Map<String, IconData> _facilityIcons = {
    'Parking': Icons.directions_car_outlined,
    'Washroom': Icons.wc_outlined,
    'Flood Lights': Icons.light_mode_outlined,
    'Lounge': Icons.weekend_outlined,
    'Refreshments': Icons.local_cafe_outlined,
    'Changing Room': Icons.dry_cleaning_outlined,
    'First Aid': Icons.medical_services_outlined,
    'Wi-Fi': Icons.wifi_rounded,
    'AC Facility': Icons.ac_unit_rounded,
  };

  final List<Map<String, dynamic>> _sports = [
    {'name': 'Football', 'icon': Icons.sports_soccer},
    {'name': 'Cricket', 'icon': Icons.sports_cricket},
    {'name': 'Badminton', 'icon': Icons.sports_tennis},
    {'name': 'Basketball', 'icon': Icons.sports_basketball},
    {'name': 'Tennis', 'icon': Icons.sports_baseball},
    {'name': 'More', 'icon': Icons.more_horiz},
  ];

  final List<String> _pricePresets = [
    'Under ₹500',
    '₹500 - ₹1000',
    '₹1000 - ₹2000',
    'Above ₹2000',
  ];

  final List<String> _turfTypes = ['Indoor', 'Outdoor', 'Rooftop', 'Open', 'Covered'];
  final List<String> _availabilities = ['All', 'Available Now', 'Today', 'This Weekend'];

  void _resetAll() {
    setState(() {
      _selectedSport = 'Football';
      _selectedTurfType = 'Outdoor';
      _selectedAvailability = 'All';
      _selectedSortBy = 'Recommended';
      _selectedPricePreset = '₹1000 - ₹2000';
      _priceRange = const RangeValues(300, 3000);
      _facilities.updateAll((key, value) => false);
      _facilities['Parking'] = true;
      _facilities['Washroom'] = true;
      _facilities['Flood Lights'] = true;
      _facilities['Refreshments'] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Input
                    _buildLocationBar(),
                    const SizedBox(height: 20),

                    // Date & Time
                    _buildSectionHeader('Date & Time', onClear: () {}),
                    const SizedBox(height: 10),
                    _buildDateTimeCards(),
                    const SizedBox(height: 22),

                    // Select Sport
                    _buildSectionHeader('Select Sport', onClear: () {
                      setState(() => _selectedSport = '');
                    }),
                    const SizedBox(height: 10),
                    _buildSportsRow(),
                    const SizedBox(height: 22),

                    // Facilities
                    _buildSectionHeader('Facilities', onClear: () {
                      setState(() => _facilities.updateAll((key, value) => false));
                    }),
                    const SizedBox(height: 10),
                    _buildFacilitiesGrid(),
                    const SizedBox(height: 22),

                    // Price Range
                    _buildSectionHeader('Price Range', onClear: () {
                      setState(() {
                        _priceRange = const RangeValues(300, 3000);
                        _selectedPricePreset = '';
                      });
                    }),
                    const SizedBox(height: 10),
                    _buildPriceRange(),
                    const SizedBox(height: 22),

                    // Sort By
                    _buildSortBy(),
                    const SizedBox(height: 22),

                    // Turf Type
                    _buildSectionHeader('Turf Type', onClear: () {
                      setState(() => _selectedTurfType = '');
                    }),
                    const SizedBox(height: 10),
                    _buildTurfTypesRow(),
                    const SizedBox(height: 22),

                    // Availability
                    _buildSectionHeader('Availability', onClear: () {
                      setState(() => _selectedAvailability = '');
                    }),
                    const SizedBox(height: 10),
                    _buildAvailabilityRow(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Search Button
            _buildBottomSearchButton(context),
          ],
        ),
      ),
    );
  }

  // Top Bar
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111A13),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1E2E22)),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search & Filters',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Find the perfect turf for your game',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF8E9E94),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: _resetAll,
            child: Row(
              children: [
                const Icon(Icons.refresh, color: AppTheme.primaryGreen, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Reset All',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Location Bar
  Widget _buildLocationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2F23)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Text(
                  'Koramangala, Bengaluru',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8E9E94), size: 18),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF16251B),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  // Section Header with Clear button
  Widget _buildSectionHeader(String title, {required VoidCallback onClear}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        GestureDetector(
          onTap: onClear,
          child: Text(
            'Clear',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }

  // Date & Time Cards
  Widget _buildDateTimeCards() {
    return Row(
      children: [
        // Date
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF101912),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1F2F23)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, color: AppTheme.primaryGreen, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Date',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF8E9E94),
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryGreen, size: 18),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Sat, 24 May 2025',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Time
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF101912),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1F2F23)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: AppTheme.primaryGreen, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Time',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF8E9E94),
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryGreen, size: 18),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '6:00 PM - 10:00 PM',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Sports Row
  Widget _buildSportsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _sports.map((sport) {
        final isSelected = _selectedSport == sport['name'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSport = sport['name'] as String;
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF111A13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1C2C20),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      sport['icon'] as IconData,
                      color: isSelected ? Colors.white : const Color(0xFFC0CEC5),
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sport['name'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppTheme.primaryGreen : const Color(0xFFC0CEC5),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.black, size: 10),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Facilities 3-columns Grid
  Widget _buildFacilitiesGrid() {
    final facilityKeys = _facilities.keys.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: facilityKeys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final facility = facilityKeys[index];
        final isSelected = _facilities[facility] ?? false;
        final icon = _facilityIcons[facility] ?? Icons.check_circle_outline;

        return GestureDetector(
          onTap: () {
            setState(() {
              _facilities[facility] = !isSelected;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF111A13),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1E2E22),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppTheme.primaryGreen : const Color(0xFF7E8F83),
                  size: 16,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    facility,
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : const Color(0xFFA0B2A5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.black, size: 9),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Price Range Section
  Widget _buildPriceRange() {
    return Column(
      children: [
        // Range Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₹ ${_priceRange.start.toInt()}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                Text(
                  '₹ ${_priceRange.end.toInt()}+',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.play_arrow, color: Color(0xFF8E9E94), size: 12),
              ],
            ),
          ],
        ),

        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryGreen,
            inactiveTrackColor: const Color(0xFF1E2E22),
            trackHeight: 4,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
          ),
          child: RangeSlider(
            values: _priceRange,
            min: 100,
            max: 5000,
            onChanged: (values) {
              setState(() {
                _priceRange = values;
                _selectedPricePreset = '';
              });
            },
          ),
        ),
        const SizedBox(height: 6),

        // Presets row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _pricePresets.map((preset) {
            final isSelected = _selectedPricePreset == preset;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPricePreset = preset;
                  if (preset == 'Under ₹500') {
                    _priceRange = const RangeValues(100, 500);
                  } else if (preset == '₹500 - ₹1000') {
                    _priceRange = const RangeValues(500, 1000);
                  } else if (preset == '₹1000 - ₹2000') {
                    _priceRange = const RangeValues(1000, 2000);
                  } else if (preset == 'Above ₹2000') {
                    _priceRange = const RangeValues(2000, 5000);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF111A13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1E2E22),
                  ),
                ),
                child: Text(
                  preset,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppTheme.primaryGreen : const Color(0xFFA0B2A5),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Sort By
  Widget _buildSortBy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF101912),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1F2F23)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.swap_vert_rounded, color: AppTheme.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _selectedSortBy,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryGreen, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  // Turf Type
  Widget _buildTurfTypesRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _turfTypes.map((type) {
          final isSelected = _selectedTurfType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTurfType = type);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F2618) : const Color(0xFF111A13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1E2E22),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      type,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppTheme.primaryGreen : const Color(0xFFA0B2A5),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.black, size: 9),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Availability Row
  Widget _buildAvailabilityRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _availabilities.map((avail) {
          final isSelected = _selectedAvailability == avail;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedAvailability = avail);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F2618) : const Color(0xFF111A13),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1E2E22),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      avail,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppTheme.primaryGreen : const Color(0xFFA0B2A5),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.black, size: 9),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Sticky Bottom Search Button
  Widget _buildBottomSearchButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F0D),
        border: Border(
          top: BorderSide(color: AppTheme.cardBorder.withValues(alpha: 0.8)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () => context.go('/discover'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 6),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, color: Colors.black, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Search Turfs (128)',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Text(
                'Find best turfs for your game',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF1E3A24),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
