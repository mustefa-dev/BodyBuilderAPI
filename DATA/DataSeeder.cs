using System;
using System.Linq;
using BodyBuilderAPI.DATA;
using BodyBuilderAPI.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace BodyBuilderAPI.DATA
{
    public static class DataSeeder
    {
        public static void SeedData(IServiceProvider serviceProvider)
        {
            using var context = new AppDbContext(
                serviceProvider.GetRequiredService<DbContextOptions<AppDbContext>>());

            // Check if the plan already exists
            if (context.WorkoutPlans.Any(p => p.Name == "Jeremy Ethier 5-Day Full Body Workout Plan"))
            {
                return; // DB has been seeded
            }

            var planId = Guid.NewGuid();
            var plan = new WorkoutPlan
            {
                Id = planId,
                Name = "Jeremy Ethier 5-Day Full Body Workout Plan",
                Description = "A 5-day full body workout split designed to maximize your gains. For the first 2 weeks, take it easy and avoid pushing too close to failure (RPE 7-8). After 2 weeks, start pushing harder."
            };

            context.WorkoutPlans.Add(plan);

            // Seed Day 1
            var day1Id = Guid.NewGuid();
            var day1 = new WorkoutDay
            {
                Id = day1Id,
                PlanId = planId,
                DayNumber = 1,
                Title = "Day 1 Workout"
            };
            context.WorkoutDays.Add(day1);

            // Day 1 Exercises
            var backSquat = new Exercise { Id = Guid.NewGuid(), Name = "Barbell Back Squat", Category = "Legs" };
            var inclinePress = new Exercise { Id = Guid.NewGuid(), Name = "Low Incline Dumbbell Press", Category = "Chest" };
            var legCurl = new Exercise { Id = Guid.NewGuid(), Name = "Seated Leg Curls", Category = "Legs" };
            var latPulldown = new Exercise { Id = Guid.NewGuid(), Name = "Lat Pulldown", Category = "Back" };
            var cableCurl = new Exercise { Id = Guid.NewGuid(), Name = "Behind Body Cable Curls", Category = "Biceps" };
            
            context.Exercises.AddRange(backSquat, inclinePress, legCurl, latPulldown, cableCurl);

            context.WorkoutDayExercises.AddRange(
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day1Id, ExerciseId = backSquat.Id, TargetSets = 3, TargetReps = "6-8", RestTimeMinutes = 2.5m, Notes = "Experiment with foot stance, squat down to at least parallel." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day1Id, ExerciseId = inclinePress.Id, TargetSets = 3, TargetReps = "8-10", RestTimeMinutes = 2.0m, Notes = "Set bench 1-2 notches up from bottom, keep chest up." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day1Id, ExerciseId = legCurl.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.5m, Notes = "Keep toes pointed straight up, control the weight." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day1Id, ExerciseId = latPulldown.Id, TargetSets = 3, TargetReps = "8-10", RestTimeMinutes = 2.0m, Notes = "Grip outside shoulder width, pull bar to just under chin." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day1Id, ExerciseId = cableCurl.Id, TargetSets = 3, TargetReps = "10-12", RestTimeMinutes = 1.5m, Notes = "Take small step forward from cable, let arm hang behind you." }
            );

            // Seed Day 2
            var day2Id = Guid.NewGuid();
            var day2 = new WorkoutDay
            {
                Id = day2Id,
                PlanId = planId,
                DayNumber = 2,
                Title = "Day 2 Workout"
            };
            context.WorkoutDays.Add(day2);

            var benchPress = new Exercise { Id = Guid.NewGuid(), Name = "Barbell Bench Press", Category = "Chest" };
            var rdl = new Exercise { Id = Guid.NewGuid(), Name = "Barbell RDL", Category = "Legs" };
            var dbRow = new Exercise { Id = Guid.NewGuid(), Name = "DB Chest Supported Row", Category = "Back" };
            var cableLateral = new Exercise { Id = Guid.NewGuid(), Name = "Cable Lateral Raises", Category = "Shoulders" };
            var ropeExt = new Exercise { Id = Guid.NewGuid(), Name = "Overhead Rope Extensions", Category = "Triceps" };

            context.Exercises.AddRange(benchPress, rdl, dbRow, cableLateral, ropeExt);

            context.WorkoutDayExercises.AddRange(
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day2Id, ExerciseId = benchPress.Id, TargetSets = 3, TargetReps = "6-8", RestTimeMinutes = 2.5m, Notes = "" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day2Id, ExerciseId = rdl.Id, TargetSets = 3, TargetReps = "8-10", RestTimeMinutes = 2.5m, Notes = "" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day2Id, ExerciseId = dbRow.Id, TargetSets = 3, TargetReps = "8-10", RestTimeMinutes = 2.0m, Notes = "Mid/Upper back focus" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day2Id, ExerciseId = cableLateral.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.5m, Notes = "" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day2Id, ExerciseId = ropeExt.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.5m, Notes = "" }
            );

            // Seed Day 3
            var day3Id = Guid.NewGuid();
            context.WorkoutDays.Add(new WorkoutDay { Id = day3Id, PlanId = planId, DayNumber = 3, Title = "Day 3 Workout" });
            
            var pullups = new Exercise { Id = Guid.NewGuid(), Name = "Pull-ups", Category = "Back" };
            var legPress = new Exercise { Id = Guid.NewGuid(), Name = "Leg Press", Category = "Legs" };
            var cableFlyes = new Exercise { Id = Guid.NewGuid(), Name = "Seated Mid-Chest Cable Flyes", Category = "Chest" };
            var calfRaises = new Exercise { Id = Guid.NewGuid(), Name = "Standing Weighted Calf Raises", Category = "Calves" };
            var hammerCurls = new Exercise { Id = Guid.NewGuid(), Name = "Hammer Curls", Category = "Biceps" };
            
            context.Exercises.AddRange(pullups, legPress, cableFlyes, calfRaises, hammerCurls);
            
            context.WorkoutDayExercises.AddRange(
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day3Id, ExerciseId = pullups.Id, TargetSets = 3, TargetReps = "6-10", RestTimeMinutes = 2m, Notes = "" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day3Id, ExerciseId = legPress.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 2m, Notes = "Quad-focused" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day3Id, ExerciseId = cableFlyes.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.5m, Notes = "" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day3Id, ExerciseId = calfRaises.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.5m, Notes = "" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day3Id, ExerciseId = hammerCurls.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.5m, Notes = "" }
            );

            // Seed Day 4
            var day4Id = Guid.NewGuid();
            context.WorkoutDays.Add(new WorkoutDay { Id = day4Id, PlanId = planId, DayNumber = 4, Title = "Day 4 Workout" });
            
            var bulgarian = new Exercise { Id = Guid.NewGuid(), Name = "Bulgarian Split Squat", Category = "Legs" };
            var chestDips = new Exercise { Id = Guid.NewGuid(), Name = "Chest Dips", Category = "Chest" };
            var legExt = new Exercise { Id = Guid.NewGuid(), Name = "Seated Leg Extensions", Category = "Legs" };
            var latRow = new Exercise { Id = Guid.NewGuid(), Name = "Lat Focused Cable Row", Category = "Back" };
            var rearDelt = new Exercise { Id = Guid.NewGuid(), Name = "Rear Delt Cable Fly", Category = "Shoulders" };
            var pushdown = new Exercise { Id = Guid.NewGuid(), Name = "Cable Pushdowns", Category = "Triceps" };
            
            context.Exercises.AddRange(bulgarian, chestDips, legExt, latRow, rearDelt, pushdown);
            
            context.WorkoutDayExercises.AddRange(
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day4Id, ExerciseId = bulgarian.Id, TargetSets = 3, TargetReps = "8-10", RestTimeMinutes = 2m, Notes = "Glute Focused" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day4Id, ExerciseId = chestDips.Id, TargetSets = 3, TargetReps = "8-12", RestTimeMinutes = 2m, Notes = "" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day4Id, ExerciseId = legExt.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.5m, Notes = "" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day4Id, ExerciseId = latRow.Id, TargetSets = 3, TargetReps = "10-12", RestTimeMinutes = 1.5m, Notes = "" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day4Id, ExerciseId = rearDelt.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.5m, Notes = "" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day4Id, ExerciseId = pushdown.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.5m, Notes = "Elbow friendly" }
            );

            // Seed Day 5
            var day5Id = Guid.NewGuid();
            context.WorkoutDays.Add(new WorkoutDay { Id = day5Id, PlanId = planId, DayNumber = 5, Title = "Day 5 Workout" });
            
            var dbPress = new Exercise { Id = Guid.NewGuid(), Name = "Seated Dumbbell Shoulder Press", Category = "Shoulders" };
            var inclineLat = new Exercise { Id = Guid.NewGuid(), Name = "Lying Incline Lateral Raises", Category = "Shoulders" };
            var decPushup = new Exercise { Id = Guid.NewGuid(), Name = "Decline Push-ups", Category = "Chest" };
            var seatedRow = new Exercise { Id = Guid.NewGuid(), Name = "Seated Cable Row", Category = "Back" };
            var incCurl = new Exercise { Id = Guid.NewGuid(), Name = "Incline Dumbbell Curls", Category = "Biceps" };
            
            context.Exercises.AddRange(dbPress, inclineLat, decPushup, seatedRow, incCurl);
            
            context.WorkoutDayExercises.AddRange(
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day5Id, ExerciseId = dbPress.Id, TargetSets = 3, TargetReps = "8-10", RestTimeMinutes = 2m, Notes = "" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day5Id, ExerciseId = inclineLat.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.5m, Notes = "" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day5Id, ExerciseId = decPushup.Id, TargetSets = 3, TargetReps = "10-20", RestTimeMinutes = 1.5m, Notes = "Banded if possible" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day5Id, ExerciseId = seatedRow.Id, TargetSets = 3, TargetReps = "10-12", RestTimeMinutes = 1.5m, Notes = "Mid/upper back focus" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day5Id, ExerciseId = incCurl.Id, TargetSets = 3, TargetReps = "10-12", RestTimeMinutes = 1.5m, Notes = "" },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day5Id, ExerciseId = calfRaises.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.5m, Notes = "" } // Reused calf raises from Day 3
            );

            context.SaveChanges();
        }
    }
}
