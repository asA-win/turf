import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class ScoreboardSetupScreen extends StatefulWidget {
  final Map<String, dynamic>? initialConfig;

  const ScoreboardSetupScreen({super.key, this.initialConfig});

  @override
  State<ScoreboardSetupScreen> createState() => _ScoreboardSetupScreenState();
}

class _ScoreboardSetupScreenState extends State<ScoreboardSetupScreen> {
  late String _selectedSport;
  late final TextEditingController _venueController;
  late final TextEditingController _teamANameController;
  late final TextEditingController _teamBNameController;

  // Add member controllers
  final TextEditingController _playerANameController = TextEditingController();
  final TextEditingController _playerAJerseyController = TextEditingController();
  final TextEditingController _playerBNameController = TextEditingController();
  final TextEditingController _playerBJerseyController = TextEditingController();

  late String _selectedRoleA;
  late String _selectedRoleB;

  Color _teamAColor = const Color(0xFF00E676);
  Color _teamBColor = const Color(0xFF00E5FF);

  final List<Map<String, dynamic>> _teamAMembers = [];
  final List<Map<String, dynamic>> _teamBMembers = [];

  // Match settings
  int _cricketOvers = 8;
  int _footballHalfMinutes = 20;
  int _badmintonPoints = 21;
  int _basketballQuarterMinutes = 10;

  final List<Map<String, dynamic>> _sports = [
    {
      'id': 'football',
      'name': 'Football',
      'icon': Icons.sports_soccer_rounded,
      'color': const Color(0xFF00E676),
      'subtitle': 'Goals, Halves, Fouls & Cards',
      'defaultA': 'Turf Titans',
      'defaultB': 'Kickers United',
    },
    {
      'id': 'cricket',
      'name': 'Box Cricket',
      'icon': Icons.sports_cricket_rounded,
      'color': const Color(0xFFFFA000),
      'subtitle': 'Runs, Overs, Wickets & Extras',
      'defaultA': 'Royal Strikers',
      'defaultB': 'Blasters XI',
    },
    {
      'id': 'badminton',
      'name': 'Badminton',
      'icon': Icons.sports_tennis_rounded,
      'color': const Color(0xFF29B6F6),
      'subtitle': 'Sets, Rally Points & Service',
      'defaultA': 'Smashers Alpha',
      'defaultB': 'Shuttle Masters',
    },
    {
      'id': 'basketball',
      'name': 'Basketball',
      'icon': Icons.sports_basketball_rounded,
      'color': const Color(0xFFFF7043),
      'subtitle': '1pt, 2pt, 3pt & Quarters',
      'defaultA': 'Hoop Kings',
      'defaultB': 'Dunkers United',
    },
    {
      'id': 'tennis',
      'name': 'Tennis',
      'icon': Icons.sports_handball_rounded,
      'color': const Color(0xFFAB47BC),
      'subtitle': 'Sets, Games & Rally points',
      'defaultA': 'Ace Aces',
      'defaultB': 'Spin Wizards',
    },
  ];

  final List<Color> _colorOptions = [
    const Color(0xFF00E676), // Green
    const Color(0xFF00E5FF), // Cyan
    const Color(0xFFFF5252), // Red
    const Color(0xFFFFD600), // Gold
    const Color(0xFFE040FB), // Purple
    const Color(0xFFFF6E40), // Orange
    const Color(0xFF448AFF), // Blue
  ];

  List<String> get _currentRoles {
    switch (_selectedSport) {
      case 'cricket':
        return ['Batsman', 'Bowler', 'All-Rounder', 'Wicket-Keeper', 'Captain'];
      case 'basketball':
        return ['Point Guard', 'Shooting Guard', 'Small Forward', 'Power Forward', 'Center'];
      case 'badminton':
      case 'tennis':
        return ['Singles Player', 'Doubles Partner', 'Captain'];
      case 'football':
      default:
        return ['Striker', 'Midfielder', 'Defender', 'Goalkeeper', 'Captain', 'Substitute'];
    }
  }

