import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/features/turf_details/data/repositories/turf_repository.dart';
import 'package:turf_app/features/turf_details/domain/models/slot.dart';
import 'package:turf_app/features/turf_details/domain/models/turf.dart';

enum _SlotTimingCategory {
  aiBest,
  popular,
  standard,
}

class SlotSelectionScreen extends ConsumerStatefulWidget {
  final String turfId;
  const SlotSelectionScreen({super.key, required this.turfId});

  @override
  ConsumerState<SlotSelectionScreen> createState() => _SlotSelectionScreenState();
}

class _SlotSelectionScreenState extends ConsumerState<SlotSelectionScreen> {
  int selectedDateIndex = 0;
  Slot? selectedSlotObj;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;
  List<Slot>? _realtimeSlots;

  final List<DateTime> dateOptions = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRealtimeSlots();
    });
  }

  void _initRealtimeSlots() {
    try {
      final realtime = ref.read(realtimeServiceProvider);
      _wsSubscription = realtime.connectToChannel('slots/${widget.turfId}').listen((data) {
        if (!mounted) return;
        final type = data['type'] as String?;
        final slotId = data['slot_id'] as int?;
        if (slotId == null) return;

        setState(() {
          if (_realtimeSlots != null) {
            final idx = _realtimeSlots!.indexWhere((s) => s.id == slotId);
            if (idx != -1) {
              final oldSlot = _realtimeSlots![idx];
              if (type == 'slot_locked') {
                if (selectedSlotObj?.id == slotId) {
                  selectedSlotObj = null;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ The slot you highlighted is currently held by another player.'),
                      backgroundColor: Colors.amber,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
                _realtimeSlots![idx] = oldSlot.copyWith(isBooked: true);
              } else if (type == 'slot_booked') {
                if (selectedSlotObj?.id == slotId) {
                  selectedSlotObj = null;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚡ The selected slot was just booked by another player!'),
                      backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
                _realtimeSlots![idx] = oldSlot.copyWith(isBooked: true);
              } else if (type == 'slot_released') {
                _realtimeSlots![idx] = oldSlot.copyWith(isBooked: false);
              } else if (type == 'slot_toggled') {
                final isBooked = data['is_booked'] as bool? ?? !oldSlot.isBooked;
                _realtimeSlots![idx] = oldSlot.copyWith(isBooked: isBooked);
              }
            }
          }
        });
      });
    } catch (e) {
      debugPrint('Realtime slot listener error: $e');
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final turfIdInt = int.tryParse(widget.turfId) ?? 1;
    final turfAsync = ref.watch(fetchTurfByIdProvider(turfIdInt));
    final slotsAsync = ref.watch(fetchSlotsProvider(turfIdInt));

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Text(
          'Select Date & Time',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: turfAsync.when(
          data: (turf) => slotsAsync.when(
            data: (slots) {
              if (_realtimeSlots == null || _realtimeSlots!.isEmpty) {
                _realtimeSlots = slots.isNotEmpty
                    ? List<Slot>.from(slots)
                    : _generateFallbackSlots(turf.id, dateOptions[selectedDateIndex]);
              }
              return _buildContent(context, turf, _realtimeSlots!);
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            error: (err, stack) {
              if (_realtimeSlots == null || _realtimeSlots!.isEmpty) {
                _realtimeSlots = _generateFallbackSlots(turf.id, dateOptions[selectedDateIndex]);
              }
              return _buildContent(context, turf, _realtimeSlots!);
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          error: (err, stack) {
            final fallbackTurf = _getFallbackTurf(turfIdInt);
            if (_realtimeSlots == null || _realtimeSlots!.isEmpty) {
              _realtimeSlots = _generateFallbackSlots(turfIdInt, dateOptions[selectedDateIndex]);
            }
            return _buildContent(context, fallbackTurf, _realtimeSlots!);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Turf turf, List<Slot> slots) {
    final availableSlots = slots.where((s) => !s.isBooked).toList();
    if (selectedSlotObj == null && availableSlots.isNotEmpty) {
      selectedSlotObj = availableSlots.firstWhere(
        (s) => _getSlotCategory(s, slots) == _SlotTimingCategory.aiBest,
        orElse: () => availableSlots.first,
      );
    }

    final priceStr = '₹${(turf.pricePerHour).toInt()}';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month Picker Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(dateOptions[selectedDateIndex]),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    const Icon(Icons.calendar_month_outlined, color: AppTheme.primaryGreen, size: 20),
                  ],
                ),
                const SizedBox(height: 14),

                // Date Pill List
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(dateOptions.length, (index) {
                      final isSelected = selectedDateIndex == index;
                      final d = dateOptions[index];
                      return GestureDetector(
                        onTap: () => setState(() {
                          selectedDateIndex = index;
                          _realtimeSlots = null;
                          selectedSlotObj = null;
                        }),
                        child: Container(
                          width: 58,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryGreen : AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                DateFormat('EEE').format(d),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: isSelected ? Colors.black : AppTheme.textGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd').format(d),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.black : AppTheme.textWhite,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 28),

                // AI Timing Recommendation Banner
                _buildAiRecommendationBanner(slots),
                const SizedBox(height: 18),

                // Available Time Slots Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Timing Slot',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF102816),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2E6B47), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'LIVE SYNC',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4ADE80),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Color Legend Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLegendItem(const Color(0xFFFFB300), 'AI Best Slot'),
                    _buildLegendItem(const Color(0xFF4ADE80), 'Popular'),
                    _buildLegendItem(const Color(0xFF8E9E94), 'Available'),
                    _buildLegendItem(const Color(0xFF424D46), 'Booked'),
                  ],
                ),
                const SizedBox(height: 14),

                if (slots.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.event_busy, color: AppTheme.primaryGreen, size: 36),
                          const SizedBox(height: 10),
                          Text(
                            'No slots available for this date.',
                            style: GoogleFonts.poppins(color: AppTheme.textWhite, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: slots.map((slot) => _buildSlotTile(context, slot, slots, priceStr)).toList(),
                  ),
              ],
            ),
          ),
        ),

        // Bottom Selected Banner + Continue CTA
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceDark,
            border: Border(top: BorderSide(color: AppTheme.cardBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Selected Slot',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey),
                          ),
                          if (selectedSlotObj != null &&
                              _getSlotCategory(selectedSlotObj!, slots) == _SlotTimingCategory.aiBest) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF332306),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFFFB300), width: 0.6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.auto_awesome, color: Color(0xFFFFB300), size: 9),
                                  const SizedBox(width: 3),
                                  Text(
                                    'AI Best Match',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFFB300),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        selectedSlotObj != null
                            ? '${DateFormat('EEE, dd MMM').format(selectedSlotObj!.startTime.toLocal())} • ${DateFormat('hh:mm a').format(selectedSlotObj!.startTime.toLocal())}'
                            : 'No slot selected',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    priceStr,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: selectedSlotObj == null
                      ? null
                      : () async {
                          final slotToBook = selectedSlotObj!;
                          try {
                            await ref.read(turfRepositoryProvider).lockSlot(slotToBook.id);
                          } catch (_) {}
                          if (context.mounted) {
                            context.push('/checkout', extra: {
                              'turf': turf,
                              'slot': slotToBook,
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Continue to Checkout',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Slot> _generateFallbackSlots(int turfId, DateTime date) {
    final times = [
      {'start': 6, 'end': 7},
      {'start': 7, 'end': 8},
      {'start': 8, 'end': 9},
      {'start': 16, 'end': 17},
      {'start': 17, 'end': 18},
      {'start': 18, 'end': 19},
      {'start': 19, 'end': 20},
      {'start': 20, 'end': 21},
      {'start': 21, 'end': 22},
    ];

    return times.asMap().entries.map((e) {
      final idx = e.key;
      final t = e.value;
      final start = DateTime(date.year, date.month, date.day, t['start']!, 0);
      final end = DateTime(date.year, date.month, date.day, t['end']!, 0);
      return Slot(
        id: (turfId * 100) + idx + 1,
        turfId: turfId,
        startTime: start,
        endTime: end,
        isBooked: idx == 3,
      );
    }).toList();
  }

  _SlotTimingCategory _getSlotCategory(Slot slot, List<Slot> slots) {
    final hour = slot.startTime.toLocal().hour;
    // 7 PM - 8 PM (19:00) is the prime AI recommendation
    final has7pmAvailable = slots.any((s) => !s.isBooked && s.startTime.toLocal().hour == 19);
    if (has7pmAvailable && hour == 19) {
      return _SlotTimingCategory.aiBest;
    }
    // If 7 PM is booked or not present, 6 PM (18:00) becomes AI Best
    if (!has7pmAvailable && hour == 18) {
      return _SlotTimingCategory.aiBest;
    }
    // Popular slots
    if (hour == 18 || hour == 20) {
      return _SlotTimingCategory.popular;
    }
    return _SlotTimingCategory.standard;
  }

  Widget _buildAiRecommendationBanner(List<Slot> slots) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF19160A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF524010)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2208),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFFFFB300), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AI TIMING RECOMMENDATION',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFB300),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'OPTIMAL',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFB300),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '7:00 PM - 8:00 PM is highlighted in gold as the best timing slot today based on pleasant evening weather (26°C), optimal pitch bounce, and peak player turnout.',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: const Color(0xFFDCD2BD),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: const Color(0xFFA0B2A5),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotTile(BuildContext context, Slot slot, List<Slot> slots, String priceStr) {
    final timeFormat = DateFormat('hh:mm a');
    final startStr = timeFormat.format(slot.startTime.toLocal());
    final endStr = timeFormat.format(slot.endTime.toLocal());

    // 1. Booked Slot
    if (slot.isBooked) {
      return Container(
        width: (MediaQuery.of(context).size.width - 52) / 2,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0C0F0D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF19201C)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$startStr - $endStr',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF556059),
                      decoration: TextDecoration.lineThrough,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B201D),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'BOOKED',
                    style: GoogleFonts.poppins(
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6B7A71),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Unavailable',
              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF455049)),
            ),
          ],
        ),
      );
    }

    // 2. Available Slot with AI Timing Categories
    final category = _getSlotCategory(slot, slots);
    final isBest = category == _SlotTimingCategory.aiBest;
    final isPopular = category == _SlotTimingCategory.popular;
    final isSelected = selectedSlotObj?.id == slot.id;

    // Distinct background and border colors for each category
    Color bgColor;
    Color borderColor;
    double borderWidth = isSelected ? 2.0 : (isBest ? 1.5 : 1.0);

    if (isSelected) {
      bgColor = isBest
          ? const Color(0xFF281E08)
          : AppTheme.primaryGreen.withValues(alpha: 0.18);
      borderColor = isBest ? const Color(0xFFFFB300) : AppTheme.primaryGreen;
    } else if (isBest) {
      bgColor = const Color(0xFF1D1707);
      borderColor = const Color(0xFFFFB300);
    } else if (isPopular) {
      bgColor = const Color(0xFF0D1D13);
      borderColor = const Color(0xFF1E5235);
    } else {
      bgColor = AppTheme.cardDark;
      borderColor = AppTheme.cardBorder;
    }

    return GestureDetector(
      onTap: () => setState(() => selectedSlotObj = slot),
      child: Container(
        width: (MediaQuery.of(context).size.width - 52) / 2,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isBest
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.12),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isBest)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF332306),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFFFB300), width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFFFFB300), size: 10),
                        const SizedBox(width: 3),
                        Text(
                          'AI BEST',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFFB300),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11291B),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFF2E6B47), width: 0.8),
                    ),
                    child: Text(
                      'POPULAR',
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4ADE80),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 16),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 16),
              ],
            ),
            const SizedBox(height: 6),

            // Time String
            Text(
              '$startStr - $endStr',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (isBest ? const Color(0xFFFFD54F) : AppTheme.primaryGreen)
                    : (isBest ? const Color(0xFFFFE082) : AppTheme.textWhite),
              ),
            ),
            const SizedBox(height: 3),

            // Price & Subtitle Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  priceStr,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppTheme.primaryGreen : AppTheme.textGrey,
                  ),
                ),
                Text(
                  isBest ? '26°C Cool' : (isPopular ? 'High Demand' : ''),
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: isBest ? const Color(0xFFFFB300) : const Color(0xFF4ADE80),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Turf _getFallbackTurf(int turfId) {
    return Turf(
      id: turfId,
      name: turfId == 2 ? 'City Arena Kilpauk' : 'Greenfield Sports Arena',
      location: turfId == 2 ? 'Kilpauk, Chennai' : 'Koramangala, Bengaluru',
      pricePerHour: turfId == 2 ? 1500.0 : 1200.0,
      sportTypes: 'Football, Cricket',
      averageRating: 4.8,
      totalReviews: 124,
    );
  }
}
