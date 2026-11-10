import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/providers/api_client.dart';
import 'package:turf_app/core/theme/app_theme.dart';
import 'package:turf_app/features/tournament/data/tournament_repository.dart';

class TournamentRulesScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? data;

  const TournamentRulesScreen({super.key, this.data});

  @override
  ConsumerState<TournamentRulesScreen> createState() => _TournamentRulesScreenState();
}

class _TournamentRulesScreenState extends ConsumerState<TournamentRulesScreen> {
  bool _agreedToRules = false;
  bool _agreedToSafetyAndConduct = false;
  bool _isRegistering = false;

  bool get _canProceed => _agreedToRules && _agreedToSafetyAndConduct;

  void _proceedToBooking() async {
    if (!_canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept all tournament rules and guidelines to proceed with booking.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isRegistering = true);

    final t = widget.data?['tournament'] as Map<String, dynamic>? ?? {};
    final tournId = t['id'] as String? ?? 'tourn_1';
    final tournName = t['name'] as String? ?? 'Tournament Championship';
    final venue = t['venue'] as String? ?? 'Play Arena, Bangalore';
    final feeAmount = (t['entryFeeAmount'] as num?)?.toInt() ?? 0;
    final teamName = widget.data?['teamName'] as String? ?? 'My Squad FC';
    final captain = widget.data?['captainName'] as String? ?? 'Captain';
    final players = widget.data?['players'] as List? ?? [];

    // Register team in TournamentRepository and backend
    await TournamentRepository.instance.registerTeamForTournament(tournId, {
      'teamName': teamName,
      'captainName': captain,
      'contactPhone': widget.data?['contactPhone'] ?? '+91 98765 43210',
      'teamTag': widget.data?['teamTag'] ?? 'MYT',
      'jerseyColor': widget.data?['jerseyColor'] ?? 'Neon Green',
      'skillLevel': widget.data?['skillLevel'] ?? 'Intermediate / Club',
      'registeredAt': 'Just now',
      'playersCount': players.length,
      'players': players,
      'isUserTeam': true,
      'rating': 4.8,
    }, dio: ref.read(dioClientProvider));

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isRegistering = false);

