import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class TournamentRegisterScreen extends StatefulWidget {
  final Map<String, dynamic>? tournament;

  const TournamentRegisterScreen({super.key, this.tournament});

  @override
  State<TournamentRegisterScreen> createState() => _TournamentRegisterScreenState();
}

class _TournamentPlayerItem {
  final TextEditingController nameController;
  final TextEditingController jerseyController;
  final TextEditingController phoneController;
  String role;

  _TournamentPlayerItem({
    required String name,
    required this.role,
    String jersey = '',
    String phone = '',
  })  : nameController = TextEditingController(text: name),
        jerseyController = TextEditingController(text: jersey),
        phoneController = TextEditingController(text: phone);

  void dispose() {
    nameController.dispose();
    jerseyController.dispose();
    phoneController.dispose();
  }
}

class _TournamentRegisterScreenState extends State<TournamentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Team Details
  late final TextEditingController _teamNameController;
  late final TextEditingController _teamTagController;
  String _selectedSkillLevel = 'Intermediate / Club';
  String _selectedJerseyColor = 'Neon Green';

  // Captain & Contact Details
  late final TextEditingController _captainNameController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _emergencyContactController;

  // Extra Options ("and etc option")
  bool _requestLockerRoom = true;
  bool _requestVideoHighlights = false;
  bool _requestMatchBibs = false;
  bool _requestParkingSlots = true;
  late final TextEditingController _specialRequestsController;

  // Squad Members
  final List<_TournamentPlayerItem> _players = [];

  final List<String> _jerseyColors = [
    'Neon Green',
    'Royal Blue',
    'Fire Red',
    'Sun Yellow',
    'Midnight Black',
    'Clean White',
    'Purple',
    'Orange',
  ];

  final List<String> _skillLevels = [
    'Beginner / Casual',
    'Intermediate / Club',
    'Advanced / Semi-Pro',
    'Pro / League',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.tournament ?? {};
    final sport = (t['sport'] as String?)?.toLowerCase() ?? 'football';

    _teamNameController = TextEditingController(text: 'Thunder Strikers FC');
    _teamTagController = TextEditingController(text: 'TSF');
    _captainNameController = TextEditingController(text: 'Rahul Sharma');
    _contactPhoneController = TextEditingController(text: '+91 98765 43210');
    _contactEmailController = TextEditingController(text: 'rahul.sharma@gmail.com');
    _emergencyContactController = TextEditingController(text: '+91 91234 56789');
    _specialRequestsController = TextEditingController();

    _initializeDefaultPlayers(sport);
  }

  void _initializeDefaultPlayers(String sport) {
    if (sport == 'cricket') {
      _players.addAll([
        _TournamentPlayerItem(name: 'Rahul Sharma', role: 'Captain (Batsman)', jersey: '7'),
        _TournamentPlayerItem(name: 'Karthik Rao', role: 'Vice Captain (All-Rounder)', jersey: '18'),
        _TournamentPlayerItem(name: 'Aditya Nair', role: 'Wicket-Keeper', jersey: '1'),
        _TournamentPlayerItem(name: 'Siddharth M.', role: 'Fast Bowler', jersey: '24'),
        _TournamentPlayerItem(name: 'Manish Kumar', role: 'Spinner', jersey: '99'),
        _TournamentPlayerItem(name: 'Arjun Das', role: 'Middle-Order Batsman', jersey: '45'),
        _TournamentPlayerItem(name: 'Sameer Khan', role: 'Finisher / All-Rounder', jersey: '11'),
      ]);
    } else if (sport == 'badminton' || sport == 'tennis') {
      _players.addAll([
        _TournamentPlayerItem(name: 'Rahul Sharma', role: 'Captain / Main Player', jersey: '1'),
        _TournamentPlayerItem(name: 'Karthik Rao', role: 'Doubles Partner', jersey: '2'),
        _TournamentPlayerItem(name: 'Siddharth M.', role: 'Substitute / Reserve', jersey: '3'),
      ]);
    } else {
      // Default Football / Other
      _players.addAll([
        _TournamentPlayerItem(name: 'Rahul Sharma', role: 'Captain (Striker)', jersey: '10'),
        _TournamentPlayerItem(name: 'Karthik Rao', role: 'Vice Captain (Midfielder)', jersey: '8'),
        _TournamentPlayerItem(name: 'Aditya Nair', role: 'Goalkeeper', jersey: '1'),
        _TournamentPlayerItem(name: 'Siddharth M.', role: 'Center Back', jersey: '4'),
        _TournamentPlayerItem(name: 'Manish Kumar', role: 'Winger', jersey: '7'),
        _TournamentPlayerItem(name: 'Arjun Das', role: 'Defender', jersey: '3'),
      ]);
    }
  }

  List<String> _getRolesForSport(String sport) {
    if (sport == 'cricket') {
      return [
        'Captain (Batsman)',
        'Vice Captain (All-Rounder)',
        'Batsman',
        'Fast Bowler',
        'Spinner',
        'All-Rounder',
        'Wicket-Keeper',
        'Substitute',
      ];
    } else if (sport == 'badminton' || sport == 'tennis') {
      return [
        'Captain / Main Player',
        'Doubles Partner',
        'Singles Player',
        'Substitute / Reserve',
      ];
    } else {
      return [
        'Captain (Striker)',
        'Vice Captain (Midfielder)',
        'Striker / Forward',
        'Midfielder',
        'Center Back',
        'Full Back / Wing Back',
        'Goalkeeper',
        'Substitute',
      ];
    }
  }

  void _addPlayer() {
    final sport = (widget.tournament?['sport'] as String?)?.toLowerCase() ?? 'football';
    final roles = _getRolesForSport(sport);
    final nextNum = _players.length + 1;
    setState(() {
      _players.add(
        _TournamentPlayerItem(
          name: '',
          role: roles.length > 2 ? roles[2] : 'Player',
          jersey: '$nextNum',
        ),
      );
    });
  }

  void _removePlayer(int index) {
    if (_players.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 squad members are required for tournament registration.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      final item = _players.removeAt(index);
      item.dispose();
    });
  }

  void _autoFillFullSquad() {
    final sport = (widget.tournament?['sport'] as String?)?.toLowerCase() ?? 'football';
    setState(() {
      for (final p in _players) {
        p.dispose();
      }
      _players.clear();
      _initializeDefaultPlayers(sport);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Squad roster populated with recommended roles and numbers!'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _proceedToRules() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required team and captain information.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Check player names
    for (int i = 0; i < _players.length; i++) {
      if (_players[i].nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter the name for Player #${i + 1}.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    final squadRoster = _players.map((p) => {
      'name': p.nameController.text.trim(),
      'role': p.role,
      'jersey': p.jerseyController.text.trim().isNotEmpty ? p.jerseyController.text.trim() : '-',
      'phone': p.phoneController.text.trim(),
    }).toList();

    final registrationData = {
      'tournament': widget.tournament,
      'teamName': _teamNameController.text.trim(),
      'teamTag': _teamTagController.text.trim().toUpperCase(),
      'jerseyColor': _selectedJerseyColor,
      'skillLevel': _selectedSkillLevel,
      'captainName': _captainNameController.text.trim(),
      'contactPhone': _contactPhoneController.text.trim(),
      'contactEmail': _contactEmailController.text.trim(),
      'emergencyContact': _emergencyContactController.text.trim(),
      'players': squadRoster,
      'playerCount': squadRoster.length,
      'options': {
        'requestLockerRoom': _requestLockerRoom,
        'requestVideoHighlights': _requestVideoHighlights,
        'requestMatchBibs': _requestMatchBibs,
        'requestParkingSlots': _requestParkingSlots,
        'specialNotes': _specialRequestsController.text.trim(),
      },
    };

    context.push('/tournament-rules', extra: registrationData);
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _teamTagController.dispose();
    _captainNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _emergencyContactController.dispose();
    _specialRequestsController.dispose();
    for (final p in _players) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament ?? {};
    final tournName = t['name'] as String? ?? 'Tournament Championship';
    final sport = t['sport'] as String? ?? 'Football';
    final venue = t['venue'] as String? ?? 'Play Arena, Bangalore';
    final dates = t['dates'] as String? ?? 'Upcoming Weekend';
    final entryFee = t['entryFee'] as String? ?? 'Free Entry';
    final format = t['format'] as String? ?? 'Knockout Stage';
    final sportIcon = (t['sportIcon'] as IconData?) ?? Icons.emoji_events;
    final accentColor = (t['accentColor'] as Color?) ?? AppTheme.primaryGreen;

    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1711),
        title: Text(
          'Tournament Registration',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Step 1 of 2',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tournament Overview Header Card
                      _buildTournamentHeaderCard(
                        tournName: tournName,
                        sport: sport,
                        venue: venue,
                        dates: dates,
                        format: format,
                        entryFee: entryFee,
                        sportIcon: sportIcon,
                        accentColor: accentColor,
                      ),

                      const SizedBox(height: 20),

                      // Section 1: Team & Club Details
                      _buildSectionHeader('1. TEAM & SQUAD DETAILS', Icons.shield_outlined),
                      const SizedBox(height: 12),
                      _buildTeamDetailsCard(),

                      const SizedBox(height: 22),

                      // Section 2: Captain & Management Contact
                      _buildSectionHeader('2. CAPTAIN & CONTACT INFO', Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildCaptainDetailsCard(),

                      const SizedBox(height: 22),

                      // Section 3: Adding Team Members
                      _buildMembersSectionHeader(sport),
                      const SizedBox(height: 12),
                      _buildSquadMembersList(sport),

                      const SizedBox(height: 22),

                      // Section 4: Extra Options ("and etc option")
                      _buildSectionHeader('4. ADDITIONAL OPTIONS & PREFERENCES', Icons.tune),
                      const SizedBox(height: 12),
                      _buildExtraOptionsCard(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // Bottom Sticky Proceed Bar
              _buildBottomActionBar(entryFee),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentHeaderCard({
    required String tournName,
    required String sport,
    required String venue,
    required String dates,
    required String format,
    required String entryFee,
    required IconData sportIcon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101C14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(sportIcon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$sport • $format',
                      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF8DA394)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.6)),
                ),
                child: Text(
                  entryFee,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFF1F3526), height: 22),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.primaryGreen),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  venue,
                  style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFFC7D7CD)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.amber),
              const SizedBox(width: 6),
              Text(
                dates,
                style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFFC7D7CD)),
              ),
            ],
          ),
        ],
      ),
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
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSectionHeader(String sport) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.group_outlined, size: 16, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Text(
              '3. SQUAD MEMBERS (${_players.length} ADDED)',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        InkWell(
          onTap: _autoFillFullSquad,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.auto_fix_high, size: 13, color: AppTheme.primaryGreen),
                const SizedBox(width: 4),
                Text(
                  'Auto-fill Squad',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
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

  Widget _buildTeamDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1812),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B2B20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team Name *', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _teamNameController,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter team name' : null,
                      decoration: InputDecoration(
                        hintText: 'e.g. Thunder Strikers',
                        hintStyle: GoogleFonts.poppins(color: Colors.white30, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF16251C),
                        prefixIcon: const Icon(Icons.shield_outlined, color: AppTheme.primaryGreen, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tag / Abbr', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _teamTagController,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      maxLength: 4,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'TSF',
                        hintStyle: GoogleFonts.poppins(color: Colors.white30, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF16251C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Jersey Color
          Text('Primary Jersey Color', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF16251C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedJerseyColor,
                dropdownColor: const Color(0xFF101B14),
                isExpanded: true,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                items: _jerseyColors
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getColorFromName(c),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(c),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedJerseyColor = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Skill Level
          Text('Team Competition Level', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF16251C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSkillLevel,
                dropdownColor: const Color(0xFF101B14),
                isExpanded: true,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                items: _skillLevels
                    .map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSkillLevel = val);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorFromName(String name) {
    switch (name) {
      case 'Neon Green':
        return AppTheme.primaryGreen;
      case 'Royal Blue':
        return Colors.blueAccent;
      case 'Fire Red':
        return Colors.redAccent;
      case 'Sun Yellow':
        return Colors.amber;
      case 'Midnight Black':
        return Colors.grey.shade800;
      case 'Clean White':
        return Colors.white;
      case 'Purple':
        return Colors.purpleAccent;
      case 'Orange':
        return Colors.deepOrangeAccent;
      default:
        return AppTheme.primaryGreen;
    }
  }

  Widget _buildCaptainDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1812),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B2B20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Captain / Team Leader Full Name *', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _captainNameController,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
            validator: (val) => val == null || val.trim().isEmpty ? 'Enter captain name' : null,
            decoration: InputDecoration(
              hintText: 'e.g. John Doe',
              filled: true,
              fillColor: const Color(0xFF16251C),
              prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryGreen, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contact Phone *', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _contactPhoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      decoration: InputDecoration(
                        hintText: '+91 98765 43210',
                        filled: true,
                        fillColor: const Color(0xFF16251C),
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.primaryGreen, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Emergency Phone', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emergencyContactController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '+91 91234 56789',
                        filled: true,
                        fillColor: const Color(0xFF16251C),
                        prefixIcon: const Icon(Icons.emergency_outlined, color: Colors.orange, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text('Official Notification Email', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _contactEmailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'captain@domain.com',
              filled: true,
              fillColor: const Color(0xFF16251C),
              prefixIcon: const Icon(Icons.mail_outline, color: AppTheme.primaryGreen, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadMembersList(String sport) {
    final availableRoles = _getRolesForSport(sport.toLowerCase());

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _players.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, index) {
            final player = _players[index];
            final isCaptain = index == 0;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1812),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCaptain ? AppTheme.primaryGreen.withValues(alpha: 0.5) : const Color(0xFF1B2B20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isCaptain ? AppTheme.primaryGreen : const Color(0xFF1A2F22),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isCaptain ? 'CAPTAIN' : 'PLAYER #${index + 1}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCaptain ? Colors.black : AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                          if (isCaptain) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                          ],
                        ],
                      ),
                      if (!isCaptain)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _removePlayer(index),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Player Name & Jersey Row
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: player.nameController,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: isCaptain ? 'Captain Name' : 'Player Name',
                            hintStyle: GoogleFonts.poppins(color: Colors.white30, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF16251C),
                            prefixIcon: const Icon(Icons.person, color: AppTheme.textGrey, size: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: player.jerseyController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: '#',
                            hintStyle: GoogleFonts.poppins(color: Colors.white30, fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF16251C),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Position / Role Selection
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16251C),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: availableRoles.contains(player.role) ? player.role : availableRoles.first,
                        dropdownColor: const Color(0xFF101B14),
                        isExpanded: true,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                        items: availableRoles
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (newRole) {
                          if (newRole != null) {
                            setState(() => player.role = newRole);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        // Add Member Button
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: _addPlayer,
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen, size: 18),
            label: Text(
              '+ Add Team Member',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.5), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.05),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExtraOptionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1812),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1B2B20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOptionSwitch(
            title: 'Dedicated Team Dugout & Locker Access',
            subtitle: 'Secure lockers and shaded team bench during matches',
            value: _requestLockerRoom,
            onChanged: (val) => setState(() => _requestLockerRoom = val),
          ),
          const Divider(color: Color(0xFF18281C), height: 20),
          _buildOptionSwitch(
            title: 'Team Parking Slots Reserved',
            subtitle: 'Guaranteed parking spaces near turf entrance for squad',
            value: _requestParkingSlots,
            onChanged: (val) => setState(() => _requestParkingSlots = val),
          ),
          const Divider(color: Color(0xFF18281C), height: 20),
          _buildOptionSwitch(
            title: 'Official Match Bibs & Training Balls',
            subtitle: 'Complimentary match bib set and warm-up balls provided',
            value: _requestMatchBibs,
            onChanged: (val) => setState(() => _requestMatchBibs = val),
          ),
          const Divider(color: Color(0xFF18281C), height: 20),
          _buildOptionSwitch(
            title: 'Match Highlights & Video Recording',
            subtitle: 'Full HD multi-angle match recording delivered post-game',
            value: _requestVideoHighlights,
            onChanged: (val) => setState(() => _requestVideoHighlights = val),
          ),
          const SizedBox(height: 14),

          Text('Special Requests & Team Notes (Optional)', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _specialRequestsController,
            maxLines: 2,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'e.g. Early warm-up slot required, team hydration kit, medical notes...',
              hintStyle: GoogleFonts.poppins(color: Colors.white30, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF16251C),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF8DA394)),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryGreen,
          activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar(String entryFee) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C140E),
        border: const Border(top: BorderSide(color: Color(0xFF1A2B1F), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tournament Entry Fee',
                style: GoogleFonts.poppins(fontSize: 10.5, color: AppTheme.textGrey),
              ),
              Text(
                entryFee,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _proceedToRules,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.black),
                label: Text(
                  'Continue to Rules',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
