using System;

namespace BodyBuilderAPI.Entities
{
    public class ExerciseRecord
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid SessionId { get; set; }
        public Guid WorkoutDayExerciseId { get; set; }
        
        public int SetNumber { get; set; }
        public decimal WeightUsed { get; set; }
        public int RepsCompleted { get; set; }
        public bool IsFailureReached { get; set; }
        
        public DateTime SetCompletedAt { get; set; } = DateTime.UtcNow;
        public int RestTimeTakenSeconds { get; set; } // Computed based on previous set completed time
        
        // Navigation
        public WorkoutSession Session { get; set; }
        public WorkoutDayExercise WorkoutDayExercise { get; set; }
    }
}
