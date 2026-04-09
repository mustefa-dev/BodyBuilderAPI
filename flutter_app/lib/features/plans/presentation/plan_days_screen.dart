import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium.dart';
import '../../session/data/session_repository.dart';
import '../data/models.dart';
import 'plans_provider.dart';

class PlanDaysScreen extends ConsumerWidget {
  final String planId;
  const PlanDaysScreen({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysAsync = ref.watch(planDaysProvider(planId));

    return Scaffold(
      body: GlowBackground(
        glow1: AppColors.accent1,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textSecondary)),
                    const Spacer(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Choose Your', style: GoogleFonts.inter(fontSize: 16, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                    Text('Workout Day', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: daysAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                        const SizedBox(height: 12),
                        const Text('Failed to load', style: TextStyle(color: AppColors.error)),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => ref.invalidate(planDaysProvider(planId)), child: const Text('Retry')),
                      ],
                    ),
                  ),
                  data: (days) => ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: days.length,
                    itemBuilder: (context, index) => _DayCard(day: days[index], index: index),
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

class _DayCard extends ConsumerStatefulWidget {
  final WorkoutDay day;
  final int index;
  const _DayCard({required this.day, required this.index});

  @override
  ConsumerState<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends ConsumerState<_DayCard> {
  bool _loading = false;

  static const _gradients = [
    [Color(0xFF6C63FF), Color(0xFF3B82F6)],
    [Color(0xFFEF4444), Color(0xFFF59E0B)],
    [Color(0xFF22C55E), Color(0xFF06B6D4)],
    [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
  ];

  Future<void> _checkIn() async {
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    try {
      final sessionId = await ref.read(sessionRepositoryProvider).checkIn(widget.day.id);
      if (mounted) {
        context.go('/workout?sessionId=$sessionId&dayId=${widget.day.id}&title=${Uri.encodeComponent(widget.day.title)}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to start. Try again.')));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[widget.index % _gradients.length];
    final exercisesAsync = ref.watch(dayExercisesProvider(widget.day.id));

    return GestureDetector(
      onTap: () => _showSheet(context, exercisesAsync),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: colors[0].withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Center(child: Text('${widget.day.dayNumber}', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.day.title, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3)),
                  const SizedBox(height: 2),
                  exercisesAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (ex) => Text('${ex.length} exercises', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context, AsyncValue<List<DayExercise>> exercisesAsync) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(widget.day.title, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1)),
              const SizedBox(height: 16),
              exercisesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Could not load exercises'),
                data: (exercises) => Column(
                  children: exercises.asMap().entries.map((entry) {
                    final e = entry.value;
                    final color = AppColors.categoryColor(e.category);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                            child: Center(child: Text('${entry.key + 1}', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(e.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                          Text('${e.targetSets}x${e.targetReps}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: 'Start Workout',
                icon: Icons.play_arrow_rounded,
                gradient: AppColors.successGradient,
                isLoading: _loading,
                height: 60,
                onPressed: _checkIn,
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }
}
