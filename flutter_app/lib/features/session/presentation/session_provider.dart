import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/session_models.dart';
import '../data/session_repository.dart';

final activeSessionProvider = FutureProvider<ActiveSession?>((ref) async {
  return ref.watch(sessionRepositoryProvider).getActiveSession();
});

final historyProvider = FutureProvider<List<SessionHistory>>((ref) async {
  return ref.watch(sessionRepositoryProvider).getHistory();
});

final exerciseHistoryProvider = FutureProvider.family<List<PreviousSet>, String>((ref, exerciseId) async {
  return ref.watch(sessionRepositoryProvider).getExerciseHistory(exerciseId);
});

final personalRecordsProvider = FutureProvider<List<PersonalRecord>>((ref) async {
  return ref.watch(sessionRepositoryProvider).getPersonalRecords();
});

final sessionDetailProvider = FutureProvider.family<SessionDetail, String>((ref, sessionId) async {
  return ref.watch(sessionRepositoryProvider).getSessionDetails(sessionId);
});
