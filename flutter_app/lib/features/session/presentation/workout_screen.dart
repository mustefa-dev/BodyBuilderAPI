import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/rest_timer_widget.dart';
import '../../plans/presentation/plans_provider.dart';
import '../data/session_models.dart';
import '../data/session_repository.dart';
import 'widgets/exercise_card.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String dayId;
  final String title;

  const WorkoutScreen({
    super.key,
    required this.sessionId,
    required this.dayId,
    required this.title,
  });

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  final Map<String, Set<int>> _completedSets = {};
  final Map<String, int?> _loadingSets = {};
  late DateTime _startTime;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;
  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = DateTime.now().difference(_startTime));
    });
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  String get _elapsedFormatted {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes % 60;
    final s = _elapsed.inSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _logSet(String exerciseId, int setNum, double weight, int reps, bool failure, int restSeconds) async {
    setState(() => _loadingSets[exerciseId] = setNum);
    try {
      final repo = ref.read(sessionRepositoryProvider);
      await repo.recordSet(
        widget.sessionId,
        RecordSetRequest(
          workoutDayExerciseId: exerciseId,
          setNumber: setNum,
          weightUsed: weight,
          repsCompleted: reps,
          isFailureReached: failure,
        ),
      );
      setState(() {
        _completedSets.putIfAbsent(exerciseId, () => {}).add(setNum);
        _loadingSets[exerciseId] = null;
      });
      if (mounted) {
        RestTimerSheet.show(context, seconds: restSeconds, onDone: () {});
      }
    } catch (e) {
      setState(() => _loadingSets[exerciseId] = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save set. Tap LOG to retry.')),
        );
      }
    }
  }

  Future<void> _finishWorkout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Finish Workout?', style: GoogleFonts.oswald(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to end this session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('FINISH'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _checkingOut = true);
    try {
      final repo = ref.read(sessionRepositoryProvider);
      final totalMins = await repo.checkOut(widget.sessionId);
      if (mounted) {
        context.go('/workout/summary?duration=${totalMins.toStringAsFixed(1)}&sets=$_totalCompletedSets');
      }
    } catch (e) {
      setState(() => _checkingOut = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to end workout. Try again.')),
        );
      }
    }
  }

  int get _totalCompletedSets => _completedSets.values.fold(0, (sum, s) => sum + s.length);

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(dayExercisesProvider(widget.dayId));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: GoogleFonts.oswald(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(_elapsedFormatted, style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _checkingOut ? null : _finishWorkout,
              icon: _checkingOut
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_circle, color: AppColors.success),
              label: Text('FINISH', style: GoogleFonts.oswald(color: AppColors.success, fontSize: 15)),
            ),
          ),
        ],
      ),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading exercises', style: TextStyle(color: AppColors.error))),
        data: (exercises) => ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: exercises.length,
          itemBuilder: (context, index) {
            final ex = exercises[index];
            return ExerciseCard(
              exercise: ex,
              sessionId: widget.sessionId,
              completedSets: _completedSets[ex.id] ?? {},
              loadingSet: _loadingSets[ex.id],
              onLogSet: (setNum, weight, reps, failure) =>
                  _logSet(ex.id, setNum, weight, reps, failure, ex.restTimeSeconds),
            );
          },
        ),
      ),
    );
  }
}
