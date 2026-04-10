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
    final totalSecs = (totalDurationMinutes * 60).round();
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // MISSION COMPLETE label
              Text(
                'MISSION COMPLETE',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),

              // ELITE STATUS huge italic bold
              Text(
                'ELITE STATUS',
                style: GoogleFonts.lexend(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.02 * 40,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 32),

              // Trophy icon card
              SurfaceCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.emoji_events_rounded, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your performance telemetry has been\nsynced to the kinetic cloud.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // DURATION card
              SurfaceCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'DURATION',
                      style: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formattedDuration,
                          style: GoogleFonts.lexend(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            height: 1,
                            letterSpacing: -0.02 * 48,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'MIN',
                            style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Two stat cards side by side
              Row(
                children: [
                  Expanded(
                    child: SurfaceCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'TOTAL SETS',
                            style: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalSets',
                            style: GoogleFonts.lexend(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SurfaceCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'VOLUME',
                            style: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalSets',
                            style: GoogleFonts.lexend(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 2),

              // BACK TO HOME button
              LimeButton(
                label: 'BACK TO HOME \u2192',
                height: 60,
                onPressed: () => context.go('/'),
              ),
              const SizedBox(height: 16),

              // Bottom text
              Text(
                'PERFORMANCE DATA ENCRYPTED & SAVED',
                style: GoogleFonts.lexend(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}
