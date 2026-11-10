import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/services/realtime_service.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class ParkingScreen extends ConsumerStatefulWidget {
  const ParkingScreen({super.key});

  @override
  ConsumerState<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends ConsumerState<ParkingScreen> {
  String selectedVehicle = 'Car';
  int availableSlots = 23;
  int totalSlots = 50;
  bool isReserving = false;
  StreamSubscription<Map<String, dynamic>>? _parkingSub;

  @override
  void initState() {
    super.initState();
    _fetchParkingStatus();
    _connectRealtime();
  }

  Future<void> _fetchParkingStatus() async {
    try {
      final dio = ref.read(apiClientProvider);
      final res = await dio.get('/api/v1/parking/status');
      if (res.statusCode == 200 && res.data is Map) {
        if (mounted) {
          setState(() {
            availableSlots = (res.data['available_slots'] as num?)?.toInt() ?? availableSlots;
            totalSlots = (res.data['total_slots'] as num?)?.toInt() ?? totalSlots;
          });
        }
      }
    } catch (e) {
      debugPrint('Parking status fetch fallback: $e');
    }
  }

  void _connectRealtime() {
    final stream = ref.read(realtimeServiceProvider).connectToChannel('parking');
    _parkingSub = stream.listen((event) {
      debugPrint('Real-time parking event: $event');
      final eventType = event['type'] as String?;
      if (eventType == 'parking_updated') {
        if (mounted) {
          setState(() {
            if (event.containsKey('available_slots')) {
              availableSlots = (event['available_slots'] as num).toInt();
            }
            if (event.containsKey('total_slots')) {
              totalSlots = (event['total_slots'] as num).toInt();
            }
          });

          final msg = event['message'] as String? ?? 'Parking slot updated';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.local_parking, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text('⚡ $msg ($availableSlots left)'),
                ],
              ),
              backgroundColor: AppTheme.cardDark,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _reserveParking() async {
    if (availableSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No parking slots currently available!'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }

    setState(() => isReserving = true);

    // Optimistic UI update
    final newAvailable = (availableSlots - 1).clamp(0, totalSlots);
    setState(() {
      availableSlots = newAvailable;
    });

    // Broadcast live over WebSocket
    ref.read(realtimeServiceProvider).emitToChannel('parking', {
      'type': 'parking_updated',
      'available_slots': newAvailable,
      'total_slots': totalSlots,
      'vehicle_type': selectedVehicle,
      'message': 'New $selectedVehicle parked',
    });

    try {
      final dio = ref.read(apiClientProvider);
      await dio.post('/api/v1/parking/reserve', data: {
        'vehicle_type': selectedVehicle,
        'price': 50.0,
      });
    } catch (e) {
      debugPrint('Parking reserve REST fallback: $e');
    }

    if (mounted) {
      setState(() => isReserving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $selectedVehicle parking slot reserved at Elite Arena! (₹50)'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  Future<void> _releaseParking() async {
    final newAvailable = (availableSlots + 1).clamp(0, totalSlots);
    setState(() {
      availableSlots = newAvailable;
    });

    // Broadcast live over WebSocket
    ref.read(realtimeServiceProvider).emitToChannel('parking', {
      'type': 'parking_updated',
      'available_slots': newAvailable,
      'total_slots': totalSlots,
      'message': 'Parking slot freed',
    });

    try {
      final dio = ref.read(apiClientProvider);
      await dio.post('/api/v1/parking/release');
    } catch (e) {
      debugPrint('Parking release REST fallback: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚗 Parking slot released live!'),
          backgroundColor: AppTheme.cardDark,
        ),
      );
    }
  }

  @override
  void dispose() {
    _parkingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = totalSlots > 0 ? (availableSlots / totalSlots).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Smart Parking',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
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
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'IOT LIVE',
                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Circular Gauge Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Elite Arena • Real-time Sensors',
                              style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textGrey),
                            ),
                            const SizedBox(height: 20),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: ratio),
                                    duration: const Duration(milliseconds: 500),
                                    builder: (context, value, _) => CircularProgressIndicator(
                                      value: value,
                                      strokeWidth: 12,
                                      color: availableSlots < 5 ? AppTheme.errorRed : AppTheme.primaryGreen,
                                      backgroundColor: AppTheme.cardBorder,
                                      strokeCap: StrokeCap.round,
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                                      child: Text(
                                        '$availableSlots / $totalSlots',
                                        key: ValueKey<int>(availableSlots),
                                        style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                                      ),
                                    ),
                                    Text(
                                      'Available Slots',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: availableSlots < 5 ? AppTheme.errorRed : AppTheme.primaryGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton.icon(
                                  onPressed: _releaseParking,
                                  icon: const Icon(Icons.outbond, size: 16, color: AppTheme.textGrey),
                                  label: Text('Simulate Vehicle Exit (+1)', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Reserve Card Title
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Reserve your slot in advance',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textWhite),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Vehicle Type Selector Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _vehicleType('Car', Icons.directions_car),
                          _vehicleType('Bike', Icons.two_wheeler),
                          _vehicleType('EV', Icons.ev_station),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Reserve CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isReserving ? null : _reserveParking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isReserving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                        )
                      : Text(
                          'Reserve Now ₹50',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vehicleType(String title, IconData icon) {
    final isSelected = selectedVehicle == title;
    return GestureDetector(
      onTap: () => setState(() => selectedVehicle = title),
      child: Container(
        width: 95,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.15) : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryGreen : AppTheme.textGrey, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