  @override
  void initState() {
    super.initState();
    final cfg = widget.initialConfig ?? {};
    _selectedSport = (cfg['sport'] as String?)?.toLowerCase() ?? 'football';
    _venueController = TextEditingController(
      text: (cfg['turfName'] as String?) ?? 'Play Arena - Koramangala',
    );

    final sportMeta = _sports.firstWhere(
      (s) => s['id'] == _selectedSport,
      orElse: () => _sports.first,
    );

    _teamANameController = TextEditingController(
      text: (cfg['teamA'] as String?) ?? (sportMeta['defaultA'] as String),
    );
    _teamBNameController = TextEditingController(
      text: (cfg['teamB'] as String?) ?? (sportMeta['defaultB'] as String),
    );

    _selectedRoleA = _currentRoles.first;
    _selectedRoleB = _currentRoles.first;

    // Prefill sample members if requested or none provided
    _seedInitialSampleMembers();
  }

  void _seedInitialSampleMembers() {
    if (_selectedSport == 'football') {
      _teamAMembers.addAll([
        {'name': 'Rahul Sharma', 'role': 'Striker', 'number': '10'},
        {'name': 'Vikram Rathore', 'role': 'Midfielder', 'number': '7'},
        {'name': 'Samson Davis', 'role': 'Defender', 'number': '4'},
        {'name': 'Karan Mehta', 'role': 'Goalkeeper', 'number': '1'},
      ]);
      _teamBMembers.addAll([
        {'name': 'Harsh Varma', 'role': 'Striker', 'number': '9'},
        {'name': 'David Miller', 'role': 'Midfielder', 'number': '8'},
        {'name': 'Aditya Rao', 'role': 'Defender', 'number': '3'},
        {'name': 'Tanmay Roy', 'role': 'Goalkeeper', 'number': '12'},
      ]);
    } else if (_selectedSport == 'cricket') {
      _teamAMembers.addAll([
        {'name': 'Rohit Sen', 'role': 'Captain', 'number': '45'},
        {'name': 'Arun Kumar', 'role': 'Batsman', 'number': '18'},
        {'name': 'Kiran Patel', 'role': 'All-Rounder', 'number': '7'},
        {'name': 'Jasprit Singh', 'role': 'Bowler', 'number': '93'},
      ]);
      _teamBMembers.addAll([
        {'name': 'Virat Joshi', 'role': 'Captain', 'number': '18'},
        {'name': 'Shikhar D.', 'role': 'Batsman', 'number': '25'},
        {'name': 'Hardik R.', 'role': 'All-Rounder', 'number': '33'},
        {'name': 'Mohammad S.', 'role': 'Bowler', 'number': '11'},
      ]);
    } else {
      _teamAMembers.addAll([
        {'name': 'Player 1', 'role': _currentRoles[0], 'number': '1'},
        {'name': 'Player 2', 'role': _currentRoles.length > 1 ? _currentRoles[1] : _currentRoles[0], 'number': '2'},
      ]);
      _teamBMembers.addAll([
        {'name': 'Opponent 1', 'role': _currentRoles[0], 'number': '1'},
        {'name': 'Opponent 2', 'role': _currentRoles.length > 1 ? _currentRoles[1] : _currentRoles[0], 'number': '2'},
      ]);
    }
  }

  void _onSportChanged(String sportId) {
    setState(() {
      _selectedSport = sportId;
      _selectedRoleA = _currentRoles.first;
      _selectedRoleB = _currentRoles.first;

      final sportMeta = _sports.firstWhere((s) => s['id'] == sportId);
      _teamANameController.text = sportMeta['defaultA'] as String;
      _teamBNameController.text = sportMeta['defaultB'] as String;

      _teamAMembers.clear();
      _teamBMembers.clear();
      _seedInitialSampleMembers();
    });
  }

