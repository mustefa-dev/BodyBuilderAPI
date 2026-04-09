import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../plans/data/models.dart';
import '../session_provider.dart';
import 'set_input_row.dart';

class ExerciseCard extends ConsumerStatefulWidget {
  final DayExercise exercise;
  final String sessionId;
  final Set<int> completedSets;
  final Function(int setNumber, double weight, int reps, bool failure) onLogSet;
  final int? loadingSet;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.sessionId,
    required this.completedSets,
    required this.onLogSet,
    this.loadingSet,
  });

  @override
  ConsumerState<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<ExerciseCard> {
  bool _showNotes = false;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(exerciseHistoryProvider(widget.exercise.id));
    final previousSets = historyAsync.value ?? [];
    final categoryColor = AppColors.categoryColor(widget.exercise.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.exercise.name,
                    style: GoogleFonts.oswald(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.exercise.category,
                    style: TextStyle(color: categoryColor, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Target + rest info
            Row(
              children: [
                Text('${widget.exercise.targetSets} x ${widget.exercise.targetReps}',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.accent2, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Text('${widget.exercise.restTimeMinutes}min rest',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const Spacer(),
                if (widget.exercise.notes.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _showNotes = !_showNotes),
                    child: Icon(
                      _showNotes ? Icons.info : Icons.info_outline,
                      size: 20,
                      color: _showNotes ? AppColors.accent2 : AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            // Notes
            if (_showNotes && widget.exercise.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent2.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.exercise.notes,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
              ),
            ],
            const SizedBox(height: 12),
            // Previous performance
            if (previousSets.isNotEmpty) ...[
              Text(
                'Last: ${previousSets.map((s) => '${s.weightUsed.toStringAsFixed(1)}kg x${s.repsCompleted}').join(', ')}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
            ],
            // Set rows
            ...List.generate(widget.exercise.targetSets, (i) {
              final setNum = i + 1;
              final prev = previousSets.where((s) => s.setNumber == setNum).firstOrNull;
              return SetInputRow(
                setNumber: setNum,
                prefillWeight: prev?.weightUsed,
                prefillReps: prev?.repsCompleted,
                isCompleted: widget.completedSets.contains(setNum),
                isLoading: widget.loadingSet == setNum,
                onLog: (weight, reps, failure) => widget.onLogSet(setNum, weight, reps, failure),
              );
            }),
          ],
        ),
      ),
    );
  }
}
