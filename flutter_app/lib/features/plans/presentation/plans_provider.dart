import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';
import '../data/plans_repository.dart';

final plansProvider = FutureProvider<List<WorkoutPlan>>((ref) async {
  return ref.watch(plansRepositoryProvider).getPlans();
});

final planDaysProvider = FutureProvider.family<List<WorkoutDay>, String>((ref, planId) async {
  return ref.watch(plansRepositoryProvider).getPlanDays(planId);
});

final dayExercisesProvider = FutureProvider.family<List<DayExercise>, String>((ref, dayId) async {
  return ref.watch(plansRepositoryProvider).getDayExercises(dayId);
});
