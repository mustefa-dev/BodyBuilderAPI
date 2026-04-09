class WorkoutPlan {
  final String id;
  final String name;
  final String description;

  WorkoutPlan({required this.id, required this.name, required this.description});

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
    );
  }
}

class WorkoutDay {
  final String id;
  final String planId;
  final int dayNumber;
  final String title;

  WorkoutDay({required this.id, required this.planId, required this.dayNumber, required this.title});

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      id: json['id'] as String,
      planId: json['planId'] as String,
      dayNumber: json['dayNumber'] as int,
      title: json['title'] as String,
    );
  }
}

class DayExercise {
  final String id;
  final String name;
  final String category;
  final int targetSets;
  final String targetReps;
  final double restTimeMinutes;
  final String notes;

  DayExercise({
    required this.id,
    required this.name,
    required this.category,
    required this.targetSets,
    required this.targetReps,
    required this.restTimeMinutes,
    required this.notes,
  });

  int get restTimeSeconds => (restTimeMinutes * 60).round();

  factory DayExercise.fromJson(Map<String, dynamic> json) {
    return DayExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? '',
      targetSets: json['targetSets'] as int,
      targetReps: json['targetReps'] as String,
      restTimeMinutes: (json['restTimeMinutes'] as num).toDouble(),
      notes: json['notes'] as String? ?? '',
    );
  }
}
