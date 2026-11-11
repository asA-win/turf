import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';
import 'package:turf_app/features/turf_details/domain/models/turf.dart';

class TurfDetailsScreen extends ConsumerStatefulWidget {
  final String turfId;
  const TurfDetailsScreen({super.key, required this.turfId});

  @override
  ConsumerState<TurfDetailsScreen> createState() => _TurfDetailsScreenState();
}

class _TurfDetailsScreenState extends ConsumerState<TurfDetailsScreen> {
  bool _isFavorite = false;
  bool _isDescriptionExpanded = false;
  String _selectedPeakHour = '6 PM - 10 PM';
  StreamSubscription<Map<String, dynamic>>? _turfSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final turfIdInt = int.tryParse(widget.turfId) ?? 1;
      try {
        _turfSub = ref.read(realtimeServiceProvider).connectToChannel('slots/${widget.turfId}').listen((_) {
          if (mounted) ref.invalidate(fetchTurfByIdProvider(turfIdInt));
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _turfSub?.cancel();
    super.dispose();
  }

  final List<String> _carouselImages = [
    'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=1200',
    'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=1200',
    'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=1200',
  ];

  final List<Map<String, dynamic>> _amenities = [
    {'name': 'Flood Lights', 'icon': Icons.light_mode_outlined},
    {'name': 'Parking', 'icon': Icons.directions_car_outlined},
    {'name': 'Washroom', 'icon': Icons.wc_outlined},
    {'name': 'Changing Room', 'icon': Icons.dry_cleaning_outlined},
    {'name': 'Lounge', 'icon': Icons.weekend_outlined},
    {'name': 'Refreshments', 'icon': Icons.local_cafe_outlined},
    {'name': 'First Aid', 'icon': Icons.medical_services_outlined},
    {'name': 'Wi-Fi', 'icon': Icons.wifi_rounded},
    {'name': 'AC Facility', 'icon': Icons.ac_unit_rounded},
    {'name': 'CCTV', 'icon': Icons.videocam_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final turfIdInt = int.tryParse(widget.turfId) ?? 1;
    final turfAsync = ref.watch(fetchTurfByIdProvider(turfIdInt));
    final turf = turfAsync.valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Image Carousel with overlays
                _buildHeroImage(context, turf),

                // 2. Main Turf Title & Ratings Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(turf),
                      const SizedBox(height: 12),

                      // Quick Tag Pills
                      _buildQuickPills(),
                      const SizedBox(height: 14),

                      // Description with Read More
                      _buildDescription(turf),
                      const SizedBox(height: 20),

                      // Amenities Grid (2 rows x 5 columns)
                      _buildAmenitiesSection(),
                      const SizedBox(height: 20),

                      // Specs: Turf Type & Ground Size
                      _buildSpecsSection(),
                      const SizedBox(height: 20),

                      // AI Weather & Match Conditions
                      _buildAiWeatherSection(context),
                      const SizedBox(height: 20),

                      // Peak Hours
                      _buildPeakHoursSection(),
                      const SizedBox(height: 20),

                      // Price & Apply Coupon Row
                      _buildPriceAndCouponSection(context, turf),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Fixed Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActionBar(context, turf),
          ),
        ],
      ),
    );
  }

  // Hero Image Carousel matching screenshot 4
  Widget _buildHeroImage(BuildContext context, Turf? turf) {
    return Stack(
      children: [
        Image.network(
          turf?.imageUrl ?? _carouselImages[0],
          height: 280,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 280,
            color: const Color(0xFF16251B),
            child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen, size: 60),
          ),
        ),

        // Gradient overlay for smooth dark blend
        Container(
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.6),
                Colors.transparent,
                const Color(0xFF070B08),
              ],
            ),
          ),
        ),

        // Top Navigation and actions overlay
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _isFavorite = !_isFavorite);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => context.push('/share-match/${widget.turfId}'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.file_upload_outlined, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 1 / 24 indicator bottom-right
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '1 / 24',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Dots indicator bottom center
        Positioned(
          bottom: 18,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
              ...List.generate(4, (_) => Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  // Title, Verification, Rating and Location
  Widget _buildTitleSection(Turf? turf) {
    final name = turf?.name ?? 'Play Arena';
    final location = turf?.location ?? 'Koramangala, Bengaluru';
    final rating = turf != null && turf.averageRating > 0 ? turf.averageRating.toStringAsFixed(1) : '4.8';
    final reviews = turf != null && turf.totalReviews > 0 ? '(${turf.totalReviews} Reviews)' : '(256 Reviews)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: AppTheme.primaryGreen, size: 18),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102818),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryGreen, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: AppTheme.primaryGreen, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        rating,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reviews,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    color: const Color(0xFF7E8F83),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen, size: 14),
            const SizedBox(width: 4),
            Text(
              location,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF8E9E94),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Quick Pills row
  Widget _buildQuickPills() {
    final pills = [
      {'icon': Icons.wb_cloudy_outlined, 'label': '28°C Optimal'},
      {'icon': Icons.sports_soccer, 'label': '7v7'},
      {'icon': Icons.light_mode_outlined, 'label': 'Flood Lights'},
      {'icon': Icons.local_parking_rounded, 'label': 'Parking'},
      {'icon': Icons.wc_outlined, 'label': 'Washroom'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ...pills.map((pill) => Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF111A13),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E2E22)),
            ),
            child: Row(
              children: [
                Icon(pill['icon'] as IconData, color: AppTheme.primaryGreen, size: 14),
                const SizedBox(width: 5),
                Text(
                  pill['label'] as String,
                  style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFFC0CEC5)),
                ),
              ],
            ),
          )),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF111A13),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E2E22)),
            ),
            child: const Icon(Icons.chevron_right, color: Color(0xFF8E9E94), size: 16),
          ),
        ],
      ),
    );
  }

  // Description
  Widget _buildDescription(Turf? turf) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          turf?.description ?? 'Premium turf with FIFA quality ground, excellent maintenance and top-notch amenities.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFFA0B2A5),
            height: 1.5,
          ),
          maxLines: _isDescriptionExpanded ? null : 2,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            setState(() => _isDescriptionExpanded = !_isDescriptionExpanded);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isDescriptionExpanded ? 'Read Less' : 'Read More',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                _isDescriptionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppTheme.primaryGreen,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Amenities Grid (2 rows x 5 columns)
  Widget _buildAmenitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _amenities.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.85,
            crossAxisSpacing: 6,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final item = _amenities[index];
            return Column(
              children: [
                Icon(
                  item['icon'] as IconData,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(height: 6),
                Text(
                  item['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    color: const Color(0xFFA0B2A5),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Turf Type and Ground Size Specs
  Widget _buildSpecsSection() {
    return Row(
      children: [
        // Turf Type
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF101912),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1F2F23)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16251B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sports_soccer, color: AppTheme.primaryGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Turf Type',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF7E8F83),
                      ),
                    ),
                    Text(
                      'Outdoor',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Ground Size
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF101912),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1F2F23)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16251B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.aspect_ratio_rounded, color: AppTheme.primaryGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ground Size',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF7E8F83),
                      ),
                    ),
                    Text(
                      '60m x 40m',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // AI Weather & Match Conditions Card
  Widget _buildAiWeatherSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B2A1F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D2516),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.primaryGreen, width: 0.8),
                    ),
                    child: Text(
                      'AI',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'WEATHER & MATCH CONDITIONS',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.push(
                  '/weather',
                  extra: {
                    'turfName': 'Greenfield Arena',
                    'location': 'Koramangala, Bengaluru',
                  },
                ),
                child: Row(
                  children: [
                    Text(
                      'Forecast',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, color: AppTheme.primaryGreen, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Weather Main Row: Temp + Description + Metrics
          Row(
            children: [
              const Icon(Icons.wb_cloudy_outlined, color: Color(0xFFFFB300), size: 36),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '28°C',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Partly Cloudy',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFC0CEC5),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Feels like 31°C • Wind: 14 km/h',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF7E8F83),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3 Weather Metric Chips
          Row(
            children: [
              Expanded(
                child: _weatherMetricChip(Icons.water_drop_outlined, 'Rain', '10%'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _weatherMetricChip(Icons.opacity, 'Humidity', '64%'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _weatherMetricChip(Icons.grass_rounded, 'Pitch', 'Dry / Optimal'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // AI Turf Condition Insight Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1D13),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF193B24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Insight: Ideal outdoor playing conditions. Low humidity with no rain expected during evening slots.',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: const Color(0xFFC5DACB),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherMetricChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF142017),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2E22)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 13),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  color: const Color(0xFF7E8F83),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Peak Hours
  Widget _buildPeakHoursSection() {
    final peakSlots = ['6 AM - 9 AM', '6 PM - 10 PM', '10 PM - 12 AM'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peak Hours',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          'Prices may be higher during these hours',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF7E8F83),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: peakSlots.map((slot) {
            final isSelected = _selectedPeakHour == slot;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedPeakHour = slot);
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0F2618) : const Color(0xFF111A13),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1E2E22),
                      ),
                    ),
                    child: Text(
                      slot,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppTheme.primaryGreen : const Color(0xFFA0B2A5),
                      ),
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2516),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryGreen, width: 0.8),
                      ),
                      child: Text(
                        'High',
                        style: GoogleFonts.poppins(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Price & Apply Coupon Row
  Widget _buildPriceAndCouponSection(BuildContext context, Turf? turf) {
    final priceStr = turf != null ? '₹${turf.pricePerHour.toInt()}' : '₹1,200';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF7E8F83),
              ),
            ),
            Text(
              '$priceStr /hr',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            Text(
              'Inclusive of all taxes',
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: const Color(0xFF7E8F83),
              ),
            ),
          ],
        ),

        // Apply Coupon Button
        GestureDetector(
          onTap: () => context.push('/promo-code'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF101912),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E3524)),
            ),
            child: Row(
              children: [
                const Icon(Icons.percent_rounded, color: AppTheme.primaryGreen, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Apply Coupon',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Bottom Fixed Action Bar
  Widget _buildBottomActionBar(BuildContext context, Turf? turf) {
    final priceStr = turf != null ? '₹${turf.pricePerHour.toInt()}' : '₹1,200';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F0D),
        border: Border(
          top: BorderSide(color: AppTheme.cardBorder.withValues(alpha: 0.8)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Check Availability
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.push('/slot-selection/${widget.turfId}'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E3524)),
                    backgroundColor: const Color(0xFF101912),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month_outlined, color: AppTheme.primaryGreen, size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Check Availability',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Book Now
            Expanded(
              flex: 5,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => context.push('/slot-selection/${widget.turfId}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Book Now',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Starts from $priceStr /hr',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xFF1C3823),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
