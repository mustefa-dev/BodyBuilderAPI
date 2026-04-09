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

// ====================================================================
//  STEP-BY-STEP GUIDED WORKOUT
//  Flow: ExerciseIntro → LogSet → RestTimer → (repeat) → Complete
// ====================================================================

enum WorkoutPhase { loading, exerciseIntro, logSet, resting, finished }

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

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> with TickerProviderStateMixin {
  // Phase
  WorkoutPhase _phase = WorkoutPhase.loading;

  // Exercises
  List<DayExercise> _exercises = [];
  int _exIndex = 0;
  int _setNum = 1;

  // Input
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  bool _failure = false;
  bool _isLogging = false;

  // Timer
  late DateTime _startTime;
  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;

  // Rest
  Timer? _restTimer;
  int _restTotal = 0;
  int _restRemaining = 0;

  // Stats
  int _totalSets = 0;
  bool _checkingOut = false;

  // Animation
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  DayExercise get _ex => _exercises[_exIndex];
  bool get _isLastSet => _setNum >= _ex.targetSets;
  bool get _isLastExercise => _exIndex >= _exercises.length - 1;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = DateTime.now().difference(_startTime));
    });
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _fadeCtrl.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  String get _elapsedStr {
    final m = _elapsed.inMinutes;
    final s = _elapsed.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _onExercisesLoaded(List<DayExercise> exercises) {
    _exercises = exercises;
    _goToExerciseIntro(0);
  }

  void _goToExerciseIntro(int index) {
    _fadeCtrl.reset();
    setState(() {
      _exIndex = index;
      _setNum = 1;
      _phase = WorkoutPhase.exerciseIntro;
    });
    _fadeCtrl.forward();
  }

  void _startSets() {
    _fadeCtrl.reset();
    _prefill();
    setState(() => _phase = WorkoutPhase.logSet);
    _fadeCtrl.forward();
  }

  void _prefill() {
    final history = ref.read(exerciseHistoryProvider(_ex.id)).value ?? [];
    final prev = history.where((s) => s.setNumber == _setNum).firstOrNull;
    _weightCtrl.text = prev?.weightUsed.toStringAsFixed(1) ?? '';
    _repsCtrl.text = prev?.repsCompleted.toString() ?? '';
    _failure = false;
  }

  Future<void> _logSet() async {
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final r = int.tryParse(_repsCtrl.text) ?? 0;
    if (w <= 0 || r <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter weight and reps')),
      );
      return;
    }

    setState(() => _isLogging = true);
    HapticFeedback.mediumImpact();

    try {
      await ref.read(sessionRepositoryProvider).recordSet(
            widget.sessionId,
            RecordSetRequest(
              workoutDayExerciseId: _ex.id,
              setNumber: _setNum,
              weightUsed: w,
              repsCompleted: r,
              isFailureReached: _failure,
            ),
          );

      setState(() {
        _isLogging = false;
        _totalSets++;
      });

      // What's next?
      if (_isLastSet && _isLastExercise) {
        // Workout done!
        _finishWorkout();
      } else {
        _startRest();
      }
    } catch (e) {
      setState(() => _isLogging = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Try again.')),
        );
      }
    }
  }

  void _startRest() {
    _fadeCtrl.reset();
    final secs = _ex.restTimeSeconds;
    setState(() {
      _phase = WorkoutPhase.resting;
      _restTotal = secs;
      _restRemaining = secs;
    });
    _fadeCtrl.forward();

    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_restRemaining <= 1) {
        _restTimer?.cancel();
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 250), () => HapticFeedback.heavyImpact());
        Future.delayed(const Duration(milliseconds: 500), () => HapticFeedback.heavyImpact());
        _advanceAfterRest();
      } else {
        setState(() => _restRemaining--);
        if (_restRemaining <= 5) HapticFeedback.lightImpact();
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    _advanceAfterRest();
  }

  void _advanceAfterRest() {
    if (_isLastSet) {
      _goToExerciseIntro(_exIndex + 1);
    } else {
      _fadeCtrl.reset();
      setState(() {
        _setNum++;
        _phase = WorkoutPhase.logSet;
      });
      _prefill();
      _fadeCtrl.forward();
    }
  }

  Future<void> _finishWorkout() async {
    setState(() => _checkingOut = true);
    try {
      final totalMins = await ref.read(sessionRepositoryProvider).checkOut(widget.sessionId);
      if (mounted) {
        context.go('/workout/summary?duration=${totalMins.toStringAsFixed(1)}&sets=$_totalSets');
      }
    } catch (e) {
      setState(() => _checkingOut = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to end workout.')),
        );
      }
    }
  }

  Future<void> _confirmFinish() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('End workout?', style: GoogleFonts.oswald(color: AppColors.textPrimary)),
        content: Text('$_totalSets sets completed so far.'),
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
    if (ok == true) _finishWorkout();
  }

  // ====================================================================
  //  BUILD
  // ====================================================================
  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(dayExercisesProvider(widget.dayId));

    return Scaffold(
      backgroundColor: _phase == WorkoutPhase.resting ? _restColor : AppColors.background,
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Could not load exercises', style: TextStyle(color: AppColors.error)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(dayExercisesProvider(widget.dayId)),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
        data: (exercises) {
          if (_exercises.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _onExercisesLoaded(exercises));
            return const Center(child: CircularProgressIndicator());
          }
          return switch (_phase) {
            WorkoutPhase.loading => const Center(child: CircularProgressIndicator()),
            WorkoutPhase.exerciseIntro => _buildIntro(),
            WorkoutPhase.logSet => _buildLogSet(),
            WorkoutPhase.resting => _buildRest(),
            WorkoutPhase.finished => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
    );
  }

  // ====================================================================
  //  TOP BAR (shared across phases)
  // ====================================================================
  Widget _topBar({Color? textColor}) {
    final tc = textColor ?? AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          // Timer
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: tc.withValues(alpha: 0.6)),
              const SizedBox(width: 4),
              Text(_elapsedStr, style: GoogleFonts.oswald(fontSize: 15, color: tc.withValues(alpha: 0.8))),
            ],
          ),
          const Spacer(),
          // Progress
          Text(
            '${_exIndex + 1}/${_exercises.length}',
            style: GoogleFonts.oswald(fontSize: 14, color: tc.withValues(alpha: 0.6)),
          ),
          const SizedBox(width: 12),
          // Finish
          GestureDetector(
            onTap: _checkingOut ? null : _confirmFinish,
            child: Text('END', style: GoogleFonts.oswald(fontSize: 15, color: tc.withValues(alpha: 0.6))),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  //  PROGRESS DOTS
  // ====================================================================
  Widget _progressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_exercises.length, (i) {
        final done = i < _exIndex;
        final current = i == _exIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: current ? 24 : 8,
          height: 6,
          decoration: BoxDecoration(
            color: done ? AppColors.success : (current ? AppColors.primary : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // ====================================================================
  //  PHASE 1: EXERCISE INTRO
  // ====================================================================
  Widget _buildIntro() {
    final ex = _ex;
    final color = AppColors.categoryColor(ex.category);
    final historyAsync = ref.watch(exerciseHistoryProvider(ex.id));
    final prevSets = historyAsync.value ?? [];

    return FadeTransition(
      opacity: _fadeAnim,
      child: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _progressDots(),
            const Spacer(flex: 2),

            // Category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(ex.category.toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 16),

            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                ex.name,
                style: GoogleFonts.oswald(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.1),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),

            // Target
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _miniStat(Icons.repeat, '${ex.targetSets} sets'),
                  _divider(),
                  _miniStat(Icons.fitness_center, '${ex.targetReps} reps'),
                  _divider(),
                  _miniStat(Icons.timer, '${ex.restTimeMinutes}m rest'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Previous performance
            if (prevSets.isNotEmpty) ...[
              Text('LAST SESSION', style: GoogleFonts.oswald(fontSize: 12, color: AppColors.textMuted, letterSpacing: 2)),
              const SizedBox(height: 8),
              ...prevSets.map((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      'Set ${s.setNumber}:  ${s.weightUsed.toStringAsFixed(1)} kg  x  ${s.repsCompleted} reps',
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // Notes
            if (ex.notes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tips_and_updates, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(ex.notes, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(flex: 3),

            // START button
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _startSets,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('START  →', style: GoogleFonts.oswald(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(width: 1, height: 16, color: AppColors.surfaceLight),
    );
  }

  // ====================================================================
  //  PHASE 2: LOG SET
  // ====================================================================
  Widget _buildLogSet() {
    final ex = _ex;
    final historyAsync = ref.watch(exerciseHistoryProvider(ex.id));
    final prevSets = historyAsync.value ?? [];
    final prev = prevSets.where((s) => s.setNumber == _setNum).firstOrNull;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SafeArea(
        child: Column(
          children: [
            _topBar(),
            const SizedBox(height: 8),

            // Exercise name (small)
            Text(ex.name, style: GoogleFonts.oswald(fontSize: 16, color: AppColors.textMuted)),
            const SizedBox(height: 4),

            // Set indicator
            Text(
              'SET $_setNum  of  ${ex.targetSets}',
              style: GoogleFonts.oswald(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 2),
            ),
            const SizedBox(height: 4),

            // Target reps
            Text('Target: ${ex.targetReps} reps', style: GoogleFonts.inter(fontSize: 14, color: AppColors.primary)),

            if (prev != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last: ${prev.weightUsed.toStringAsFixed(1)} kg x ${prev.repsCompleted}',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
              ),
            ],

            // Set dots
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(ex.targetSets, (i) {
                final done = i + 1 < _setNum;
                final current = i + 1 == _setNum;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.success : (current ? AppColors.primary : AppColors.surfaceLight),
                    border: current ? Border.all(color: AppColors.primary, width: 2) : null,
                  ),
                );
              }),
            ),

            const Spacer(),

            // WEIGHT
            Text('WEIGHT', style: GoogleFonts.oswald(fontSize: 13, color: AppColors.textMuted, letterSpacing: 2)),
            const SizedBox(height: 8),
            _numberInput(
              controller: _weightCtrl,
              suffix: 'kg',
              decimal: true,
              onMinus: () {
                final v = (double.tryParse(_weightCtrl.text) ?? 0) - 2.5;
                setState(() => _weightCtrl.text = v.clamp(0, 999).toStringAsFixed(1));
              },
              onPlus: () {
                final v = (double.tryParse(_weightCtrl.text) ?? 0) + 2.5;
                setState(() => _weightCtrl.text = v.clamp(0, 999).toStringAsFixed(1));
              },
            ),
            const SizedBox(height: 24),

            // REPS
            Text('REPS', style: GoogleFonts.oswald(fontSize: 13, color: AppColors.textMuted, letterSpacing: 2)),
            const SizedBox(height: 8),
            _numberInput(
              controller: _repsCtrl,
              suffix: '',
              decimal: false,
              onMinus: () {
                final v = (int.tryParse(_repsCtrl.text) ?? 0) - 1;
                setState(() => _repsCtrl.text = v.clamp(0, 99).toString());
              },
              onPlus: () {
                final v = (int.tryParse(_repsCtrl.text) ?? 0) + 1;
                setState(() => _repsCtrl.text = v.clamp(0, 99).toString());
              },
            ),
            const SizedBox(height: 16),

            // Failure toggle
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _failure = !_failure);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _failure ? AppColors.error.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _failure ? AppColors.error : AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _failure ? Icons.local_fire_department : Icons.local_fire_department_outlined,
                      color: _failure ? AppColors.error : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reached failure',
                      style: TextStyle(color: _failure ? AppColors.error : AppColors.textMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // LOG BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
              child: SizedBox(
                width: double.infinity,
                height: 72,
                child: ElevatedButton(
                  onPressed: _isLogging ? null : _logSet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    disabledBackgroundColor: AppColors.success.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 4,
                  ),
                  child: _isLogging
                      ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 28, color: Colors.white),
                            const SizedBox(width: 10),
                            Text('DONE', style: GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberInput({
    required TextEditingController controller,
    required String suffix,
    required bool decimal,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Minus
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onMinus();
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.remove, color: AppColors.textSecondary, size: 28),
          ),
        ),
        const SizedBox(width: 16),
        // Input
        SizedBox(
          width: 150,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            textAlign: TextAlign.center,
            style: GoogleFonts.oswald(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: decimal ? '0.0' : '0',
              hintStyle: GoogleFonts.oswald(fontSize: 48, color: AppColors.textMuted.withValues(alpha: 0.3)),
              suffixText: suffix.isNotEmpty ? suffix : null,
              suffixStyle: GoogleFonts.inter(fontSize: 18, color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onTap: () => controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length),
          ),
        ),
        const SizedBox(width: 16),
        // Plus
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onPlus();
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.add, color: AppColors.textSecondary, size: 28),
          ),
        ),
      ],
    );
  }

  // ====================================================================
  //  PHASE 3: REST TIMER
  // ====================================================================
  Color get _restColor {
    if (_restRemaining <= 5) return const Color(0xFFB91C1C);
    if (_restRemaining <= 15) return const Color(0xFFB45309);
    return const Color(0xFF1E3A5F);
  }

  Widget _buildRest() {
    final mins = _restRemaining ~/ 60;
    final secs = _restRemaining % 60;
    final progress = _restTotal > 0 ? (_restTotal - _restRemaining) / _restTotal : 0.0;

    // What comes next
    String nextLabel;
    if (_isLastSet) {
      if (_isLastExercise) {
        nextLabel = 'WORKOUT COMPLETE!';
      } else {
        nextLabel = 'Up next: ${_exercises[_exIndex + 1].name}';
      }
    } else {
      nextLabel = 'Next: Set ${_setNum + 1} of ${_ex.targetSets}';
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: SafeArea(
        child: Column(
          children: [
            _topBar(textColor: Colors.white),
            const Spacer(flex: 2),

            // "REST" label
            Text('REST', style: GoogleFonts.oswald(fontSize: 20, color: Colors.white60, letterSpacing: 6)),
            const SizedBox(height: 8),

            // Timer
            Text(
              '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
              style: GoogleFonts.oswald(fontSize: 96, fontWeight: FontWeight.bold, color: Colors.white, height: 1),
            ),
            const SizedBox(height: 20),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // What's next
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                nextLabel,
                style: GoogleFonts.inter(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),

            const Spacer(flex: 3),

            // +15s / Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  // +15s
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _restRemaining += 15;
                          _restTotal += 15;
                        }),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('+15s', style: GoogleFonts.oswald(fontSize: 18, color: Colors.white70)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Skip
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _skipRest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('SKIP REST  →', style: GoogleFonts.oswald(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
