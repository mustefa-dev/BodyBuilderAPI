import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/country_picker.dart';
import '../../../core/widgets/premium.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  CountryCode _country = defaultCountry;

  @override
  void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _register() async {
    final phone = '${_country.dialCode}${_phoneCtrl.text.trim()}';
    final success = await ref.read(authProvider.notifier).register(_nameCtrl.text.trim(), phone, _passCtrl.text);
    if (success && mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created!'))); context.pop(); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textSecondary)),
                const Spacer(),
                const KineticLogo(size: 20),
                const Spacer(),
                const SizedBox(width: 48),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text('CREATE ACCOUNT', style: GoogleFonts.lexend(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text('Join the elite ranks of professional performance.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 36),

                    const SectionLabel('Full Name'),
                    const SizedBox(height: 10),
                    _input(_nameCtrl, 'John Doe', prefixIcon: Icons.person_outline),
                    const SizedBox(height: 24),

                    const SectionLabel('Phone Number'),
                    const SizedBox(height: 10),
                    PhoneInput(controller: _phoneCtrl, onCountryChanged: (c) => _country = c),
                    const SizedBox(height: 24),

                    const SectionLabel('Secure Password'),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(12)),
                      child: TextField(
                        controller: _passCtrl, obscureText: _obscure,
                        style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                    ),

                    if (auth.error != null) ...[
                      const SizedBox(height: 16),
                      Text(auth.error!, style: GoogleFonts.inter(color: AppColors.error, fontSize: 13)),
                    ],
                    const SizedBox(height: 32),
                    LimeButton(label: 'REGISTER ACCOUNT', isLoading: auth.isLoading, onPressed: _register),
                    const SizedBox(height: 16),
                    Center(
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: 'By registering, you agree to our ', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                        TextSpan(text: 'Terms of Service', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        TextSpan(text: ' and ', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                        TextSpan(text: 'Privacy Policy', style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ]), textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 24),
                    Center(child: Column(children: [
                      Text('Already have an account?', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                      GestureDetector(onTap: () => context.pop(), child: Padding(padding: const EdgeInsets.all(8), child: Text('BACK TO LOGIN', style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1)))),
                    ])),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String hint, {IconData? prefixIcon}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.textMuted, size: 20) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
