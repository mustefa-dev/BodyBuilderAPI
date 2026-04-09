import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class CountryCode {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const CountryCode({required this.name, required this.code, required this.dialCode, required this.flag});
}

const _countries = [
  CountryCode(name: 'Iraq', code: 'IQ', dialCode: '+964', flag: '🇮🇶'),
  CountryCode(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
  CountryCode(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
  CountryCode(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '🇸🇦'),
  CountryCode(name: 'UAE', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
  CountryCode(name: 'Kuwait', code: 'KW', dialCode: '+965', flag: '🇰🇼'),
  CountryCode(name: 'Qatar', code: 'QA', dialCode: '+974', flag: '🇶🇦'),
  CountryCode(name: 'Bahrain', code: 'BH', dialCode: '+973', flag: '🇧🇭'),
  CountryCode(name: 'Oman', code: 'OM', dialCode: '+968', flag: '🇴🇲'),
  CountryCode(name: 'Jordan', code: 'JO', dialCode: '+962', flag: '🇯🇴'),
  CountryCode(name: 'Lebanon', code: 'LB', dialCode: '+961', flag: '🇱🇧'),
  CountryCode(name: 'Egypt', code: 'EG', dialCode: '+20', flag: '🇪🇬'),
  CountryCode(name: 'Turkey', code: 'TR', dialCode: '+90', flag: '🇹🇷'),
  CountryCode(name: 'Iran', code: 'IR', dialCode: '+98', flag: '🇮🇷'),
  CountryCode(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
  CountryCode(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
  CountryCode(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
  CountryCode(name: 'Pakistan', code: 'PK', dialCode: '+92', flag: '🇵🇰'),
  CountryCode(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
  CountryCode(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
  CountryCode(name: 'Sweden', code: 'SE', dialCode: '+46', flag: '🇸🇪'),
  CountryCode(name: 'Netherlands', code: 'NL', dialCode: '+31', flag: '🇳🇱'),
  CountryCode(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
  CountryCode(name: 'Mexico', code: 'MX', dialCode: '+52', flag: '🇲🇽'),
  CountryCode(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
  CountryCode(name: 'South Korea', code: 'KR', dialCode: '+82', flag: '🇰🇷'),
  CountryCode(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
  CountryCode(name: 'Russia', code: 'RU', dialCode: '+7', flag: '🇷🇺'),
  CountryCode(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
  CountryCode(name: 'Italy', code: 'IT', dialCode: '+39', flag: '🇮🇹'),
];

CountryCode defaultCountry = _countries.first; // Iraq

class PhoneInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<CountryCode>? onCountryChanged;

  const PhoneInput({super.key, required this.controller, this.onCountryChanged});

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  CountryCode _selected = defaultCountry;

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CountrySheet(
        selected: _selected,
        onSelect: (c) {
          setState(() => _selected = c);
          widget.onCountryChanged?.call(c);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Country code button
          GestureDetector(
            onTap: _showPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  Text(_selected.flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(_selected.dialCode, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
          // Phone input
          Expanded(
            child: TextField(
              controller: widget.controller,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary, letterSpacing: 1.5),
              decoration: InputDecoration(
                hintText: 'Phone number',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), letterSpacing: 0),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountrySheet extends StatefulWidget {
  final CountryCode selected;
  final ValueChanged<CountryCode> onSelect;

  const _CountrySheet({required this.selected, required this.onSelect});

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final _searchCtrl = TextEditingController();
  List<CountryCode> _filtered = _countries;

  void _filter(String q) {
    setState(() {
      _filtered = _countries.where((c) => c.name.toLowerCase().contains(q.toLowerCase()) || c.dialCode.contains(q)).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Select Country', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _filter,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                  prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final c = _filtered[i];
                final isSelected = c.code == widget.selected.code;
                return ListTile(
                  onTap: () => widget.onSelect(c),
                  leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(c.name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.dialCode, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, color: AppColors.accent2, size: 20),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
