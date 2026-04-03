using System;

namespace BodyBuilderAPI.Entities
{
    public class ProgressiveOverloadHistory
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid UserId { get; set; }
        public Guid ExerciseId { get; set; }
        
        public decimal OneRepMax { get; set; } // Estimated 1RM calculated by Brzycki formula
        public decimal PersonalBestWeight { get; set; } // Absolute max weight lifted
        public DateTime DateAchieved { get; set; } = DateTime.UtcNow;
        
        // Navigation
        public User User { get; set; }
        public Exercise Exercise { get; set; }
    }
}
