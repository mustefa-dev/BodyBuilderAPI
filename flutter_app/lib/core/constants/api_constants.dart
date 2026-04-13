class ApiConstants {
  static const baseUrl = 'https://clinic.taco5k.site/api';

  // Auth
  static const login = '/auth/login';
  static const register = '/auth/register';

  // Plans
  static const plans = '/plans';
  static String planDays(String planId) => '/plans/$planId/days';
  static String dayExercises(String dayId) => '/plans/day/$dayId/exercises';

  // Sessions
  static const checkIn = '/workoutsessions/check-in';
  static String recordSet(String sessionId) => '/workoutsessions/$sessionId/record-set';
  static String checkOut(String sessionId) => '/workoutsessions/$sessionId/check-out';
  static const activeSession = '/workoutsessions/active';
  static const sessionHistory = '/workoutsessions/history';
  static String sessionDetails(String sessionId) => '/workoutsessions/$sessionId/details';

  // Progress
  static String exerciseHistory(String exerciseId) => '/progress/history/$exerciseId';
  static const personalRecords = '/progress/personal-records';
}
