import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gym_button.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final double totalDurationMinutes;
  final int totalSets;

  const WorkoutSummaryScreen({
    super.key,
    required this.totalDurationMinutes,
    required this.totalSets,
  });

  String get _formattedDuration {
    final mins = totalDurationMinutes.round();
    if (mins >= 60) return '${mins ~/ 60}h ${mins % 60}m';
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 80, color: AppColors.gold),
                const SizedBox(height: 24),
                Text('WORKOUT COMPLETE!',
                    style: GoogleFonts.oswald(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 32),
                _StatRow(icon: Icons.timer, label: 'Duration', value: _formattedDuration),
                const SizedBox(height: 16),
                _StatRow(icon: Icons.fitness_center, label: 'Sets Completed', value: '$totalSets'),
                const SizedBox(height: 48),
                GymButton(
                  label: 'BACK TO HOME',
                  icon: Icons.home,
                  onPressed: () => context.go('/'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 16),
          Text(label, style: GoogleFonts.inter(fontSize: 16, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
