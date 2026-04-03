using System;
using System.Collections.Generic;

namespace BodyBuilderAPI.Entities
{
    public class WorkoutPlan
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Name { get; set; }
        public string Description { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Navigation
        public ICollection<WorkoutDay> Days { get; set; }
    }
}
