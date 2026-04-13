class ActiveSession {
  final String id;
  final String workoutDayId;
  final DateTime checkInTime;
  final double elapsedTimeMinutes;
  final int completedSetsCount;

  ActiveSession({
    required this.id,
    required this.workoutDayId,
    required this.checkInTime,
    required this.elapsedTimeMinutes,
    required this.completedSetsCount,
  });

  factory ActiveSession.fromJson(Map<String, dynamic> json) {
    return ActiveSession(
      id: json['id'] as String,
      workoutDayId: json['workoutDayId'] as String,
      checkInTime: DateTime.parse(json['checkInTime'] as String),
      elapsedTimeMinutes: (json['elapsedTimeMinutes'] as num).toDouble(),
      completedSetsCount: json['completedSetsCount'] as int,
    );
  }
}

class RecordSetRequest {
  final String workoutDayExerciseId;
  final int setNumber;
  final double weightUsed;
  final int repsCompleted;
  final bool isFailureReached;

  RecordSetRequest({
    required this.workoutDayExerciseId,
    required this.setNumber,
    required this.weightUsed,
    required this.repsCompleted,
    required this.isFailureReached,
  });

  Map<String, dynamic> toJson() => {
        'workoutDayExerciseId': workoutDayExerciseId,
        'setNumber': setNumber,
        'weightUsed': weightUsed,
        'repsCompleted': repsCompleted,
        'isFailureReached': isFailureReached,
      };
}

class SessionHistory {
  final String id;
  final String title;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double? totalDurationMinutes;

  SessionHistory({
    required this.id,
    required this.title,
    required this.checkInTime,
    this.checkOutTime,
    this.totalDurationMinutes,
  });

  factory SessionHistory.fromJson(Map<String, dynamic> json) {
    return SessionHistory(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Workout',
      checkInTime: DateTime.parse(json['checkInTime'] as String),
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime'] as String) : null,
      totalDurationMinutes: (json['totalDurationMinutes'] as num?)?.toDouble(),
    );
  }

  String get formattedDuration {
    if (totalDurationMinutes == null) return '--';
    final mins = totalDurationMinutes!.round();
    if (mins >= 60) return '${mins ~/ 60}h ${mins % 60}m';
    return '${mins}m';
  }
}

class PreviousSet {
  final int setNumber;
  final double weightUsed;
  final int repsCompleted;

  PreviousSet({required this.setNumber, required this.weightUsed, required this.repsCompleted});

  factory PreviousSet.fromJson(Map<String, dynamic> json) {
    return PreviousSet(
      setNumber: json['setNumber'] as int,
      weightUsed: (json['weightUsed'] as num).toDouble(),
      repsCompleted: json['repsCompleted'] as int,
    );
  }
}

class SessionExerciseSet {
  final int setNumber;
  final double weightUsed;
  final int repsCompleted;
  final bool isFailureReached;

  SessionExerciseSet({
    required this.setNumber,
    required this.weightUsed,
    required this.repsCompleted,
    required this.isFailureReached,
  });

  factory SessionExerciseSet.fromJson(Map<String, dynamic> json) {
    return SessionExerciseSet(
      setNumber: json['setNumber'] as int,
      weightUsed: (json['weightUsed'] as num).toDouble(),
      repsCompleted: json['repsCompleted'] as int,
      isFailureReached: json['isFailureReached'] as bool? ?? false,
    );
  }
}

class SessionExercise {
  final String exerciseName;
  final String? category;
  final List<SessionExerciseSet> sets;

  SessionExercise({required this.exerciseName, this.category, required this.sets});

  factory SessionExercise.fromJson(Map<String, dynamic> json) {
    return SessionExercise(
      exerciseName: json['exerciseName'] as String? ?? 'Exercise',
      category: json['category'] as String?,
      sets: (json['sets'] as List).map((e) => SessionExerciseSet.fromJson(e)).toList(),
    );
  }
}

class SessionDetail {
  final String id;
  final String title;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final double? totalDurationMinutes;
  final List<SessionExercise> exercises;

  SessionDetail({
    required this.id,
    required this.title,
    required this.checkInTime,
    this.checkOutTime,
    this.totalDurationMinutes,
    required this.exercises,
  });

  factory SessionDetail.fromJson(Map<String, dynamic> json) {
    return SessionDetail(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Workout',
      checkInTime: DateTime.parse(json['checkInTime'] as String),
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime'] as String) : null,
      totalDurationMinutes: (json['totalDurationMinutes'] as num?)?.toDouble(),
      exercises: (json['exercises'] as List).map((e) => SessionExercise.fromJson(e)).toList(),
    );
  }

  String get formattedDuration {
    if (totalDurationMinutes == null) return '--';
    final mins = totalDurationMinutes!.round();
    if (mins >= 60) return '${mins ~/ 60}h ${mins % 60}m';
    return '${mins}m';
  }

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);
}

class PersonalRecord {
  final String name;
  final double personalBestWeight;
  final DateTime dateAchieved;

  PersonalRecord({required this.name, required this.personalBestWeight, required this.dateAchieved});

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      name: json['name'] as String,
      personalBestWeight: (json['personalBestWeight'] as num).toDouble(),
      dateAchieved: DateTime.parse(json['dateAchieved'] as String),
    );
  }
}
