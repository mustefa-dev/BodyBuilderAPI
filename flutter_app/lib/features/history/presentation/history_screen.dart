import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium.dart';
import '../../session/presentation/session_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WORKOUT\nHISTORY',
                    style: GoogleFonts.lexend(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -1, height: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Review your path to peak performance.',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Stat cards ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: historyAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (sessions) {
                  final totalVolume = sessions.fold<double>(0, (sum, s) => sum + (s.totalDurationMinutes ?? 0)).round();
                  return Row(
                    children: [
                      Expanded(
                        child: SurfaceCard(
                          color: AppColors.surfaceLow,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TOTAL VOLUME', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 1)),
                              const SizedBox(height: 8),
                              Text('${totalVolume}m', style: GoogleFonts.lexend(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SurfaceCard(
                          color: AppColors.surfaceLow,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('WORKOUTS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 1)),
                              const SizedBox(height: 8),
                              Text('${sessions.length}', style: GoogleFonts.lexend(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── Workout list ──
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.invalidate(historyProvider),
                        child: Text('Retry', style: GoogleFonts.inter(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: 64, color: AppColors.textMuted.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Text('No workouts yet', style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                          const SizedBox(height: 6),
                          Text('Your completed sessions will appear here', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final s = sessions[index];
                      return _HistoryCard(session: s);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final dynamic session;
  const _HistoryCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, MMM d').format(session.checkInTime.toLocal()).toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date in lime
          Text(
            date,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          // Workout name + chevron
          Row(
            children: [
              Expanded(
                child: Text(
                  session.title,
                  style: GoogleFonts.lexend(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          // Duration + volume row
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                session.formattedDuration,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