  @override
  void dispose() {
    _venueController.dispose();
    _teamANameController.dispose();
    _teamBNameController.dispose();
    _playerANameController.dispose();
    _playerAJerseyController.dispose();
    _playerBNameController.dispose();
    _playerBJerseyController.dispose();
    super.dispose();
  }

  void _addPlayerA() {
    final name = _playerANameController.text.trim();
    if (name.isEmpty) {
      _showToast('Please enter member name');
      return;
    }
    setState(() {
      _teamAMembers.add({
        'name': name,
        'role': _selectedRoleA,
        'number': _playerAJerseyController.text.trim().isEmpty
            ? '${_teamAMembers.length + 1}'
            : _playerAJerseyController.text.trim(),
      });
      _playerANameController.clear();
      _playerAJerseyController.clear();
    });
    HapticFeedback.lightImpact();
  }

  void _addPlayerB() {
    final name = _playerBNameController.text.trim();
    if (name.isEmpty) {
      _showToast('Please enter member name');
      return;
    }
    setState(() {
      _teamBMembers.add({
        'name': name,
        'role': _selectedRoleB,
        'number': _playerBJerseyController.text.trim().isEmpty
            ? '${_teamBMembers.length + 1}'
            : _playerBJerseyController.text.trim(),
      });
      _playerBNameController.clear();
      _playerBJerseyController.clear();
    });
    HapticFeedback.lightImpact();
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
        backgroundColor: const Color(0xFF1E2C22),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _launchScoreboard() {
    final teamA = _teamANameController.text.trim().isEmpty ? 'Team A' : _teamANameController.text.trim();
    final teamB = _teamBNameController.text.trim().isEmpty ? 'Team B' : _teamBNameController.text.trim();
    final turfName = _venueController.text.trim().isEmpty ? 'Greenfield Turf' : _venueController.text.trim();

    final config = <String, dynamic>{
      'sport': _selectedSport,
      'turfName': turfName,
      'teamA': teamA,
      'teamB': teamB,
      'teamAColor': _teamAColor.toARGB32(),
      'teamBColor': _teamBColor.toARGB32(),
      'teamAMembers': List<Map<String, dynamic>>.from(_teamAMembers),
      'teamBMembers': List<Map<String, dynamic>>.from(_teamBMembers),
      'cricketOvers': _cricketOvers,
      'footballHalfMinutes': _footballHalfMinutes,
      'badmintonPoints': _badmintonPoints,
      'basketballQuarterMinutes': _basketballQuarterMinutes,
      'isViewOnly': false,
    };

    context.push('/scoreboard', extra: config);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B08),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scoreboard Setup',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Add teams, members & track live scores',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF8E9E94),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryGreen),
            tooltip: 'Reset to Defaults',
            onPressed: () => _onSportChanged(_selectedSport),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset + 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sport Selector Header
              _buildSectionHeader('1. SELECT SPORT', Icons.sports_score_rounded),
              const SizedBox(height: 10),
              _buildSportSelector(),
              const SizedBox(height: 22),

              // 2. Venue / Turf Name
              _buildSectionHeader('2. TURF / VENUE', Icons.location_on_outlined),
              const SizedBox(height: 8),
              _buildVenueField(),
              const SizedBox(height: 22),

              // 3. Team A Setup (Name, Color & Members)
              _buildTeamSetupCard(
                teamLabel: 'TEAM A',
                nameController: _teamANameController,
                currentColor: _teamAColor,
                onColorChanged: (c) => setState(() => _teamAColor = c),
                members: _teamAMembers,
                playerNameController: _playerANameController,
                playerJerseyController: _playerAJerseyController,
                selectedRole: _selectedRoleA,
                onRoleChanged: (r) => setState(() => _selectedRoleA = r),
                onAddPlayer: _addPlayerA,
                onRemovePlayer: (idx) => setState(() => _teamAMembers.removeAt(idx)),
                accentColor: _teamAColor,
              ),
              const SizedBox(height: 20),

              // VS Divider Pill
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101912),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1F2F23)),
                  ),
                  child: Text(
                    'VS MATCHUP',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Team B Setup (Name, Color & Members)
              _buildTeamSetupCard(
                teamLabel: 'TEAM B',
                nameController: _teamBNameController,
                currentColor: _teamBColor,
                onColorChanged: (c) => setState(() => _teamBColor = c),
                members: _teamBMembers,
                playerNameController: _playerBNameController,
                playerJerseyController: _playerBJerseyController,
                selectedRole: _selectedRoleB,
                onRoleChanged: (r) => setState(() => _selectedRoleB = r),
                onAddPlayer: _addPlayerB,
                onRemovePlayer: (idx) => setState(() => _teamBMembers.removeAt(idx)),
                accentColor: _teamBColor,
              ),
              const SizedBox(height: 22),

              // 5. Match Format / Sport Rules
              _buildSectionHeader('3. MATCH FORMAT & RULES', Icons.tune_rounded),
              const SizedBox(height: 10),
              _buildMatchFormatSettings(),
            ],
          ),
        ),
      ),
      bottomSheet: _buildBottomLaunchBar(),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppTheme.primaryGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSportSelector() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _sports.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final s = _sports[index];
          final isSelected = _selectedSport == s['id'];
          final color = s['color'] as Color;

          return GestureDetector(
            onTap: () => _onSportChanged(s['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 110,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : const Color(0xFF101912),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFF1F2F23),
                  width: isSelected ? 1.8 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isSelected ? 0.3 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(s['icon'] as IconData, color: color, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF9EABA2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVenueField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2F23)),
      ),
      child: TextField(
        controller: _venueController,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.5),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.stadium_rounded, color: AppTheme.primaryGreen, size: 20),
          hintText: 'Enter turf or arena name',
          hintStyle: GoogleFonts.poppins(color: const Color(0xFF6F8275), fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTeamSetupCard({
    required String teamLabel,
    required TextEditingController nameController,
    required Color currentColor,
    required ValueChanged<Color> onColorChanged,
    required List<Map<String, dynamic>> members,
    required TextEditingController playerNameController,
    required TextEditingController playerJerseyController,
    required String selectedRole,
    required ValueChanged<String> onRoleChanged,
    required VoidCallback onAddPlayer,
    required ValueChanged<int> onRemovePlayer,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: currentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: currentColor.withValues(alpha: 0.5), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                teamLabel,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${members.length} Members',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Team Name Input
          TextField(
            controller: nameController,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF09120B),
              hintText: 'Enter Team Name',
              hintStyle: GoogleFonts.poppins(color: const Color(0xFF5E7064), fontSize: 13),
              prefixIcon: Icon(Icons.shield_rounded, color: accentColor, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1B2B1F)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Team Color Palette Selector
          Row(
            children: [
              Text(
                'Jersey Color:',
                style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8E9E94)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colorOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final c = _colorOptions[i];
                      final isSelected = currentColor == c;
                      return GestureDetector(
                        onTap: () => onColorChanged(c),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 14, color: Colors.black)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1B2B1F), height: 1),
          const SizedBox(height: 14),

          // Add Member Section Subhead
          Text(
            'ADD MEMBERS / PLAYERS',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: const Color(0xFF8E9E94),
            ),
          ),
          const SizedBox(height: 10),

          // Input Row: Name + Jersey Number
          Row(
            children: [
              Expanded(
                flex: 5,
                child: TextField(
                  controller: playerNameController,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF09120B),
                    hintText: 'Player Name (e.g. Alex)',
                    hintStyle: GoogleFonts.poppins(color: const Color(0xFF5E7064), fontSize: 12),
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF6F8275), size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF1B2B1F)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: accentColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: playerJerseyController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF09120B),
                    hintText: '# Jersey',
                    hintStyle: GoogleFonts.poppins(color: const Color(0xFF5E7064), fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF1B2B1F)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: accentColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Role dropdown + Add Member Button Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09120B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1B2B1F)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF101912),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8E9E94)),
                      items: _currentRoles.map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(
                            role,
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) onRoleChanged(val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onAddPlayer,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: Colors.black),
                label: Text(
                  'Add',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  elevation: 0,
                  minimumSize: const Size(80, 42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Member Roster List
          if (members.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text(
                'No members added yet.\nType above to add players to this squad.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF6F8275)),
              ),
            )
          else
            Column(
              children: List.generate(members.length, (idx) {
                final m = members[idx];
                final role = m['role'] ?? 'Player';
                final num = m['number']?.toString() ?? '${idx + 1}';

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09120B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1B2B1F)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          num,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['name'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              role,
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                color: const Color(0xFF8E9E94),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF6F8275), size: 18),
                        onPressed: () => onRemovePlayer(idx),
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchFormatSettings() {
    if (_selectedSport == 'cricket') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF101912),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2F23)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overs per Inning',
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8E9E94)),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [4, 6, 8, 10, 12, 15, 20].map((ov) {
                  final isSel = _cricketOvers == ov;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$ov Overs'),
                      selected: isSel,
                      onSelected: (val) {
                        if (val) setState(() => _cricketOvers = ov);
                      },
                      selectedColor: AppTheme.primaryGreen,
                      backgroundColor: const Color(0xFF09120B),
                      labelStyle: GoogleFonts.poppins(
                        color: isSel ? Colors.black : Colors.white,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        fontSize: 11.5,
                      ),
                      side: BorderSide(
                        color: isSel ? AppTheme.primaryGreen : const Color(0xFF1B2B1F),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    } else if (_selectedSport == 'football') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF101912),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2F23)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Minutes per Half',
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8E9E94)),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [10, 15, 20, 25, 30, 45].map((mins) {
                  final isSel = _footballHalfMinutes == mins;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$mins Mins'),
                      selected: isSel,
                      onSelected: (val) {
                        if (val) setState(() => _footballHalfMinutes = mins);
                      },
                      selectedColor: AppTheme.primaryGreen,
                      backgroundColor: const Color(0xFF09120B),
                      labelStyle: GoogleFonts.poppins(
                        color: isSel ? Colors.black : Colors.white,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        fontSize: 11.5,
                      ),
                      side: BorderSide(
                        color: isSel ? AppTheme.primaryGreen : const Color(0xFF1B2B1F),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    } else if (_selectedSport == 'badminton') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF101912),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F2F23)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Points per Set',
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8E9E94)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [11, 15, 21, 30].map((pts) {
                final isSel = _badmintonPoints == pts;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$pts Pts'),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) setState(() => _badmintonPoints = pts);
                    },
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: const Color(0xFF09120B),
                    labelStyle: GoogleFonts.poppins(
                      color: isSel ? Colors.black : Colors.white,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11.5,
                    ),
                    side: BorderSide(
                      color: isSel ? AppTheme.primaryGreen : const Color(0xFF1B2B1F),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101912),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2F23)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quarter / Game Duration',
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8E9E94)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [8, 10, 12].map((q) {
              final isSel = _basketballQuarterMinutes == q;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$q Mins'),
                  selected: isSel,
                  onSelected: (val) {
                    if (val) setState(() => _basketballQuarterMinutes = q);
                  },
                  selectedColor: AppTheme.primaryGreen,
                  backgroundColor: const Color(0xFF09120B),
                  labelStyle: GoogleFonts.poppins(
                    color: isSel ? Colors.black : Colors.white,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    fontSize: 11.5,
                  ),
                  side: BorderSide(
                    color: isSel ? AppTheme.primaryGreen : const Color(0xFF1B2B1F),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomLaunchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0F0B),
        border: Border(top: BorderSide(color: Color(0xFF1F2F23))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _launchScoreboard,
            icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.black, size: 22),
            label: Text(
              'Start Live Scoreboard',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              elevation: 4,
              shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}
