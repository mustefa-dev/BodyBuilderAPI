import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final double totalDurationMinutes;
  final int totalSets;

  const WorkoutSummaryScreen({super.key, required this.totalDurationMinutes, required this.totalSets});

  String get _formattedDuration {
    final mins = totalDurationMinutes.round();
    if (mins >= 60) return '${mins ~/ 60}h ${mins % 60}m';
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        glow1: AppColors.gold,
        glow2: AppColors.success,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Trophy with glow
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 8)],
                    ),
                    child: const Icon(Icons.emoji_events, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 28),
                  Text('Workout Complete!', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1)),
                  const SizedBox(height: 6),
                  Text('Great job pushing through', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
                  const SizedBox(height: 40),

                  // Stats
                  Row(
                    children: [
                      Expanded(child: _SummaryCard(icon: Icons.timer_outlined, value: _formattedDuration, label: 'Duration', color: AppColors.accent2)),
                      const SizedBox(width: 12),
                      Expanded(child: _SummaryCard(icon: Icons.fitness_center, value: '$totalSets', label: 'Sets', color: AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 48),

                  GradientButton(
                    label: 'Back to Home',
                    icon: Icons.home_rounded,
                    height: 60,
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SummaryCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
