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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar: logo left, bell + avatar right
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const KineticLogo(size: 22),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_none_rounded, color: AppColors.textMuted, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
            ),

            // Title section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'SELECT DAY',
                    style: GoogleFonts.lexend(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.02 * 40,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '5-DAY FULL BODY PLAN',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Day cards
            Expanded(
              child: daysAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                      const SizedBox(height: 12),
                      Text('Failed to load', style: GoogleFonts.inter(color: AppColors.error)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(planDaysProvider(planId)),
                        child: Text('Retry', style: GoogleFonts.inter(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                data: (days) => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: days.length,
                  itemBuilder: (context, index) => _DayCard(day: days[index], index: index, isFirst: index == 0),
                ),
              ),
            ),

            // Sticky bottom button
            Container(
              color: AppColors.background,
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              child: daysAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (days) => days.isNotEmpty
                    ? _StartWorkoutButton(day: days.first)
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
//  START WORKOUT STICKY BUTTON
// ============================================================
class _StartWorkoutButton extends ConsumerStatefulWidget {
  final WorkoutDay day;
  const _StartWorkoutButton({required this.day});

  @override
  ConsumerState<_StartWorkoutButton> createState() => _StartWorkoutButtonState();
}

class _StartWorkoutButtonState extends ConsumerState<_StartWorkoutButton> {
  bool _loading = false;

  Future<void> _checkIn() async {
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    try {
      final sessionId = await ref.read(sessionRepositoryProvider).checkIn(widget.day.id);
      if (mounted) {
        context.push('/workout?sessionId=$sessionId&dayId=${widget.day.id}&title=${Uri.encodeComponent(widget.day.title)}');
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
    return LimeButton(
      label: 'START WORKOUT',
      icon: Icons.bolt_rounded,
      isLoading: _loading,
      height: 60,
      onPressed: _checkIn,
    );
  }
}

// ============================================================
//  DAY CARD
// ============================================================
class _DayCard extends ConsumerStatefulWidget {
  final WorkoutDay day;
  final int index;
  final bool isFirst;
  const _DayCard({required this.day, required this.index, required this.isFirst});

  @override
  ConsumerState<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends ConsumerState<_DayCard> {
  bool _loading = false;

  Future<void> _checkIn() async {
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    try {
      final sessionId = await ref.read(sessionRepositoryProvider).checkIn(widget.day.id);
      if (mounted) {
        Navigator.of(context).pop(); // close bottom sheet
        context.push('/workout?sessionId=$sessionId&dayId=${widget.day.id}&title=${Uri.encodeComponent(widget.day.title)}');
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
    final exercisesAsync = ref.watch(dayExercisesProvider(widget.day.id));
    final dayLabel = 'DAY ${widget.day.dayNumber.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () => _showSheet(context, exercisesAsync),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Main card row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Lime accent bar
                  Container(
                    width: 4,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayLabel,
                          style: GoogleFonts.lexend(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.day.title,
                          style: GoogleFonts.lexend(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.02 * 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        exercisesAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (ex) => Text(
                            '${ex.length} exercises  ·  ~${ex.length * 8} min',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.isFirst)
                    Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 24),
                ],
              ),
            ),

            // First card expanded: session preview
            if (widget.isFirst)
              exercisesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (exercises) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: AppColors.surfaceHigh,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'SESSION PREVIEW',
                        style: GoogleFonts.lexend(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: exercises.map((e) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            e.name,
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
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
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Day label
              Text(
                'DAY ${widget.day.dayNumber.toString().padLeft(2, '0')}',
                style: GoogleFonts.lexend(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1.5),
              ),
              const SizedBox(height: 6),
              Text(
                widget.day.title,
                style: GoogleFonts.lexend(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.02 * 24),
              ),
              const SizedBox(height: 20),

              // Exercise list
              exercisesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (_, __) => Text('Could not load exercises', style: GoogleFonts.inter(color: AppColors.error)),
                data: (exercises) => Column(
                  children: exercises.asMap().entries.map((entry) {
                    final e = entry.value;
                    final color = AppColors.categoryColor(e.category);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: GoogleFonts.lexend(color: color, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              e.name,
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                            ),
                          ),
                          Text(
                            '${e.targetSets}x${e.targetReps}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              LimeButton(
                label: 'START WORKOUT',
                icon: Icons.bolt_rounded,
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
