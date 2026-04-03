using System;

namespace BodyBuilderAPI.Entities
{
    public class WorkoutDayExercise
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid WorkoutDayId { get; set; }
        public Guid ExerciseId { get; set; }
        
        // Target prescribed by Jeremy Ethier's PDF
        public int TargetSets { get; set; }
        public string TargetReps { get; set; } // string because it might be "6-8" or "10-15"
        public decimal RestTimeMinutes { get; set; }
        public string Notes { get; set; }

        // Navigation
        public WorkoutDay WorkoutDay { get; set; }
        public Exercise Exercise { get; set; }
    }
}
