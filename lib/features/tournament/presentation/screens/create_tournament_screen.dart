import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/tournament/data/tournament_repository.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Fields
  final _nameController = TextEditingController();
  final _venueController = TextEditingController(text: 'Play Arena');
  final _addressController = TextEditingController(text: 'Koramangala 4th Block, Bangalore');
  final _entryFeeController = TextEditingController(text: '1500');
  final _prizePoolController = TextEditingController(text: '100000');
  final _firstPrizeController = TextEditingController(text: '70000');
  final _secondPrizeController = TextEditingController(text: '30000');
  final _organizerController = TextEditingController(text: 'Bangalore Sports Circle');
  final _phoneController = TextEditingController(text: '+91 98765 43210');
  final _rulesController = TextEditingController(
    text: 'Standard tournament rules apply. Shin guards / proper sports gear mandatory. Matches are 20 mins per half. Referees decision is final.',
  );

  String _selectedSport = 'Football';
  String _selectedFormat = '5v5 Knockout';
  String _selectedLevel = 'Open Category';
  String _selectedArea = 'Koramangala';
  int _totalSpots = 16;
  bool _isFreeEntry = false;
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 9));

  int _selectedBannerIndex = 0;
  final List<Map<String, String>> _bannerPresets = [
    {
      'sport': 'Football',
      'url': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
      'label': 'Turf Stadium Night',
    },
    {
      'sport': 'Cricket',
      'url': 'https://images.unsplash.com/photo-1531415074868-036b1c57e329?w=800',
      'label': 'Box Cricket Arena',
    },
    {
      'sport': 'Badminton',
      'url': 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
      'label': 'Indoor Badminton Court',
    },
    {
      'sport': 'Basketball',
      'url': 'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800',
      'label': 'Hoops Court Lights',
    },
  ];

  final List<Map<String, dynamic>> _sportsList = [
    {'name': 'Football', 'icon': Icons.sports_soccer_rounded, 'color': Color(0xFF00E5FF)},
    {'name': 'Cricket', 'icon': Icons.sports_cricket_rounded, 'color': Color(0xFFFF9800)},
    {'name': 'Badminton', 'icon': Icons.sports_tennis_rounded, 'color': Color(0xFF10B981)},
    {'name': 'Basketball', 'icon': Icons.sports_basketball_rounded, 'color': Color(0xFFF59E0B)},
    {'name': 'Tennis', 'icon': Icons.sports_baseball_rounded, 'color': Color(0xFF8B5CF6)},
    {'name': 'Volleyball', 'icon': Icons.sports_volleyball_rounded, 'color': Color(0xFFEC4899)},
  ];

  final List<String> _formatOptions = [
    '5v5 Knockout',
    '7v7 League + Knockout',
    'Box Cricket 7v7',
    'Doubles Knockout',
    'Round Robin Group Stage',
    'Double Elimination',
  ];

  final List<String> _levelOptions = [
    'Open Category',
    'Corporate Teams',
    'Amateur / Weekend',
    'Under-21 Youth',
    'Veterans (35+)',
  ];

  final Map<String, double> _areaDistances = {
    'Koramangala': 1.2,
    'HSR Layout': 2.4,
    'Bellandur': 3.1,
    'Indiranagar': 3.8,
    'Sarjapur': 4.6,
    'BTM Layout': 2.8,
    'Electronic City': 8.5,
    'Whitefield': 14.0,
  };

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Bangalore $_selectedSport Super Cup 2025';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _addressController.dispose();
    _entryFeeController.dispose();
    _prizePoolController.dispose();
    _firstPrizeController.dispose();
    _secondPrizeController.dispose();
    _organizerController.dispose();
    _phoneController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  void _onSportChanged(String sport) {
    setState(() {
      _selectedSport = sport;
      _nameController.text = 'Bangalore $sport Championship 2025';
      if (sport == 'Football') {
        _selectedFormat = '5v5 Knockout';
        _selectedBannerIndex = 0;
      } else if (sport == 'Cricket') {
        _selectedFormat = 'Box Cricket 7v7';
        _selectedBannerIndex = 1;
      } else if (sport == 'Badminton') {
        _selectedFormat = 'Doubles Knockout';
        _selectedBannerIndex = 2;
      } else if (sport == 'Basketball') {
        _selectedFormat = '5v5 Knockout';
        _selectedBannerIndex = 3;
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.black,
              surface: Color(0xFF101912),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 2));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submitTournament() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields correctly.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final sportMeta = _sportsList.firstWhere(
      (s) => s['name'] == _selectedSport,
      orElse: () => _sportsList.first,
    );

    final feeAmount = _isFreeEntry ? 0 : int.tryParse(_entryFeeController.text.trim()) ?? 0;
    final prizeAmount = int.tryParse(_prizePoolController.text.trim()) ?? 50000;
    final distance = _areaDistances[_selectedArea] ?? 2.5;

    final newTournament = {
      'id': 'tourn_${DateTime.now().millisecondsSinceEpoch}',
      'name': _nameController.text.trim(),
      'sport': _selectedSport,
      'sportIcon': sportMeta['icon'] as IconData,
      'accentColor': sportMeta['color'] as Color,
      'format': '$_selectedFormat • $_totalSpots Teams',
      'formatType': _selectedFormat,
      'status': 'Open Entry',
      'statusBadge': 'REGISTRATION OPEN',
      'badgeColor': AppTheme.primaryGreen,
      'venue': '${_venueController.text.trim()}, $_selectedArea',
      'area': _selectedArea,
      'city': 'Bangalore',
      'distanceKm': distance,
      'dates': '${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
      'prizePool': '₹${NumberFormat('#,##,###').format(prizeAmount)}',
      'prizePoolAmount': prizeAmount,
      'entryFee': _isFreeEntry ? 'Free Entry' : '₹${NumberFormat('#,##,###').format(feeAmount)} / team',
      'entryFeeAmount': feeAmount,
      'spotsFilled': 1,
      'totalSpots': _totalSpots,
      'isFillingFast': false,
      'isWeekend': _startDate.weekday == DateTime.saturday || _startDate.weekday == DateTime.sunday,
      'organizer': _organizerController.text.trim(),
      'organizerPhone': _phoneController.text.trim(),
      'image': _bannerPresets[_selectedBannerIndex]['url']!,
      'isSpotlight': false,
      'rules': _rulesController.text.trim(),
      'level': _selectedLevel,
      'createdBy': 'You',
      'isCreator': true,
    };

    // Add to shared repository
    TournamentRepository.instance.addTournament(newTournament);

    // Show celebration dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101912),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.primaryGreen, width: 1.2),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 44),
            ),
            const SizedBox(height: 12),
            Text(
              'Tournament Published!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              newTournament['name'] as String,
              style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              '${newTournament['venue']} • 📍 ${newTournament['distanceKm']} km away',
              style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Prize Pool: ${newTournament['prizePool']} • $_totalSpots Teams',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF16251A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryGreen, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your tournament is now live in the tournament directory and nearby searches!',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop(); // return to tournament list
            },
            child: Text(
              'View Tournaments List',
              style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
              context.push('/tournament-hub', extra: newTournament);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Open Tournament Hub', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C140F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Tournament',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Host a championship & accept registrations',
              style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF8E9E94)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _submitTournament,
            child: Text(
              'Publish',
              style: GoogleFonts.poppins(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Sport Selector
                _buildSectionHeader('1. Select Sport', Icons.sports_score_rounded),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _sportsList.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final sport = _sportsList[i];
                      final isSelected = _selectedSport == sport['name'];
                      return GestureDetector(
                        onTap: () => _onSportChanged(sport['name'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryGreen : const Color(0xFF101912),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1F3324),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                sport['icon'] as IconData,
                                size: 18,
                                color: isSelected ? Colors.black : Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                sport['name'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.black : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 22),

                // 2. Tournament Details
                _buildSectionHeader('2. Tournament Details', Icons.emoji_events_outlined),
                const SizedBox(height: 12),
                _buildLabel('Tournament Title *'),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration('e.g. Bangalore Monsoon Cup 2025', Icons.edit_note_rounded),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter tournament title' : null,
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Tournament Format'),
                          _buildDropdown(
                            value: _selectedFormat,
                            items: _formatOptions,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedFormat = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Category / Level'),
                          _buildDropdown(
                            value: _selectedLevel,
                            items: _levelOptions,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedLevel = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // 3. Venue & Location (Crucial for Nearby feature)
                _buildSectionHeader('3. Venue & Location', Icons.location_on_outlined),
                const SizedBox(height: 4),
                Text(
                  'Set the area so players can easily find your tournament via Nearby filters',
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8E9E94)),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Neighborhood / Area *'),
                          _buildDropdown(
                            value: _selectedArea,
                            items: _areaDistances.keys.toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedArea = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Distance Info'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                            decoration: BoxDecoration(
                              color: const Color(0xFF142418),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.near_me, color: AppTheme.primaryGreen, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '~${_areaDistances[_selectedArea]} km away',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                _buildLabel('Turf / Venue Name *'),
                TextFormField(
                  controller: _venueController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration('e.g. Play Arena / Turf Nation', Icons.stadium_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter venue name' : null,
                ),

                const SizedBox(height: 14),
                _buildLabel('Full Address'),
                TextFormField(
                  controller: _addressController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('Street address & landmarks', Icons.map_outlined),
                ),

                const SizedBox(height: 22),

                // 4. Dates & Team Slots
                _buildSectionHeader('4. Schedule & Team Slots', Icons.calendar_month_outlined),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF101912),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1F3324)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start Date', style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 11)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.date_range, color: AppTheme.primaryGreen, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(_startDate),
                                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF101912),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1F3324)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('End Date', style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 11)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.event_available, color: AppTheme.primaryGreen, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(_endDate),
                                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildLabel('Total Team Capacity / Slots'),
                Row(
                  children: [8, 12, 16, 24, 32].map((spots) {
                    final isSelected = _totalSpots == spots;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _totalSpots = spots),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryGreen : const Color(0xFF101912),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryGreen : const Color(0xFF1F3324),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$spots',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 22),

                // 5. Entry Fee & Prize Pool
                _buildSectionHeader('5. Entry Fee & Prize Pool', Icons.payments_outlined),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101912),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF1F3324)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Free Entry Tournament', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('No registration fee required from teams', style: GoogleFonts.poppins(color: const Color(0xFF8E9E94), fontSize: 11)),
                        ],
                      ),
                      Switch(
                        value: _isFreeEntry,
                        activeColor: AppTheme.primaryGreen,
                        onChanged: (val) => setState(() => _isFreeEntry = val),
                      ),
                    ],
                  ),
                ),

                if (!_isFreeEntry) ...[
                  const SizedBox(height: 14),
                  _buildLabel('Entry Fee Per Team (₹) *'),
                  TextFormField(
                    controller: _entryFeeController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                    decoration: _inputDecoration('e.g. 1500', Icons.currency_rupee_rounded),
                    validator: (v) {
                      if (!_isFreeEntry && (v == null || v.trim().isEmpty)) {
                        return 'Please enter entry fee';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 14),
                _buildLabel('Total Prize Pool (₹) *'),
                TextFormField(
                  controller: _prizePoolController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: _inputDecoration('e.g. 100000', Icons.emoji_events_rounded),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter prize pool' : null,
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('1st Place Winner (₹)'),
                          TextFormField(
                            controller: _firstPrizeController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                            decoration: _inputDecoration('70000', Icons.workspace_premium_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('2nd Place Runner (₹)'),
                          TextFormField(
                            controller: _secondPrizeController,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                            decoration: _inputDecoration('30000', Icons.military_tech_outlined),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // 6. Tournament Banner Preset
                _buildSectionHeader('6. Poster / Banner', Icons.image_outlined),
                const SizedBox(height: 10),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _bannerPresets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final banner = _bannerPresets[i];
                      final isSelected = _selectedBannerIndex == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedBannerIndex = i),
                        child: Container(
                          width: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  banner['url']!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFF16251A)),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 6,
                                left: 8,
                                right: 8,
                                child: Text(
                                  banner['label']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 22),

                // 7. Organizer & Rules
                _buildSectionHeader('7. Organizer & Rules', Icons.admin_panel_settings_outlined),
                const SizedBox(height: 12),
                _buildLabel('Organizer / Club Name *'),
                TextFormField(
                  controller: _organizerController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('Club or organizer name', Icons.business_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter organizer name' : null,
                ),

                const SizedBox(height: 14),
                _buildLabel('Contact Phone / WhatsApp *'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: _inputDecoration('+91 98765 43210', Icons.phone_outlined),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter contact number' : null,
                ),

                const SizedBox(height: 14),
                _buildLabel('Rules & Guidelines'),
                TextFormField(
                  controller: _rulesController,
                  maxLines: 3,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Enter tournament specific guidelines...',
                    hintStyle: GoogleFonts.poppins(color: const Color(0xFF6F8275), fontSize: 12.5),
                    filled: true,
                    fillColor: const Color(0xFF101912),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1F3324))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
                  ),
                ),

                const SizedBox(height: 30),

                // Publish CTA
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _submitTournament,
                    icon: const Icon(Icons.rocket_launch_rounded, color: Colors.black, size: 20),
                    label: Text(
                      'Publish Tournament',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFB5C8BC),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: const Color(0xFF6F8275), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF101912),
      prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1F3324))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F3324)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF101912),
          isExpanded: true,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
