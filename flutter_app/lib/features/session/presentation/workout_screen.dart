import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../plans/data/models.dart';
import '../../plans/presentation/plans_provider.dart';
import '../data/session_models.dart';
import '../data/session_repository.dart';
import 'session_provider.dart';

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
  // Navigation state
  int _currentExerciseIndex = 0;
  int _currentSetNumber = 1;
  List<DayExercise> _exercises = [];

  // Input state
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  bool _failure = false;

  // Workout state
  late DateTime _startTime;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;
  int _totalSetsCompleted = 0;
  bool _isLogging = false;
  bool _checkingOut = false;
  bool _showNotes = false;

  // Rest timer state
  bool _isResting = false;
  int _restRemaining = 0;
  Timer? _restTimer;

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
    _restTimer?.cancel();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  DayExercise get _currentExercise => _exercises[_currentExerciseIndex];
  bool get _isLastSet => _currentSetNumber >= _currentExercise.targetSets;
  bool get _isLastExercise => _currentExerciseIndex >= _exercises.length - 1;
  bool get _isWorkoutDone => _isLastExercise && _isLastSet;

  String get _elapsedFormatted {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes % 60;
    final s = _elapsed.inSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _prefillFromHistory() {
    final historyAsync = ref.read(exerciseHistoryProvider(_currentExercise.id));
    final previousSets = historyAsync.value ?? [];
    final prev = previousSets.where((s) => s.setNumber == _currentSetNumber).firstOrNull;

    _weightCtrl.text = prev?.weightUsed.toStringAsFixed(1) ?? _weightCtrl.text;
    if (_currentSetNumber == 1 && prev == null) {
      _weightCtrl.text = '';
    }
    _repsCtrl.text = prev?.repsCompleted.toString() ?? '';
    _failure = false;
  }

  void _startRestTimer(int seconds) {
    setState(() {
      _isResting = true;
      _restRemaining = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restRemaining <= 1) {
        _endRest();
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 300), () => HapticFeedback.heavyImpact());
        Future.delayed(const Duration(milliseconds: 600), () => HapticFeedback.heavyImpact());
      } else {
        setState(() => _restRemaining--);
        if (_restRemaining <= 5) HapticFeedback.lightImpact();
      }
    });
  }

  void _endRest() {
    _restTimer?.cancel();
    setState(() => _isResting = false);
    _advanceToNext();
  }

  void _advanceToNext() {
    if (_isWorkoutDone) return;

    if (_isLastSet) {
      // Move to next exercise
      setState(() {
        _currentExerciseIndex++;
        _currentSetNumber = 1;
        _showNotes = true;
      });
    } else {
      setState(() => _currentSetNumber++);
    }
    _prefillFromHistory();
  }

  Future<void> _logSet() async {
    final weight = double.tryParse(_weightCtrl.text) ?? 0;
    final reps = int.tryParse(_repsCtrl.text) ?? 0;
    if (weight <= 0 || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter weight and reps')),
      );
      return;
    }

    setState(() => _isLogging = true);
    HapticFeedback.mediumImpact();

    try {
      final repo = ref.read(sessionRepositoryProvider);
      await repo.recordSet(
        widget.sessionId,
        RecordSetRequest(
          workoutDayExerciseId: _currentExercise.id,
          setNumber: _currentSetNumber,
          weightUsed: weight,
          repsCompleted: reps,
          isFailureReached: _failure,
        ),
      );
      setState(() {
        _isLogging = false;
        _totalSetsCompleted++;
      });

      if (_isWorkoutDone) {
        // Auto finish
        _finishWorkout();
      } else {
        _startRestTimer(_currentExercise.restTimeSeconds);
      }
    } catch (e) {
      setState(() => _isLogging = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Tap LOG again.')),
        );
      }
    }
  }

  Future<void> _finishWorkout() async {
    setState(() => _checkingOut = true);
    try {
      final repo = ref.read(sessionRepositoryProvider);
      final totalMins = await repo.checkOut(widget.sessionId);
      if (mounted) {
        context.go('/workout/summary?duration=${totalMins.toStringAsFixed(1)}&sets=$_totalSetsCompleted');
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

  Future<void> _confirmFinish() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Finish Workout?', style: GoogleFonts.oswald(color: AppColors.textPrimary)),
        content: Text('You completed $_totalSetsCompleted sets.\nEnd this session?'),
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
    if (confirm == true) _finishWorkout();
  }

  void _skipExercise() {
    if (_isLastExercise) return;
    setState(() {
      _currentExerciseIndex++;
      _currentSetNumber = 1;
      _showNotes = true;
    });
    _prefillFromHistory();
  }

  void _prevExercise() {
    if (_currentExerciseIndex <= 0) return;
    setState(() {
      _currentExerciseIndex--;
      _currentSetNumber = 1;
    });
    _prefillFromHistory();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(dayExercisesProvider(widget.dayId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading exercises', style: TextStyle(color: AppColors.error))),
        data: (exercises) {
          if (_exercises.isEmpty) {
            _exercises = exercises;
            _showNotes = exercises.first.notes.isNotEmpty;
            WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromHistory());
          }
          return _isResting ? _buildRestScreen() : _buildExerciseScreen();
        },
      ),
    );
  }

  // ==================== REST SCREEN ====================
  Widget _buildRestScreen() {
    final mins = _restRemaining ~/ 60;
    final secs = _restRemaining % 60;

    Color bgColor;
    if (_restRemaining <= 5) {
      bgColor = AppColors.error;
    } else if (_restRemaining <= 15) {
      bgColor = AppColors.warning;
    } else {
      bgColor = AppColors.primary;
    }

    final nextLabel = _isLastSet
        ? (_isLastExercise ? 'WORKOUT COMPLETE' : 'Next: ${_exercises[_currentExerciseIndex + 1].name}')
        : 'Set ${_currentSetNumber + 1} of ${_currentExercise.targetSets}';

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text('REST', style: GoogleFonts.oswald(fontSize: 22, color: Colors.white70, letterSpacing: 6)),
            const SizedBox(height: 16),
            Text(
              '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
              style: GoogleFonts.oswald(fontSize: 96, fontWeight: FontWeight.bold, color: Colors.white, height: 1),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(nextLabel, style: GoogleFonts.inter(fontSize: 15, color: Colors.white)),
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: OutlinedButton(
                  onPressed: _endRest,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('SKIP REST', style: GoogleFonts.oswald(fontSize: 20, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== EXERCISE SCREEN ====================
  Widget _buildExerciseScreen() {
    final exercise = _currentExercise;
    final categoryColor = AppColors.categoryColor(exercise.category);
    final historyAsync = ref.watch(exerciseHistoryProvider(exercise.id));
    final previousSets = historyAsync.value ?? [];
    final prevForSet = previousSets.where((s) => s.setNumber == _currentSetNumber).firstOrNull;

    return SafeArea(
      child: Column(
        children: [
          // ===== TOP BAR =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Elapsed time
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(_elapsedFormatted, style: GoogleFonts.oswald(fontSize: 15, color: AppColors.primary)),
                    ],
                  ),
                ),
                const Spacer(),
                // Sets counter
                Text('$_totalSetsCompleted sets done', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(width: 12),
                // Finish button
                TextButton(
                  onPressed: _checkingOut ? null : _confirmFinish,
                  child: _checkingOut
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('FINISH', style: GoogleFonts.oswald(color: AppColors.success, fontSize: 15)),
                ),
              ],
            ),
          ),

          // ===== PROGRESS BAR =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_exercises.length, (i) {
                    Color dotColor;
                    if (i < _currentExerciseIndex) {
                      dotColor = AppColors.success;
                    } else if (i == _currentExerciseIndex) {
                      dotColor = AppColors.primary;
                    } else {
                      dotColor = AppColors.surfaceLight;
                    }
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _currentExerciseIndex ? 28 : 10,
                      height: 6,
                      decoration: BoxDecoration(color: dotColor, borderRadius: BorderRadius.circular(3)),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  'Exercise ${_currentExerciseIndex + 1} of ${_exercises.length}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ===== EXERCISE CONTENT =====
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(exercise.category, style: TextStyle(color: categoryColor, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),

                  // Exercise name
                  Text(
                    exercise.name.toUpperCase(),
                    style: GoogleFonts.oswald(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.1),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Target info
                  Text(
                    '${exercise.targetSets} x ${exercise.targetReps}  •  ${exercise.restTimeMinutes}min rest',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),

                  // Coach notes (shown on first set)
                  if (_showNotes && exercise.notes.isNotEmpty) ...[
                    GestureDetector(
                      onTap: () => setState(() => _showNotes = false),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.tips_and_updates, size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text('COACH TIP', style: GoogleFonts.oswald(fontSize: 13, color: AppColors.primary, letterSpacing: 1)),
                                const Spacer(),
                                const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(exercise.notes, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Spacer(),

                  // ===== SET INDICATOR =====
                  Text(
                    'SET $_currentSetNumber of ${exercise.targetSets}',
                    style: GoogleFonts.oswald(fontSize: 18, color: AppColors.textSecondary, letterSpacing: 2),
                  ),
                  const SizedBox(height: 4),

                  // Previous performance
                  if (prevForSet != null)
                    Text(
                      'Last time: ${prevForSet.weightUsed.toStringAsFixed(1)} kg x ${prevForSet.repsCompleted}',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                    ),
                  const SizedBox(height: 20),

                  // ===== WEIGHT INPUT =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BigStepper(icon: Icons.remove, onTap: () {
                        final v = (double.tryParse(_weightCtrl.text) ?? 0) - 2.5;
                        _weightCtrl.text = v.clamp(0, 999).toStringAsFixed(1);
                      }),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: _weightCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.oswald(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: '0.0',
                            hintStyle: GoogleFonts.oswald(fontSize: 42, color: AppColors.textMuted),
                            suffixText: 'kg',
                            suffixStyle: GoogleFonts.inter(fontSize: 16, color: AppColors.textMuted),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () => _weightCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _weightCtrl.text.length),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _BigStepper(icon: Icons.add, onTap: () {
                        final v = (double.tryParse(_weightCtrl.text) ?? 0) + 2.5;
                        _weightCtrl.text = v.clamp(0, 999).toStringAsFixed(1);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ===== REPS INPUT =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BigStepper(icon: Icons.remove, onTap: () {
                        final v = (int.tryParse(_repsCtrl.text) ?? 0) - 1;
                        _repsCtrl.text = v.clamp(0, 99).toString();
                      }),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _repsCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.oswald(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: GoogleFonts.oswald(fontSize: 42, color: AppColors.textMuted),
                            suffixText: 'reps',
                            suffixStyle: GoogleFonts.inter(fontSize: 16, color: AppColors.textMuted),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () => _repsCtrl.selection = TextSelection(baseOffset: 0, extentOffset: _repsCtrl.text.length),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _BigStepper(icon: Icons.add, onTap: () {
                        final v = (int.tryParse(_repsCtrl.text) ?? 0) + 1;
                        _repsCtrl.text = v.clamp(0, 99).toString();
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Failure toggle
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _failure = !_failure);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _failure ? AppColors.error.withValues(alpha: 0.15) : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _failure ? AppColors.error : Colors.transparent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _failure ? Icons.check_box : Icons.check_box_outline_blank,
                            size: 20,
                            color: _failure ? AppColors.error : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text('Hit failure',
                              style: TextStyle(color: _failure ? AppColors.error : AppColors.textMuted, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // ===== NAV ARROWS =====
                  Row(
                    children: [
                      if (_currentExerciseIndex > 0)
                        IconButton(
                          onPressed: _prevExercise,
                          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textMuted),
                          tooltip: 'Previous exercise',
                        )
                      else
                        const SizedBox(width: 48),
                      const Spacer(),
                      if (!_isLastExercise)
                        TextButton(
                          onPressed: _skipExercise,
                          child: Row(
                            children: [
                              Text('Skip', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                            ],
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ===== LOG BUTTON =====
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _isLogging ? null : _logSet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isWorkoutDone && _totalSetsCompleted > 0 ? AppColors.gold : AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLogging
                    ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : Text(
                        _isWorkoutDone && _totalSetsCompleted > 0 ? 'LOG & FINISH' : 'LOG SET',
                        style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigStepper extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _BigStepper({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 24),
      ),
    );
  }
}
