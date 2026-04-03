using BodyBuilderAPI.Entities;
using Microsoft.EntityFrameworkCore;

namespace BodyBuilderAPI.DATA
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<WorkoutPlan> WorkoutPlans { get; set; }
        public DbSet<WorkoutDay> WorkoutDays { get; set; }
        public DbSet<Exercise> Exercises { get; set; }
        public DbSet<WorkoutDayExercise> WorkoutDayExercises { get; set; }
        public DbSet<WorkoutSession> WorkoutSessions { get; set; }
        public DbSet<ExerciseRecord> ExerciseRecords { get; set; }
        public DbSet<ProgressiveOverloadHistory> ProgressiveOverloadHistories { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            
            // Put everything in a unique schema so it doesn't conflict with your other projects
            modelBuilder.HasDefaultSchema("workout");
        }
    }
}
