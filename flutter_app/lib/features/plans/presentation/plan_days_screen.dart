import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gym_button.dart';
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
      appBar: AppBar(title: const Text('SELECT DAY')),
      body: daysAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load days', style: TextStyle(color: AppColors.error)),
              const SizedBox(height: 12),
              TextButton(onPressed: () => ref.invalidate(planDaysProvider(planId)), child: const Text('Retry')),
            ],
          ),
        ),
        data: (days) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: days.length,
          itemBuilder: (context, index) => _DayCard(day: days[index]),
        ),
      ),
    );
  }
}

class _DayCard extends ConsumerStatefulWidget {
  final WorkoutDay day;
  const _DayCard({required this.day});

  @override
  ConsumerState<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends ConsumerState<_DayCard> {
  bool _loading = false;

  Future<void> _checkIn() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(sessionRepositoryProvider);
      final sessionId = await repo.checkIn(widget.day.id);
      if (mounted) {
        context.go('/workout?sessionId=$sessionId&dayId=${widget.day.id}&title=${Uri.encodeComponent(widget.day.title)}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start workout. Try again.')),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(dayExercisesProvider(widget.day.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showConfirmDialog(context, exercisesAsync),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${widget.day.dayNumber}',
                    style: GoogleFonts.oswald(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.day.title, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('Day ${widget.day.dayNumber}', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, AsyncValue<List<DayExercise>> exercisesAsync) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.day.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Could not load exercises'),
              data: (exercises) => Column(
                children: exercises
                    .map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.categoryColor(e.category),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(e.name, style: const TextStyle(color: AppColors.textPrimary))),
                              Text('${e.targetSets}x${e.targetReps}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            GymButton(
              label: 'CHECK IN',
              icon: Icons.play_arrow,
              color: AppColors.success,
              isLoading: _loading,
              onPressed: _checkIn,
            ),
          ],
        ),
      ),
    );
  }
}
