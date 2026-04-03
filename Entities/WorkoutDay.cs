using System;
using System.Collections.Generic;

namespace BodyBuilderAPI.Entities
{
    public class WorkoutDay
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public Guid PlanId { get; set; }
        public int DayNumber { get; set; }
        public string Title { get; set; } // e.g., "Day 1 Workout"

        // Navigation
        public WorkoutPlan Plan { get; set; }
        public ICollection<WorkoutDayExercise> Exercises { get; set; }
    }
}
