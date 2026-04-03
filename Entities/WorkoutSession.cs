using System;
using System.Collections.Generic;

namespace BodyBuilderAPI.Entities
{
    public class WorkoutSession
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid UserId { get; set; }
        public Guid WorkoutDayId { get; set; }
        
        public DateTime CheckInTime { get; set; } = DateTime.UtcNow;
        public DateTime? CheckOutTime { get; set; }
        public double? TotalDurationMinutes { get; set; }
        public string Status { get; set; } = "InProgress"; // InProgress, Completed, Abandoned
        
        // Navigation
        public User User { get; set; }
        public WorkoutDay WorkoutDay { get; set; }
        public ICollection<ExerciseRecord> Records { get; set; }
    }
}
