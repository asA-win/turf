import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class AiSlotRecommendationScreen extends StatefulWidget {
  const AiSlotRecommendationScreen({super.key});

  @override
  State<AiSlotRecommendationScreen> createState() => _AiSlotRecommendationScreenState();
}

class _AiSlotRecommendationScreenState extends State<AiSlotRecommendationScreen> {
  int _selectedSlotIndex = 0;

  List<Map<String, dynamic>> get _slots {
    final now = DateTime.now();
    final todayDay = now.day.toString();
    final todayMonth = DateFormat('MMM').format(now);
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowDay = tomorrow.day.toString();
    final tomorrowMonth = DateFormat('MMM').format(tomorrow);

    return [
      {
        'isBestMatch': true,
        'day': todayDay,
        'month': todayMonth,
        'time': '6:00 PM - 7:00 PM',
        'demand': 'Low Demand',
        'weather': 'Great Weather',
        'activity': 'High Player Activity',
        'playersOnline': '8-10 Players online',
        'price': '₹1,200',
      },
      {
        'isBestMatch': false,
        'day': todayDay,
        'month': todayMonth,
        'time': '7:00 PM - 8:00 PM',
        'demand': 'Medium Demand',
        'weather': 'Good Weather',
        'activity': 'High Player Activity',
        'playersOnline': '6-8 Players online',
        'price': '₹1,200',
      },
      {
        'isBestMatch': false,
        'day': tomorrowDay,
        'month': tomorrowMonth,
        'time': '5:00 PM - 6:00 PM',
        'demand': 'Low Demand',
        'weather': 'Good Weather',
        'activity': 'Medium Player Activity',
        'playersOnline': '4-6 Players online',
        'price': '₹1,000',
      },
    ];
  }

  final List<Map<String, dynamic>> _factors = [
    {'name': 'Weather\nConditions', 'icon': Icons.wb_sunny_outlined},
    {'name': 'Live Player\nActivity', 'icon': Icons.people_outline_rounded},
    {'name': 'Historical\nDemand', 'icon': Icons.trending_up_rounded},
    {'name': 'Peak Hours\nPrediction', 'icon': Icons.access_time_rounded},
    {'name': 'Event & Holiday\nImpact', 'icon': Icons.event_note_outlined},
  ];

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
                    // 1. AI Analysis Complete Card
                    _buildAiAnalysisCompleteCard(),
                    const SizedBox(height: 20),

                    // 2. Recommended Slots Header
                    _buildRecommendedSlotsHeader(context),
                    const SizedBox(height: 12),

                    // 3. Recommended Slots Cards
                    _buildSlotsList(context),
                    const SizedBox(height: 12),

                    // More Slots Link
                    Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryGreen, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              'More Slots',
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
                    const SizedBox(height: 20),

                    // 4. Why trust our AI recommendations Card
                    _buildWhyTrustCard(),
                    const SizedBox(height: 22),

                    // 5. Factors We Analyze
                    _buildFactorsWeAnalyze(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Find More Slots Button
            _buildBottomCtaButton(context),
          ],
        ),
      ),
    );
  }

  // Top Bar matching Screenshot 5
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
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'AI Slot Recommendation',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Smart picks for the best game experience',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: const Color(0xFF8E9E94),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF111A13),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E2E22)),
            ),
            child: const Icon(Icons.info_outline, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // AI Analysis Complete Card
  Widget _buildAiAnalysisCompleteCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B2A1F)),
      ),
      child: Row(
        children: [
          // Robot Avatar with glowing ring
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2618),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy_outlined, color: AppTheme.primaryGreen, size: 26),
          ),
          const SizedBox(width: 12),

          // Message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Analysis Complete',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "We've analyzed weather, demand, and player activity to find the best slots for you.",
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    color: const Color(0xFFA0B2A5),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Match Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'AI Match Score',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: const Color(0xFF7E8F83),
                ),
              ),
              Text(
                '96%',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryGreen,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Excellent Choice',
                    style: GoogleFonts.poppins(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.star, color: AppTheme.primaryGreen, size: 10),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Recommended Slots Header
  Widget _buildRecommendedSlotsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Recommended Slots',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Text(
              'Top picks just for you',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: const Color(0xFF7E8F83),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {},
          child: Row(
            children: [
              Text(
                'Why these slots?',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.primaryGreen, size: 14),
            ],
          ),
        ),
      ],
    );
  }

  // Slots List
  Widget _buildSlotsList(BuildContext context) {
    return Column(
      children: List.generate(_slots.length, (index) {
        final slot = _slots[index];
        final isBestMatch = slot['isBestMatch'] == true;
        final isSelected = _selectedSlotIndex == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF101912),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isBestMatch || isSelected) ? AppTheme.primaryGreen : const Color(0xFF1B2A1F),
                width: (isBestMatch || isSelected) ? 1.2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBestMatch)
                  Container(
                    margin: const EdgeInsets.only(top: 8, left: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11321C),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primaryGreen, width: 0.6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: AppTheme.primaryGreen, size: 11),
                        const SizedBox(width: 4),
                        Text(
                          'BEST MATCH',
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Date Box
                      Container(
                        width: 52,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF152219),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF203225)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Today',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                color: const Color(0xFF7E8F83),
                              ),
                            ),
                            Text(
                              slot['day'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              slot['month'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF7E8F83),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Time & Badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot['time'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _checkChip(slot['demand'] as String),
                                _checkChip(slot['weather'] as String),
                              ],
                            ),
                            const SizedBox(height: 3),
                            _checkChip(slot['activity'] as String),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.people_alt_outlined, color: AppTheme.primaryGreen, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  slot['playersOnline'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Price & Select Slot
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${slot['price']} /hr',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() => _selectedSlotIndex = index);
                              context.push('/slot-selection/1');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isBestMatch ? AppTheme.primaryGreen : const Color(0xFF152219),
                              foregroundColor: isBestMatch ? Colors.black : Colors.white,
                              side: isBestMatch ? null : const BorderSide(color: Color(0xFF223528)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              'Select Slot',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
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
      }),
    );
  }

  Widget _checkChip(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen, size: 11),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 9.5,
            color: const Color(0xFFA0B2A5),
          ),
        ),
      ],
    );
  }

  // Why Trust Card
  Widget _buildWhyTrustCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B2A1F)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF142419),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_outlined, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why trust our AI recommendations?',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Our AI considers 10+ factors including weather, demand, player count & peak hours.',
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    color: const Color(0xFF8E9E94),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Row(
            children: [
              Text(
                'Learn More',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.primaryGreen, size: 12),
            ],
          ),
        ],
      ),
    );
  }

  // Factors We Analyze
  Widget _buildFactorsWeAnalyze() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Factors We Analyze',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _factors.map((factor) {
            return SizedBox(
              width: 60,
              child: Column(
                children: [
                  Icon(
                    factor['icon'] as IconData,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    factor['name'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 8.5,
                      color: const Color(0xFFA0B2A5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Bottom CTA
  Widget _buildBottomCtaButton(BuildContext context) {
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
          onPressed: () => context.push('/slot-selection/1'),
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
                  const Icon(Icons.auto_awesome, color: Colors.black, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Find More Slots',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              Text(
                'Let AI find more perfect slots for you',
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
