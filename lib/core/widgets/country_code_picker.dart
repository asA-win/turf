import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:turf_app/core/theme/app_theme.dart';

class Country {
  final String name;
  final String dialCode;
  final String flag;
  final String code;

  const Country({
    required this.name,
    required this.dialCode,
    required this.flag,
    required this.code,
  });
}

class Countries {
  static const Country defaultCountry = Country(
    name: 'India',
    dialCode: '+91',
    flag: '🇮🇳',
    code: 'IN',
  );

  static const List<Country> all = [
    Country(name: 'India', dialCode: '+91', flag: '🇮🇳', code: 'IN'),
    Country(name: 'United States', dialCode: '+1', flag: '🇺🇸', code: 'US'),
    Country(name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧', code: 'GB'),
    Country(name: 'United Arab Emirates', dialCode: '+971', flag: '🇦🇪', code: 'AE'),
    Country(name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦', code: 'SA'),
    Country(name: 'Qatar', dialCode: '+974', flag: '🇶🇦', code: 'QA'),
    Country(name: 'Kuwait', dialCode: '+965', flag: '🇰🇼', code: 'KW'),
    Country(name: 'Oman', dialCode: '+968', flag: '🇴🇲', code: 'OM'),
    Country(name: 'Bahrain', dialCode: '+973', flag: '🇧🇭', code: 'BH'),
    Country(name: 'Canada', dialCode: '+1', flag: '🇨🇦', code: 'CA'),
    Country(name: 'Australia', dialCode: '+61', flag: '🇦🇺', code: 'AU'),
    Country(name: 'Singapore', dialCode: '+65', flag: '🇸🇬', code: 'SG'),
    Country(name: 'Malaysia', dialCode: '+60', flag: '🇲🇾', code: 'MY'),
    Country(name: 'Germany', dialCode: '+49', flag: '🇩🇪', code: 'DE'),
    Country(name: 'France', dialCode: '+33', flag: '🇫🇷', code: 'FR'),
    Country(name: 'Italy', dialCode: '+39', flag: '🇮🇹', code: 'IT'),
    Country(name: 'Spain', dialCode: '+34', flag: '🇪🇸', code: 'ES'),
    Country(name: 'Pakistan', dialCode: '+92', flag: '🇵🇰', code: 'PK'),
    Country(name: 'Bangladesh', dialCode: '+880', flag: '🇧🇩', code: 'BD'),
    Country(name: 'Sri Lanka', dialCode: '+94', flag: '🇱🇰', code: 'LK'),
    Country(name: 'Nepal', dialCode: '+977', flag: '🇳🇵', code: 'NP'),
    Country(name: 'South Africa', dialCode: '+27', flag: '🇿🇦', code: 'ZA'),
    Country(name: 'Nigeria', dialCode: '+234', flag: '🇳🇬', code: 'NG'),
    Country(name: 'Kenya', dialCode: '+254', flag: '🇰🇪', code: 'KE'),
    Country(name: 'Egypt', dialCode: '+20', flag: '🇪🇬', code: 'EG'),
    Country(name: 'Brazil', dialCode: '+55', flag: '🇧🇷', code: 'BR'),
    Country(name: 'Argentina', dialCode: '+54', flag: '🇦🇷', code: 'AR'),
    Country(name: 'Japan', dialCode: '+81', flag: '🇯🇵', code: 'JP'),
    Country(name: 'South Korea', dialCode: '+82', flag: '🇰🇷', code: 'KR'),
    Country(name: 'China', dialCode: '+86', flag: '🇨🇳', code: 'CN'),
    Country(name: 'Hong Kong', dialCode: '+852', flag: '🇭🇰', code: 'HK'),
    Country(name: 'Taiwan', dialCode: '+886', flag: '🇹🇼', code: 'TW'),
    Country(name: 'Philippines', dialCode: '+63', flag: '🇵🇭', code: 'PH'),
    Country(name: 'Thailand', dialCode: '+66', flag: '🇹🇭', code: 'TH'),
    Country(name: 'Vietnam', dialCode: '+84', flag: '🇻🇳', code: 'VN'),
    Country(name: 'Indonesia', dialCode: '+62', flag: '🇮🇩', code: 'ID'),
    Country(name: 'Turkey', dialCode: '+90', flag: '🇹🇷', code: 'TR'),
    Country(name: 'Russia', dialCode: '+7', flag: '🇷🇺', code: 'RU'),
    Country(name: 'Mexico', dialCode: '+52', flag: '🇲🇽', code: 'MX'),
    Country(name: 'New Zealand', dialCode: '+64', flag: '🇳🇿', code: 'NZ'),
    Country(name: 'Ireland', dialCode: '+353', flag: '🇮🇪', code: 'IE'),
    Country(name: 'Netherlands', dialCode: '+31', flag: '🇳🇱', code: 'NL'),
    Country(name: 'Belgium', dialCode: '+32', flag: '🇧🇪', code: 'BE'),
    Country(name: 'Switzerland', dialCode: '+41', flag: '🇨🇭', code: 'CH'),
    Country(name: 'Sweden', dialCode: '+46', flag: '🇸🇪', code: 'SE'),
    Country(name: 'Norway', dialCode: '+47', flag: '🇳🇴', code: 'NO'),
    Country(name: 'Denmark', dialCode: '+45', flag: '🇩🇰', code: 'DK'),
    Country(name: 'Finland', dialCode: '+358', flag: '🇫🇮', code: 'FI'),
    Country(name: 'Poland', dialCode: '+48', flag: '🇵🇱', code: 'PL'),
    Country(name: 'Portugal', dialCode: '+351', flag: '🇵🇹', code: 'PT'),
    Country(name: 'Greece', dialCode: '+30', flag: '🇬🇷', code: 'GR'),
    Country(name: 'Austria', dialCode: '+43', flag: '🇦🇹', code: 'AT'),
    Country(name: 'Czech Republic', dialCode: '+420', flag: '🇨🇿', code: 'CZ'),
    Country(name: 'Hungary', dialCode: '+36', flag: '🇭🇺', code: 'HU'),
    Country(name: 'Romania', dialCode: '+40', flag: '🇷🇴', code: 'RO'),
    Country(name: 'Colombia', dialCode: '+57', flag: '🇨🇴', code: 'CO'),
    Country(name: 'Chile', dialCode: '+56', flag: '🇨🇱', code: 'CL'),
    Country(name: 'Peru', dialCode: '+51', flag: '🇵🇪', code: 'PE'),
    Country(name: 'Ghana', dialCode: '+233', flag: '🇬🇭', code: 'GH'),
    Country(name: 'Morocco', dialCode: '+212', flag: '🇲🇦', code: 'MA'),
    Country(name: 'Jordan', dialCode: '+962', flag: '🇯🇴', code: 'JO'),
    Country(name: 'Lebanon', dialCode: '+961', flag: '🇱🇧', code: 'LB'),
    Country(name: 'Iraq', dialCode: '+964', flag: '🇮🇶', code: 'IQ'),
    Country(name: 'Israel', dialCode: '+972', flag: '🇮🇱', code: 'IL'),
    Country(name: 'Afghanistan', dialCode: '+93', flag: '🇦🇫', code: 'AF'),
    Country(name: 'Maldives', dialCode: '+960', flag: '🇲🇻', code: 'MV'),
    Country(name: 'Mauritius', dialCode: '+230', flag: '🇲🇺', code: 'MU'),
    Country(name: 'Zimbabwe', dialCode: '+263', flag: '🇿🇼', code: 'ZW'),
    Country(name: 'Ethiopia', dialCode: '+251', flag: '🇪🇹', code: 'ET'),
    Country(name: 'Tanzania', dialCode: '+255', flag: '🇹🇿', code: 'TZ'),
    Country(name: 'Uganda', dialCode: '+256', flag: '🇺🇬', code: 'UG'),
    Country(name: 'Ukraine', dialCode: '+380', flag: '🇺🇦', code: 'UA'),
    Country(name: 'Kazakhstan', dialCode: '+7', flag: '🇰🇿', code: 'KZ'),
    Country(name: 'Uzbekistan', dialCode: '+998', flag: '🇺🇿', code: 'UZ'),
    Country(name: 'Algeria', dialCode: '+213', flag: '🇩🇿', code: 'DZ'),
    Country(name: 'Angola', dialCode: '+244', flag: '🇦🇴', code: 'AO'),
    Country(name: 'Azerbaijan', dialCode: '+994', flag: '🇦🇿', code: 'AZ'),
    Country(name: 'Belarus', dialCode: '+375', flag: '🇧🇾', code: 'BY'),
    Country(name: 'Bolivia', dialCode: '+591', flag: '🇧🇴', code: 'BO'),
    Country(name: 'Bulgaria', dialCode: '+359', flag: '🇧🇬', code: 'BG'),
    Country(name: 'Cambodia', dialCode: '+855', flag: '🇰🇭', code: 'KH'),
    Country(name: 'Cameroon', dialCode: '+237', flag: '🇨🇲', code: 'CM'),
    Country(name: 'Costa Rica', dialCode: '+506', flag: '🇨🇷', code: 'CR'),
    Country(name: 'Croatia', dialCode: '+385', flag: '🇭🇷', code: 'HR'),
    Country(name: 'Cyprus', dialCode: '+357', flag: '🇨🇾', code: 'CY'),
    Country(name: 'Ecuador', dialCode: '+593', flag: '🇪🇨', code: 'EC'),
    Country(name: 'Estonia', dialCode: '+372', flag: '🇪🇪', code: 'EE'),
    Country(name: 'Georgia', dialCode: '+995', flag: '🇬🇪', code: 'GE'),
    Country(name: 'Guatemala', dialCode: '+502', flag: '🇬🇹', code: 'GT'),
    Country(name: 'Iceland', dialCode: '+354', flag: '🇮🇸', code: 'IS'),
    Country(name: 'Jamaica', dialCode: '+1', flag: '🇯🇲', code: 'JM'),
    Country(name: 'Latvia', dialCode: '+371', flag: '🇱🇻', code: 'LV'),
    Country(name: 'Lithuania', dialCode: '+370', flag: '🇱🇹', code: 'LT'),
    Country(name: 'Luxembourg', dialCode: '+352', flag: '🇱🇺', code: 'LU'),
    Country(name: 'Panama', dialCode: '+507', flag: '🇵🇦', code: 'PA'),
    Country(name: 'Paraguay', dialCode: '+595', flag: '🇵🇾', code: 'PY'),
    Country(name: 'Slovakia', dialCode: '+421', flag: '🇸🇰', code: 'SK'),
    Country(name: 'Slovenia', dialCode: '+386', flag: '🇸🇮', code: 'SI'),
    Country(name: 'Uruguay', dialCode: '+598', flag: '🇺🇾', code: 'UY'),
    Country(name: 'Venezuela', dialCode: '+58', flag: '🇻🇪', code: 'VE'),
    Country(name: 'Yemen', dialCode: '+967', flag: '🇾🇪', code: 'YE'),
  ];
}

class CountryCodeButton extends StatelessWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;

  const CountryCodeButton({
    super.key,
    required this.selectedCountry,
    required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showCountryCodePicker(
        context,
        selectedCountry: selectedCountry,
        onSelect: onCountryChanged,
      ),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCountry.flag,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 6),
            Text(
              selectedCountry.dialCode,
              style: GoogleFonts.poppins(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.textGrey,
              size: 18,
            ),
            const SizedBox(width: 6),
            Container(
              height: 24,
              width: 1,
              color: AppTheme.cardBorder,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

void showCountryCodePicker(
  BuildContext context, {
  Country? selectedCountry,
  required ValueChanged<Country> onSelect,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.backgroundBlack,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _CountryPickerSheet(
      selectedCountry: selectedCountry ?? Countries.defaultCountry,
      onSelect: (country) {
        Navigator.pop(ctx);
        onSelect(country);
      },
    ),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onSelect;

  const _CountryPickerSheet({
    required this.selectedCountry,
    required this.onSelect,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Country> _filteredCountries = Countries.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = Countries.all;
      } else {
        _filteredCountries = Countries.all.where((c) {
          final matchName = c.name.toLowerCase().contains(query);
          final matchDial = c.dialCode.contains(query);
          final matchCode = c.code.toLowerCase().contains(query);
          return matchName || matchDial || matchCode;
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Select Country Code',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textGrey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by country or dial code (e.g. +1, UK)',
                  hintStyle: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textGrey, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.cardBorder),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Country List
            Expanded(
              child: _filteredCountries.isEmpty
                  ? Center(
                      child: Text(
                        'No country found',
                        style: GoogleFonts.poppins(color: AppTheme.textMuted),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: _filteredCountries.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: AppTheme.cardBorder,
                        height: 1,
                        indent: 64,
                      ),
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        final isSelected = country.code == widget.selectedCountry.code &&
                            country.dialCode == widget.selectedCountry.dialCode;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          leading: Text(
                            country.flag,
                            style: const TextStyle(fontSize: 26),
                          ),
                          title: Text(
                            country.name,
                            style: GoogleFonts.poppins(
                              color: isSelected ? AppTheme.primaryGreen : AppTheme.textWhite,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                country.dialCode,
                                style: GoogleFonts.poppins(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check, color: AppTheme.primaryGreen, size: 18),
                              ],
                            ],
                          ),
                          onTap: () => widget.onSelect(country),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