    if (feeAmount > 0) {
      // Paid entry fee: proceed to checkout / payment
      context.push('/checkout', extra: {
        'tournament': t,
        'teamName': teamName,
        'captainName': captain,
        'playersCount': players.length,
        'price': feeAmount.toDouble(),
        'isTournamentBooking': true,
      });
    } else {
      // Free tournament: show confirmed registration pass
      _showRegistrationSuccessDialog(t, tournId, tournName, teamName, captain, venue, players.length);
    }
  }

  void _showRegistrationSuccessDialog(
    Map<String, dynamic> t,
    String tournId,
    String tournName,
    String teamName,
    String captain,
    String venue,
    int playersCount,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F1B13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryGreen, width: 2.5),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGreen, size: 44),
              ),
              const SizedBox(height: 18),
              Text(
                'Registration & Booking Confirmed!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Team "$teamName" is officially registered for $tournName!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9EABA2)),
              ),
              const SizedBox(height: 18),

              // Summary Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF16251C),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF223A2A)),
                ),
                child: Column(
                  children: [
                    _buildDialogRow('Captain', captain),
                    const SizedBox(height: 6),
                    _buildDialogRow('Squad Size', '$playersCount Players Registered'),
                    const SizedBox(height: 6),
                    _buildDialogRow('Venue', venue),
                    const SizedBox(height: 6),
                    _buildDialogRow('Entry Fee', 'Free Entry (Confirmed)', isGreen: true),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final liveTourn = TournamentRepository.instance.getTournamentById(tournId) ?? t;
                    context.pushReplacement('/tournament-hub', extra: {
                      ...liveTourn,
                      'id': tournId,
                      'initialTab': 0, // Teams tab
                      'justRegistered': true,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'View Tournament Teams & Hub',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textGrey)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isGreen ? AppTheme.primaryGreen : Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.data?['tournament'] as Map<String, dynamic>? ?? {};
    final tournName = t['name'] as String? ?? 'Championship Cup';
    final sport = t['sport'] as String? ?? 'Football';
    final format = t['format'] as String? ?? 'Knockout';
    final entryFee = t['entryFee'] as String? ?? 'Free Entry';
    final feeAmount = (t['entryFeeAmount'] as num?)?.toInt() ?? 0;
    final teamName = widget.data?['teamName'] as String? ?? 'My Squad';
    final players = widget.data?['players'] as List? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF070B08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1711),
        title: Text(
          'Rules & Regulations',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
            ),
            child: Text(
              'Step 2 of 2',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF00E5FF)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team & Tournament Summary Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101C14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E3524)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  tournName,
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entryFee,
                                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.shield_outlined, size: 14, color: AppTheme.primaryGreen),
                              const SizedBox(width: 6),
                              Text(
                                'Registering: ',
                                style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textGrey),
                              ),
                              Text(
                                '$teamName (${players.length} Players)',
                                style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Guide Notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF132018),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppTheme.primaryGreen, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Please review the official tournament guidelines below. Accepting the rules is required to proceed with booking.',
                              style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFB4C8BA)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Official Rules Accordion / Cards
                    _buildRuleCard(
                      number: '1',
                      title: 'Tournament Format & Match Structure',
                      icon: Icons.emoji_events_outlined,
                      items: [
                        'Official $sport rules and regulations apply ($format).',
                        'Matches will strictly start according to fixture timings scheduled in tournament brackets.',
                        'In case of a tie in knockout matches, sudden-death tiebreakers (penalty shootout / super-over / golden point) will decide the winner.',
                        'Official referee / umpire decisions are final and binding on all teams.',
                      ],
                    ),

                    const SizedBox(height: 14),

                    _buildRuleCard(
                      number: '2',
                      title: 'Reporting Time & Walkover Policy',
                      icon: Icons.timer_outlined,
                      items: [
                        'All registered squad members must report at the venue reception 30 minutes prior to scheduled fixture.',
                        'A maximum grace period of 10 minutes will be given from scheduled kick-off.',
                        'If a team fails to field minimum players within grace period, a walkover (win awarded to opposing team) will be declared.',
                        'All players must carry a valid photo ID for verification.',
                      ],
                    ),

                    const SizedBox(height: 14),

                    _buildRuleCard(
                      number: '3',
                      title: 'Turf Footwear & Protective Equipment',
                      icon: Icons.sports_kabaddi_outlined,
                      items: [
                        'Only rubber-stud turf boots or flat sole sports shoes are permitted on artificial grass.',
                        'Strictly NO metal studs, spikes, or bare feet permitted at any time.',
                        'Shin guards are mandatory for football; helmets and protective pads mandatory for box cricket.',
                        'Official match balls and match bibs will be provided by tournament management.',
                      ],
                    ),

                    const SizedBox(height: 14),

                    _buildRuleCard(
                      number: '4',
                      title: 'Fair Play, Disciplinary Rules & Code of Conduct',
                      icon: Icons.gavel_outlined,
                      items: [
                        'Zero-tolerance policy towards abusive language, physical altercations, or arguing with match officials.',
                        'Yellow card penalty: 5-minute sin bin or ₹500 disciplinary fine.',
                        'Red card consequence: Immediate expulsion from current match and automatic suspension for subsequent match.',
                        'Severe misconduct will result in permanent tournament ban and forfeiture of all registration fees.',
                      ],
                    ),

                    const SizedBox(height: 14),

                    _buildRuleCard(
                      number: '5',
                      title: 'Squad Roster & Substitution Integrity',
                      icon: Icons.group_outlined,
                      items: [
                        'Only players registered in this official roster are eligible to play in tournament matches.',
                        'Playing unregistered ringers or external players will result in immediate disqualification of the entire team.',
                        'Rolling substitutions are permitted at referee stoppages as per sport rules.',
                      ],
                    ),

                    const SizedBox(height: 14),

                    _buildRuleCard(
                      number: '6',
                      title: 'Weather Protocol & Rescheduling',
                      icon: Icons.cloud_outlined,
                      items: [
                        'Matches will continue during light rain as turf facilities feature all-weather rapid drainage.',
                        'In case of extreme lightning or dangerous storm conditions, matches will be paused and rescheduled within 48 hours.',
                      ],
                    ),

                    const SizedBox(height: 14),

                    _buildRuleCard(
                      number: '7',
                      title: 'Booking, Cancellation & Refund Policy',
                      icon: Icons.payments_outlined,
                      items: [
                        'Tournament booking locks your team slot in the official championship draw.',
                        '100% refund available if cancellation is requested at least 72 hours prior to opening match.',
                        'Cancellations within 72 hours of tournament start are strictly non-refundable.',
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Interactive Agreement Checkboxes ("if they are ok with that rules they can proceed booking")
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1B12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _canProceed ? AppTheme.primaryGreen : Colors.orange.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _canProceed ? Icons.check_circle : Icons.rule,
                                color: _canProceed ? AppTheme.primaryGreen : Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'TOURNAMENT RULES AGREEMENT',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _canProceed ? AppTheme.primaryGreen : Colors.orange,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Checkbox 1
                          InkWell(
                            onTap: () => setState(() => _agreedToRules = !_agreedToRules),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _agreedToRules,
                                  onChanged: (val) => setState(() => _agreedToRules = val ?? false),
                                  activeColor: AppTheme.primaryGreen,
                                  checkColor: Colors.black,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      'I have read, understood, and agree to all Tournament Rules, Equipment Guidelines, and Walkover Policies.',
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, height: 1.4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Checkbox 2
                          InkWell(
                            onTap: () => setState(() => _agreedToSafetyAndConduct = !_agreedToSafetyAndConduct),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _agreedToSafetyAndConduct,
                                  onChanged: (val) => setState(() => _agreedToSafetyAndConduct = val ?? false),
                                  activeColor: AppTheme.primaryGreen,
                                  checkColor: Colors.black,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text(
                                      'I confirm all registered team members are medically fit, will follow fair play standards, and accept referee decisions as final.',
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, height: 1.4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Proceed to Booking Bar
            _buildProceedBookingBar(feeAmount, entryFee),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard({
    required String number,
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
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
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 16, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(Icons.circle, size: 5, color: AppTheme.primaryGreen),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFFB2C4B7), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProceedBookingBar(int feeAmount, String entryFee) {
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
                'Total Booking Fee',
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
                onPressed: _canProceed && !_isRegistering ? _proceedToBooking : null,
                icon: _isRegistering
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.lock_outline, size: 18, color: Colors.black),
                label: Text(
                  _canProceed
                      ? (feeAmount > 0 ? 'Proceed to Booking (₹$feeAmount)' : 'Accept Rules & Book (Free)')
                      : 'Accept Rules to Proceed',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canProceed ? AppTheme.primaryGreen : Colors.grey.shade700,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFF223528),
                  disabledForegroundColor: const Color(0xFF5B7463),
                  elevation: _canProceed ? 2 : 0,
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
