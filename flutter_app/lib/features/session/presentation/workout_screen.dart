import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/premium.dart';
import '../../plans/data/models.dart';
import '../../plans/presentation/plans_provider.dart';
import '../data/session_models.dart';
import '../data/session_repository.dart';
import 'session_provider.dart';

// ====================================================================
//  STEP-BY-STEP GUIDED WORKOUT
//  Flow: ExerciseIntro -> LogSet -> RestTimer -> (repeat) -> Complete
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

  // Elapsed time is tracked for the check-out duration calculation

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

      if (_isLastSet && _isLastExercise) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('End workout?', style: GoogleFonts.lexend(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('$_totalSets sets completed so far.', style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL', style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('FINISH', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700)),
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
      backgroundColor: _phase == WorkoutPhase.resting ? _restBgColor : AppColors.background,
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('Could not load exercises', style: GoogleFonts.inter(color: AppColors.error)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(dayExercisesProvider(widget.dayId)),
                child: Text('RETRY', style: GoogleFonts.inter(color: AppColors.primary)),
              ),
            ],
          ),
        ),
        data: (exercises) {
          if (_exercises.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _onExercisesLoaded(exercises));
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          return switch (_phase) {
            WorkoutPhase.loading => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            WorkoutPhase.exerciseIntro => _buildIntro(),
            WorkoutPhase.logSet => _buildLogSet(),
            WorkoutPhase.resting => _buildRest(),
            WorkoutPhase.finished => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          };
        },
      ),
    );
  }

  // ====================================================================
  //  TOP BAR - KineticLogo + X
  // ====================================================================
  Widget _topBar({Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const KineticLogo(size: 20),
          const Spacer(),
          GestureDetector(
            onTap: _checkingOut ? null : _confirmFinish,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.textPrimary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.close_rounded, color: iconColor ?? AppColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
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
    final completionPct = _exercises.isNotEmpty ? ((_exIndex / _exercises.length) * 100).round() : 0;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SafeArea(
        child: Column(
          children: [
            _topBar(),

            // Progress line: "EXERCISE 3 OF 6" left, "50% COMPLETE" right
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'EXERCISE ${_exIndex + 1} OF ${_exercises.length}',
                    style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1),
                  ),
                  const Spacer(),
                  Text(
                    '$completionPct% COMPLETE',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Exercise image area (dark container with gradient + name)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.15),
                    AppColors.surfaceLow,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.fitness_center_rounded, size: 64, color: color.withValues(alpha: 0.25)),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ex.category.toUpperCase(),
                        style: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Exercise name HUGE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ex.name,
                  style: GoogleFonts.lexend(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.02 * 28,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Three stat boxes: SETS, REPS, REST
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _statBox('SETS', '${ex.targetSets}', color)),
                  const SizedBox(width: 8),
                  Expanded(child: _statBox('REPS', ex.targetReps, AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  Expanded(child: _statBox('REST', '${ex.restTimeSeconds}s', AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // LAST TIME card
            if (prevSets.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.history_rounded, color: AppColors.textMuted, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LAST TIME', style: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.5)),
                          const SizedBox(height: 2),
                          Text(
                            '${prevSets.first.weightUsed.toStringAsFixed(0)}kg x ${prevSets.first.repsCompleted} reps',
                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // COACH TIP
            if (ex.notes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SurfaceCard(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('COACH TIP', style: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1.5)),
                            const SizedBox(height: 4),
                            Text(ex.notes, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(),

            // START EXERCISE button
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
              child: LimeButton(
                label: 'START EXERCISE',
                icon: Icons.arrow_forward_rounded,
                height: 60,
                onPressed: _startSets,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color valueColor) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.5)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.lexend(fontSize: 24, fontWeight: FontWeight.w900, color: valueColor, height: 1),
          ),
        ],
      ),
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
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  _topBar(),

                  // "SET 2 of 3" in lime
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SET $_setNum of ${ex.targetSets}',
                        style: GoogleFonts.lexend(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Exercise name huge bold
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        ex.name,
                        style: GoogleFonts.lexend(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.02 * 28,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PREVIOUS BEST with lime bar
                  if (prev != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SurfaceCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('PREVIOUS BEST', style: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.5)),
                                const SizedBox(height: 2),
                                Text(
                                  '${prev.weightUsed.toStringAsFixed(0)}kg x ${prev.repsCompleted} reps',
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // WEIGHT section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SectionLabel('WEIGHT'),
                        const SizedBox(height: 10),
                        SurfaceCard(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          child: HeavyStepper(
                            controller: _weightCtrl,
                            unit: 'kg',
                            decimal: true,
                            onMinus: () {
                              final v = (double.tryParse(_weightCtrl.text) ?? 0) - 2.5;
                              setState(() => _weightCtrl.text = v.clamp(0, 999).toStringAsFixed(1));
                            },
                            onPlus: () {
                              final v = (double.tryParse(_weightCtrl.text) ?? 0) + 2.5;
                              setState(() => _weightCtrl.text = v.clamp(0, 999).toStringAsFixed(1));
                            },
                            extraButtons: [
                              _quickAdjustBtn('-2.5', () {
                                final v = (double.tryParse(_weightCtrl.text) ?? 0) - 2.5;
                                setState(() => _weightCtrl.text = v.clamp(0, 999).toStringAsFixed(1));
                              }),
                              const SizedBox(width: 10),
                              _quickAdjustBtn('+2.5', () {
                                final v = (double.tryParse(_weightCtrl.text) ?? 0) + 2.5;
                                setState(() => _weightCtrl.text = v.clamp(0, 999).toStringAsFixed(1));
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TARGET REPS section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SectionLabel('TARGET REPS'),
                        const SizedBox(height: 10),
                        SurfaceCard(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          child: HeavyStepper(
                            controller: _repsCtrl,
                            onMinus: () {
                              final v = (int.tryParse(_repsCtrl.text) ?? 0) - 1;
                              setState(() => _repsCtrl.text = v.clamp(0, 99).toString());
                            },
                            onPlus: () {
                              final v = (int.tryParse(_repsCtrl.text) ?? 0) + 1;
                              setState(() => _repsCtrl.text = v.clamp(0, 99).toString());
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TO FAILURE toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _failure = !_failure);
                      },
                      child: SurfaceCard(
                        color: _failure ? AppColors.error.withValues(alpha: 0.1) : AppColors.surfaceLow,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _failure ? AppColors.error.withValues(alpha: 0.15) : AppColors.surfaceHigh,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.bolt_rounded,
                                color: _failure ? AppColors.error : AppColors.textMuted,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'TO FAILURE',
                                style: GoogleFonts.lexend(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _failure ? AppColors.error : AppColors.textSecondary,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 26,
                              decoration: BoxDecoration(
                                color: _failure ? AppColors.error : AppColors.surfaceHigh,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 200),
                                alignment: _failure ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.textPrimary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Decorative dumbbell icon
                  Icon(Icons.fitness_center_rounded, size: 28, color: AppColors.surfaceHigh),

                  const Spacer(),

                  // DONE button
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
                    child: LimeButton(
                      label: 'DONE \u2713',
                      height: 64,
                      isLoading: _isLogging,
                      onPressed: _logSet,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickAdjustBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  // ====================================================================
  //  PHASE 3: REST TIMER
  // ====================================================================
  Color get _restBgColor {
    if (_restRemaining <= 5) return AppColors.error.withValues(alpha: 0.15);
    return AppColors.background;
  }

  Widget _buildRest() {
    final mins = _restRemaining ~/ 60;
    final secs = _restRemaining % 60;
    final progress = _restTotal > 0 ? (_restTotal - _restRemaining) / _restTotal : 0.0;

    // What comes next
    String nextLabel;
    String nextRight;
    if (_isLastSet) {
      if (_isLastExercise) {
        nextLabel = 'WORKOUT COMPLETE';
        nextRight = '';
      } else {
        nextLabel = _exercises[_exIndex + 1].name;
        nextRight = 'NEXT EXERCISE';
      }
    } else {
      final w = _weightCtrl.text.isNotEmpty ? '${double.tryParse(_weightCtrl.text)?.toStringAsFixed(0) ?? ''}kg' : '';
      nextLabel = 'Set ${_setNum + 1} \u2022 $w';
      nextRight = 'TARGET ${_ex.targetReps} REPS';
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: SafeArea(
        child: Column(
          children: [
            _topBar(iconColor: _restRemaining <= 5 ? AppColors.error : null),

            // "CURRENT SESSION" label, exercise name, "2/5 SETS DONE" right
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('CURRENT SESSION'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _ex.name,
                          style: GoogleFonts.lexend(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.02 * 20,
                          ),
                        ),
                      ),
                      Text(
                        '$_setNum/${_ex.targetSets} SETS DONE',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceHigh,
                  valueColor: AlwaysStoppedAnimation(_restRemaining <= 5 ? AppColors.error : AppColors.primary),
                ),
              ),
            ),

            const Spacer(flex: 2),

            // "RESTING" label
            Text(
              'RESTING',
              style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 3),
            ),
            const SizedBox(height: 8),

            // HUGE timer numbers
            Text(
              '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
              style: GoogleFonts.lexend(
                fontSize: 80,
                fontWeight: FontWeight.w900,
                color: _restRemaining <= 5 ? AppColors.error : AppColors.textPrimary,
                height: 1,
                letterSpacing: -0.02 * 80,
              ),
            ),

            const Spacer(flex: 1),

            // UP NEXT card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SurfaceCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('UP NEXT', style: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 1.5)),
                          const SizedBox(height: 2),
                          Text(nextLabel, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                    if (nextRight.isNotEmpty)
                      Text(nextRight, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 2),

            // +15S and SKIP buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _restRemaining += 15;
                        _restTotal += 15;
                      }),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('+15S', style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _skipRest,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('SKIP', style: GoogleFonts.lexend(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // RESUME TRAINING button
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
              child: LimeButton(
                label: 'RESUME TRAINING',
                height: 60,
                onPressed: _skipRest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
