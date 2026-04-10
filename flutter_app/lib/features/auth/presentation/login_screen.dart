import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/country_picker.dart';
import '../../../core/widgets/premium.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  CountryCode _country = defaultCountry;

  @override
  void dispose() { _phoneCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    final phone = '${_country.dialCode}${_phoneCtrl.text.trim()}';
    final success = await ref.read(authProvider.notifier).login(phone, _passCtrl.text);
    if (success && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              const Center(child: KineticLogo(size: 28)),
              const SizedBox(height: 48),
              Text('ATHLETE LOGIN', style: GoogleFonts.lexend(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text('Access your biometric dashboard', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 36),

              const SectionLabel('Phone Number'),
              const SizedBox(height: 10),
              PhoneInput(controller: _phoneCtrl, onCountryChanged: (c) => _country = c),
              const SizedBox(height: 24),

              const SectionLabel('Secure Password'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onSubmitted: (_) => _login(),
                ),
              ),

              if (auth.error != null) ...[
                const SizedBox(height: 16),
                Text(auth.error!, style: GoogleFonts.inter(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
              const SizedBox(height: 32),

              LimeButton(label: 'EXECUTE LOGIN', icon: Icons.arrow_forward, isLoading: auth.isLoading, onPressed: _login),
              const SizedBox(height: 32),

              // Divider with text
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: AppColors.surfaceHigh)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('NEW RECRUIT?', style: GoogleFonts.lexend(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1.5))),
                  Expanded(child: Container(height: 1, color: AppColors.surfaceHigh)),
                ],
              ),
              const SizedBox(height: 24),

              // Register card
              GestureDetector(
                onTap: () => context.push('/auth/register'),
                child: SurfaceCard(
                  color: AppColors.surfaceLow,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Start your journey', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      Text('Create an account', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
