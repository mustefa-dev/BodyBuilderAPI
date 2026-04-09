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

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activeSessionProvider);
              ref.invalidate(historyProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                // Greeting
                Text(
                  'Hey, ${auth.userName ?? 'Champ'} \u{1F4AA}',
                  style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE, MMM d').format(DateTime.now()),
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 28),

                // Active session banner
                activeAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (session) {
                    if (session == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: GestureDetector(
                        onTap: () => context.go('/workout?sessionId=${session.id}&dayId=${session.workoutDayId}&title=${Uri.encodeComponent('Active Workout')}'),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: AppColors.successGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Workout In Progress', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                                    Text('${session.completedSetsCount} sets done', style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
                                  ],
                                ),
                              ),
                              Text('RESUME', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Start workout
                plansAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (plans) {
                    if (plans.isEmpty) return const SizedBox.shrink();
                    return GradientButton(
                      label: 'Start Workout',
                      icon: Icons.fitness_center,
                      height: 60,
                      onPressed: () => context.push('/plans/${plans.first.id}/days'),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Quick stats
                historyAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (sessions) {
                    if (sessions.isEmpty) return const SizedBox.shrink();
                    final totalWorkouts = sessions.length;
                    final totalMins = sessions.fold<double>(0, (sum, s) => sum + (s.totalDurationMinutes ?? 0));
                    return Row(
                      children: [
                        Expanded(child: _StatCard(value: '$totalWorkouts', label: 'Workouts', icon: Icons.check_circle_outline, color: AppColors.success)),
                        const SizedBox(width: 12),
                        Expanded(child: _StatCard(value: '${totalMins.round()}', label: 'Minutes', icon: Icons.timer_outlined, color: AppColors.accent2)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Recent workouts
                const OverlineLabel('Recent Workouts'),
                const SizedBox(height: 12),
                historyAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (sessions) {
                    if (sessions.isEmpty) {
                      return GlassCard(
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.fitness_center, size: 32, color: Colors.white.withValues(alpha: 0.15)),
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
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1)),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final dynamic session;
  const _HistoryTile({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.check, color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(DateFormat('MMM d, yyyy').format(session.checkInTime.toLocal()), style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(session.formattedDuration, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accent2)),
        ],
      ),
    );
  }
}
