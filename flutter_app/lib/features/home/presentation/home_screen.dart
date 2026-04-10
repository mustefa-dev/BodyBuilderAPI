import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../plans/presentation/plans_provider.dart';
import '../../session/presentation/session_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final activeAsync = ref.watch(activeSessionProvider);
    final historyAsync = ref.watch(historyProvider);
    final plansAsync = ref.watch(plansProvider);

    final now = DateTime.now();
    final dateLabel = DateFormat('EEEE, MMMM d').format(now).toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceLow,
          onRefresh: () async {
            ref.invalidate(activeSessionProvider);
            ref.invalidate(historyProvider);
            ref.invalidate(plansProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // ── Top bar: logo + profile icon ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const KineticLogo(size: 22),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_outline, color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Date ──
              Text(
                dateLabel,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 1.5),
              ),
              const SizedBox(height: 6),

              // ── Greeting ──
              Text(
                'Hello, ${auth.userName ?? 'Champ'}',
                style: GoogleFonts.lexend(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -1),
              ),
              const SizedBox(height: 28),

              // ── Active session card ──
              activeAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (session) {
                  if (session == null) return const SizedBox.shrink();
                  final elapsed = session.elapsedTimeMinutes;
                  final mins = elapsed.round();
                  final h = mins ~/ 60;
                  final m = mins % 60;
                  final durationStr = h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () => context.push('/workout?sessionId=${session.id}&dayId=${session.workoutDayId}&title=${Uri.encodeComponent('Active Workout')}'),
                      child: SurfaceCard(
                        color: AppColors.surfaceLow,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ACTIVE SESSION',
                              style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1.5),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Workout In Progress',
                              style: GoogleFonts.lexend(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _MiniStat(label: 'DURATION', value: durationStr),
                                const SizedBox(width: 24),
                                _MiniStat(label: 'SETS DONE', value: '${session.completedSetsCount}'),
                              ],
                            ),
                            const SizedBox(height: 18),
                            LimeButton(
                              label: 'RESUME WORKOUT',
                              height: 48,
                              onPressed: () => context.push('/workout?sessionId=${session.id}&dayId=${session.workoutDayId}&title=${Uri.encodeComponent('Active Workout')}'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ── Start new workout card ──
              // Only show start if NO active session
              activeAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (session) {
                  if (session != null) return const SizedBox.shrink(); // already has active
                  return plansAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (plans) {
                      if (plans.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: GestureDetector(
                          onTap: () => context.push('/plans/${plans.first.id}/days'),
                          child: SurfaceCard(
                            color: AppColors.surfaceLow,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceHigh,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.add, color: AppColors.primary, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  'START NEW WORKOUT',
                                  style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: 0.5),
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 22),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // ── Stat cards row ──
              historyAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (sessions) {
                  final totalWorkouts = sessions.length;
                  final totalMins = sessions.fold<double>(0, (sum, s) => sum + (s.totalDurationMinutes ?? 0)).round();
                  return Row(
                    children: [
                      Expanded(
                        child: _BigStatCard(label: 'TOTAL WORKOUTS', value: '$totalWorkouts'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BigStatCard(label: 'TOTAL MINUTES', value: '$totalMins'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // ── Recent history header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionLabel('RECENT HISTORY'),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'VIEW ALL',
                      style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── History list ──
              historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (_, __) => const SizedBox.shrink(),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return SurfaceCard(
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.fitness_center, size: 32, color: AppColors.textMuted.withValues(alpha: 0.4)),
                            const SizedBox(height: 8),
                            Text('No workouts yet', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: sessions.take(5).map((s) => _HistoryTile(session: s)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini stat (used inside active session card) ──
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}

// ── Big stat card ──
class _BigStatCard extends StatelessWidget {
  final String label;
  final String value;
  const _BigStatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      color: AppColors.surfaceLow,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 1)),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.lexend(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1)),
        ],
      ),
    );
  }
}

// ── History tile ──
class _HistoryTile extends StatelessWidget {
  final dynamic session;
  const _HistoryTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, yyyy').format(session.checkInTime.toLocal());
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Date column
          SizedBox(
            width: 60,
            child: Text(
              date,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted, height: 1.3),
            ),
          ),
          const SizedBox(width: 12),
          // Workout info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: GoogleFonts.lexend(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  session.formattedDuration,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}
