import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gym_button.dart';
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activeSessionProvider);
            ref.invalidate(historyProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Greeting
              const SizedBox(height: 8),
              Text(
                'Hey, ${auth.userName ?? 'Champ'}',
                style: GoogleFonts.oswald(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                DateFormat('EEEE, MMM d').format(DateTime.now()),
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              // Active session banner
              activeAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (session) {
                  if (session == null) return const SizedBox.shrink();
                  return Card(
                    color: AppColors.success.withValues(alpha: 0.12),
                    margin: const EdgeInsets.only(bottom: 20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.go(
                          '/workout?sessionId=${session.id}&dayId=${session.workoutDayId}&title=${Uri.encodeComponent('Active Workout')}'),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.play_arrow, color: AppColors.success, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Workout In Progress',
                                      style: GoogleFonts.oswald(fontSize: 18, color: AppColors.success, fontWeight: FontWeight.bold)),
                                  Text('${session.completedSetsCount} sets completed',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                            Text('RESUME', style: GoogleFonts.oswald(color: AppColors.success, fontSize: 15)),
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
                  return GymButton(
                    label: 'START WORKOUT',
                    icon: Icons.fitness_center,
                    onPressed: () => context.push('/plans/${plans.first.id}/days'),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Recent workouts
              Text('RECENT WORKOUTS', style: GoogleFonts.oswald(fontSize: 16, color: AppColors.textMuted, letterSpacing: 1)),
              const SizedBox(height: 12),
              historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Could not load history', style: TextStyle(color: AppColors.textMuted)),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                      child: const Center(
                        child: Text('No workouts yet. Start your first one!', style: TextStyle(color: AppColors.textMuted)),
                      ),
                    );
                  }
                  return Column(
                    children: sessions.take(3).map((s) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                          title: Text(s.title, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
                          subtitle: Text(
                            DateFormat('MMM d').format(s.checkInTime.toLocal()),
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                          trailing: Text(s.formattedDuration,
                              style: GoogleFonts.oswald(fontSize: 15, color: AppColors.primary)),
                        ),
                      );
                    }).toList(),
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
