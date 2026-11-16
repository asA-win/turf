import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/auth/presentation/controllers/user_provider.dart';
import 'package:turf_app/features/home/data/match_repository.dart';

class CreateMatchScreen extends ConsumerStatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  ConsumerState<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends ConsumerState<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController(text: 'Turf Weekend Championship');
  final _venueController = TextEditingController(text: 'Play Arena Turf');
  final _locationController = TextEditingController(text: 'Sarjapur Road, Bangalore');
  final _teamAController = TextEditingController(text: 'Team Alpha');
  final _teamBController = TextEditingController(text: 'Team Beta');
  final _feeController = TextEditingController(text: '150');

  String _selectedSport = 'Football';
  String _selectedFormat = '5v5';
  String _teamAColor = 'Neon Green';
  String _teamBColor = 'Royal Blue';
  int _playersCount = 10;
  String _level = 'Intermediate';
  DateTime _matchDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _matchTime = const TimeOfDay(hour: 19, minute: 0);
  int _durationMinutes = 60;
  bool _isSubmitting = false;

  final Map<String, List<String>> _sportFormats = {
    'Football': ['5v5', '7v7', '11v11'],
    'Cricket': ['Box Cricket 6v6', 'Box Cricket 8v8', '11v11 T20'],
    'Badminton': ['Singles', 'Doubles'],
    'Basketball': ['3v3 Half Court', '5v5 Full Court'],
    'Tennis': ['Singles', 'Doubles'],
  };

  final List<String> _teamColors = [
    'Neon Green',
    'Royal Blue',
    'Crimson Red',
    'Golden Yellow',
    'Jet Black',
    'Pure White',
    'Purple',
    'Orange',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _locationController.dispose();
    _teamAController.dispose();
    _teamBController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _onSportChanged(String sport) {
    setState(() {
      _selectedSport = sport;
      final formats = _sportFormats[sport] ?? ['Standard'];
      _selectedFormat = formats.first;
      if (sport == 'Badminton' || sport == 'Tennis') {
        _playersCount = 4;
      } else if (sport == 'Cricket') {
        _playersCount = 12;
      } else if (sport == 'Basketball') {
        _playersCount = 6;
      } else {
        _playersCount = 10;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _matchDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryGreen,
            surface: Color(0xFF101912),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _matchDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _matchTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryGreen,
            surface: Color(0xFF101912),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _matchTime = picked);
    }
  }

  Future<void> _submitCreateMatch() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(dioClientProvider);
      final user = ref.read(currentUserProvider);

      final dateFormatted = DateFormat('yyyy-MM-dd').format(_matchDate);
      final hour = _matchTime.hour.toString().padLeft(2, '0');
      final minute = _matchTime.minute.toString().padLeft(2, '0');
      final timeFormatted = '$hour:$minute';

      final fee = double.tryParse(_feeController.text.trim()) ?? 0.0;

      final payload = {
        'title': _titleController.text.trim(),
        'sport_type': _selectedSport,
        'format': _selectedFormat,
        'venue_name': _venueController.text.trim(),
        'location': _locationController.text.trim(),
        'match_date': dateFormatted,
        'match_time': timeFormatted,
        'duration_minutes': _durationMinutes,
        'team_a_name': _teamAController.text.trim(),
        'team_b_name': _teamBController.text.trim(),
        'team_a_color': _teamAColor,
        'team_b_color': _teamBColor,
        'status': 'scheduled',
        'max_players': _playersCount,
        'price_per_player': fee,
        'skill_level': _level,
      };

      final created = await MatchRepository.instance.createMatch(
        payload,
        dio: dio,
        currentUserId: user?.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match created and published successfully!'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );

      if (created != null) {
        final config = Map<String, dynamic>.from(created['scoreboardConfig'] as Map? ?? {});
        config['id'] = created['backendId'];
        config['backendId'] = created['backendId'];
        config['isCreator'] = true;
        config['isViewOnly'] = false;
        context.pushReplacement('/scoreboard', extra: config);
      } else {
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create match: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formats = _sportFormats[_selectedSport] ?? ['Standard'];

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1711),
        title: Text(
          'Create & Host Match',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Select Sport
                Text('Sport Type', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _sportChip('Football', Icons.sports_soccer),
                      _sportChip('Cricket', Icons.sports_cricket),
                      _sportChip('Badminton', Icons.sports_tennis),
                      _sportChip('Basketball', Icons.sports_basketball),
                      _sportChip('Tennis', Icons.sports_tennis),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Match Title
                Text('Match Title', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. Friday 5v5 Friendly Match',
                    hintStyle: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryGreen)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a match title' : null,
                ),
                const SizedBox(height: 20),

                // 3. Match Format
                Text('Match Format', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: formats.contains(_selectedFormat) ? _selectedFormat : formats.first,
                      isExpanded: true,
                      dropdownColor: AppTheme.cardDark,
                      items: formats
                          .map((f) => DropdownMenuItem(value: f, child: Text(f, style: GoogleFonts.poppins(color: Colors.white))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedFormat = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Venue & Location
                Text('Venue & Location', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _venueController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.stadium_outlined, color: AppTheme.primaryGreen),
                    hintText: 'Turf / Venue Name',
                    hintStyle: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter venue name' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _locationController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen),
                    hintText: 'City, Area (e.g. Sarjapur, Bangalore)',
                    hintStyle: GoogleFonts.poppins(color: AppTheme.textGrey, fontSize: 13),
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter location' : null,
                ),
                const SizedBox(height: 20),

                // 5. Teams Names & Colors
                Text('Team Names & Jersey Colors', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Host Team (A)', style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _teamAController,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.cardDark,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _teamAColor,
                            dropdownColor: AppTheme.cardDark,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.cardDark,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: _teamColors.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.poppins(color: Colors.white, fontSize: 11)))).toList(),
                            onChanged: (v) => setState(() => _teamAColor = v ?? _teamAColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Opponent Team (B)', style: GoogleFonts.poppins(color: const Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _teamBController,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.cardDark,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _teamBColor,
                            dropdownColor: AppTheme.cardDark,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.cardDark,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: _teamColors.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.poppins(color: Colors.white, fontSize: 11)))).toList(),
                            onChanged: (v) => setState(() => _teamBColor = v ?? _teamBColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 6. Date & Time Selection
                Text('Date & Schedule', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, color: AppTheme.primaryGreen, size: 18),
                              const SizedBox(width: 8),
                              Text(DateFormat('dd MMM yyyy').format(_matchDate), style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule, color: AppTheme.primaryGreen, size: 18),
                              const SizedBox(width: 8),
                              Text(_matchTime.format(context), style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 7. Players Count & Skill Level
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Max Players', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textGrey, size: 20),
                                  onPressed: () {
                                    if (_playersCount > 2) setState(() => _playersCount--);
                                  },
                                ),
                                Text('$_playersCount', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen, size: 20),
                                  onPressed: () {
                                    if (_playersCount < 30) setState(() => _playersCount++);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Skill Level', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _level,
                                isExpanded: true,
                                dropdownColor: AppTheme.cardDark,
                                items: ['Beginner', 'Intermediate', 'Advanced', 'All Levels']
                                    .map((l) => DropdownMenuItem(value: l, child: Text(l, style: GoogleFonts.poppins(color: Colors.white, fontSize: 12))))
                                    .toList(),
                                onChanged: (v) => setState(() => _level = v ?? _level),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 8. Fee per player
                Text('Price per Player (₹)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _feeController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.currency_rupee, color: AppTheme.primaryGreen, size: 18),
                    hintText: 'e.g. 150 (Leave 0 for Free Match)',
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.cardBorder)),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitCreateMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(
                            'Create Match & Open Scoreboard',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sportChip(String label, IconData icon) {
    final isSelected = _selectedSport == label;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black : AppTheme.primaryGreen),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.poppins(color: isSelected ? Colors.black : Colors.white, fontSize: 11)),
          ],
        ),
        selectedColor: AppTheme.primaryGreen,
        backgroundColor: AppTheme.cardDark,
        onSelected: (v) => _onSportChanged(label),
      ),
    );
  }
}
