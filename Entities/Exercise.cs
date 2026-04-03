using System;

namespace BodyBuilderAPI.Entities
{
    public class Exercise
    {
        public Guid Id { get; set; } = Guid.NewGuid();
        public string Name { get; set; }
        public string Category { get; set; } // e.g., Legs, Chest, Back
        public string Description { get; set; }
    }
}
