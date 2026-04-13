import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../session/data/session_models.dart';
import '../../session/presentation/session_provider.dart';

class SessionDetailScreen extends ConsumerWidget {
  final String sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(sessionDetailProvider(sessionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                const SizedBox(height: 12),
                Text('Failed to load session', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(sessionDetailProvider(sessionId)),
                  child: Text('Retry', style: GoogleFonts.inter(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          data: (detail) => _Body(detail: detail),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final SessionDetail detail;
  const _Body({required this.detail});

  String _buildCoachText() {
    final buffer = StringBuffer();
    buffer.writeln('Workout: ${detail.title}');
    buffer.writeln('Date: ${DateFormat('EEE, MMM d y').format(detail.checkInTime.toLocal())}');
    buffer.writeln('Duration: ${detail.formattedDuration}');
    buffer.writeln('Total sets: ${detail.totalSets}');
    buffer.writeln('');
    for (final ex in detail.exercises) {
      buffer.writeln('• ${ex.exerciseName}');
      for (final s in ex.sets) {
        final failure = s.isFailureReached ? ' (failure)' : '';
        buffer.writeln('   Set ${s.setNumber}: ${_fmtWeight(s.weightUsed)} kg × ${s.repsCompleted}$failure');
      }
    }
    return buffer.toString();
  }

  String _fmtWeight(double w) {
    if (w == w.roundToDouble()) return w.toInt().toString();
    return w.toStringAsFixed(1);
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _buildCoachText()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied — paste it to your coach', style: GoogleFonts.inter(color: AppColors.onPrimary, fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, MMM d').format(detail.checkInTime.toLocal()).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SESSION DETAILS',
                  style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text(
                detail.title,
                style: GoogleFonts.lexend(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1, height: 1.1),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatChip(icon: Icons.timer_outlined, label: detail.formattedDuration),
                  const SizedBox(width: 10),
                  _StatChip(icon: Icons.fitness_center, label: '${detail.exercises.length} exercises'),
                  const SizedBox(width: 10),
                  _StatChip(icon: Icons.repeat, label: '${detail.totalSets} sets'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Exercise list
        Expanded(
          child: detail.exercises.isEmpty
              ? Center(
                  child: Text(
                    'No sets recorded in this session',
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  itemCount: detail.exercises.length,
                  itemBuilder: (_, i) => _ExerciseBlock(exercise: detail.exercises[i], index: i),
                ),
        ),

        // Share with coach button
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _copyToClipboard(context),
              icon: const Icon(Icons.copy_rounded, color: AppColors.onPrimary),
              label: Text(
                'COPY TO SHOW COACH',
                style: GoogleFonts.lexend(color: AppColors.onPrimary, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  final SessionExercise exercise;
  final int index;
  const _ExerciseBlock({required this.exercise, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = exercise.category != null ? AppColors.categoryColor(exercise.category!) : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.lexend(color: color, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exercise.exerciseName,
                  style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _ColHeader(label: 'SET', flex: 1),
                _ColHeader(label: 'WEIGHT', flex: 2),
                _ColHeader(label: 'REPS', flex: 2),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...exercise.sets.map((s) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        '${s.setNumber}',
                        style: GoogleFonts.lexend(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${_fmt(s.weightUsed)} kg',
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Text(
                            '${s.repsCompleted}',
                            style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          if (s.isFailureReached) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.flash_on, size: 12, color: AppColors.warning),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _fmt(double w) {
    if (w == w.roundToDouble()) return w.toInt().toString();
    return w.toStringAsFixed(1);
  }
}

class _ColHeader extends StatelessWidget {
  final String label;
  final int flex;
  const _ColHeader({required this.label, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1),
      ),
    );
  }
}
