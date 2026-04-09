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
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final phone = '${_country.dialCode}${_phoneCtrl.text.trim()}';
    final success = await ref.read(authProvider.notifier).login(phone, _passCtrl.text);
    if (success && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: GlowBackground(
        glow1: AppColors.accent1,
        glow2: AppColors.accent2,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: AppColors.accent1.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 8))],
                    ),
                    child: const Icon(Icons.fitness_center, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text('Welcome Back', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1.5)),
                  const SizedBox(height: 6),
                  Text('Log in to continue your training', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
                  const SizedBox(height: 40),

                  // Phone
                  const Align(alignment: Alignment.centerLeft, child: OverlineLabel('Phone Number')),
                  const SizedBox(height: 8),
                  PhoneInput(
                    controller: _phoneCtrl,
                    onCountryChanged: (c) => _country = c,
                  ),
                  const SizedBox(height: 20),

                  // Password
                  const Align(alignment: Alignment.centerLeft, child: OverlineLabel('Password')),
                  const SizedBox(height: 8),
                  GlassInput(
                    controller: _passCtrl,
                    hint: 'Enter password',
                    prefixIcon: Icons.lock_outline,
                    obscure: _obscure,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _login(),
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
                  const SizedBox(height: 28),

                  // Login button
                  GradientButton(
                    label: 'Log In',
                    isLoading: auth.isLoading,
                    onPressed: _login,
                  ),
                  const SizedBox(height: 20),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
                      GestureDetector(
                        onTap: () => context.push('/auth/register'),
                        child: Text('Sign Up', style: GoogleFonts.inter(color: AppColors.accent2, fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
