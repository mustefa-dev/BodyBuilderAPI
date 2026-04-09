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
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final phone = '${_country.dialCode}${_phoneCtrl.text.trim()}';
    final success = await ref.read(authProvider.notifier).register(_nameCtrl.text.trim(), phone, _passCtrl.text);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created! Please log in.')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: GlowBackground(
        glow1: AppColors.accent2,
        glow2: AppColors.accent1,
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Create Account', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1.5)),
                      const SizedBox(height: 6),
                      Text('Start your fitness journey today', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
                      const SizedBox(height: 36),

                      // Full Name
                      const OverlineLabel('Full Name'),
                      const SizedBox(height: 8),
                      GlassInput(
                        controller: _nameCtrl,
                        hint: 'Enter your name',
                        prefixIcon: Icons.person_outline,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),

                      // Phone
                      const OverlineLabel('Phone Number'),
                      const SizedBox(height: 8),
                      PhoneInput(
                        controller: _phoneCtrl,
                        onCountryChanged: (c) => _country = c,
                      ),
                      const SizedBox(height: 20),

                      // Password
                      const OverlineLabel('Password'),
                      const SizedBox(height: 8),
                      GlassInput(
                        controller: _passCtrl,
                        hint: 'Create a password',
                        prefixIcon: Icons.lock_outline,
                        obscure: _obscure,
                        textInputAction: TextInputAction.go,
                        onSubmitted: (_) => _register(),
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),

                      // Error
                      if (auth.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(auth.error!, style: GoogleFonts.inter(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500))),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      GradientButton(
                        label: 'Create Account',
                        isLoading: auth.isLoading,
                        onPressed: _register,
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account? ', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Text('Log In', style: GoogleFonts.inter(color: AppColors.accent2, fontSize: 14, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
