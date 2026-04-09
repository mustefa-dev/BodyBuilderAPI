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
            if (context.WorkoutPlans.Any(p => p.Name == "BWS 5-Day Full Body Workout Plan"))
            {
                return; // DB has been seeded
            }

            var planId = Guid.NewGuid();
            var plan = new WorkoutPlan
            {
                Id = planId,
                Name = "BWS 5-Day Full Body Workout Plan",
                Description = "A 5-day full body workout split designed to maximize your gains. Mon-Fri with Sat/Sun rest. For the first 2 weeks, take it easy and avoid pushing too close to failure. After 2 weeks once your body adapts, start pushing harder and increasing the weight."
            };

            context.WorkoutPlans.Add(plan);

            // ===== EXERCISES =====
            // Day 1
            var backSquat = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Barbell Back Squat", Category = "Legs",
                Description = "Set barbell on upper traps. Stance just outside shoulder-width, toes out ~15 degrees. Squat down to at least parallel keeping bar over midfoot. Elevate heels on plates if needed for ankle mobility."
            };
            var inclinePress = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Low Incline Dumbbell Press", Category = "Chest",
                Description = "Bench at 15-30 degrees (1-2 notches up). Shoulder blades pinched, feet planted. Lower with elbows at 45-60 degrees from torso. Press up thinking about pulling arms together."
            };
            var legCurl = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Seated Leg Curls", Category = "Legs",
                Description = "Knees aligned with machine pivot point. Toes pointed straight up. Pull weight down with hamstrings. Avoid fully extending legs at top - stop just before full extension."
            };
            var latPulldown = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Lat Pulldown", Category = "Back",
                Description = "Overhand grip just outside shoulder-width. Tilt upper back slightly backwards. Pull elbows down until bar reaches chin level. Try thumbless grip and pull with elbows to better engage back."
            };
            var cableCurl = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Behind Body Cable Curls", Category = "Biceps",
                Description = "Cable at lowest position. Face away, step forward so arms hang slightly behind body. Keep elbows locked, curl hands up towards shoulders curling up and slightly inward. Can do one arm at a time."
            };

            // Day 2
            var benchPress = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Barbell Bench Press", Category = "Chest",
                Description = "Grip slightly wider than shoulder-width. Shoulder blades down and pinched. Lower bar to sternum level with elbows at 45-60 degrees. Press up and slightly back. Don't bounce off chest. Use a spotter."
            };
            var rdl = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Barbell Romanian Deadlift", Category = "Legs",
                Description = "Shoulder-width overhand grip. Push hips straight back with slight knee bend, bar close to body over midfoot. Lower until hands reach knee/mid-shin level without lower back rounding. 2-3 sec down, 1 sec up."
            };
            var dbRow = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Dumbbell Chest Supported Row", Category = "Back",
                Description = "Bench at ~30 degrees. Lay chest on bench, thumbless grip. Pull elbows back at 45-60 degrees from torso, squeeze shoulder blades together at top. Control weight down, let shoulder blades open up."
            };
            var cableLateral = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Cable Lateral Raises", Category = "Shoulders",
                Description = "Cable at bottom, face away. Reach behind to grab handle. Arms slightly bent, raise diagonally 15-30 degrees in front of body to shoulder height. Rest 30 sec then switch arms."
            };
            var ropeExt = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Overhead Rope Extensions", Category = "Triceps",
                Description = "Rope at lowest position, grab one end. Face away, step forward and to side. Arm over head with hand behind head. Keep elbow locked, extend hand out fully in line with arm. One arm at a time."
            };

            // Day 3
            var pullups = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Pull-Ups", Category = "Back",
                Description = "Overhand grip slightly wider than shoulder-width. Hang with feet together, quads/glutes/abs engaged. Pull elbows down and back into sides like pulling into back pockets. Pull until chin over bar."
            };
            var legPress = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Leg Press (Quad-Focused)", Category = "Legs",
                Description = "Backrest at lowest or 1-2 notches up. Feet shoulder-width, toes out 15 degrees, placed low on footplate for quad activation. Go as deep as possible without heels rising. Use safety pins."
            };
            var cableFlyes = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Seated Mid-Chest Cable Flyes", Category = "Chest",
                Description = "Bench at ~75 degrees, cables at mid-chest height. Shoulder blades down and back. Squeeze arms together straight in front thinking about bringing biceps together. Pause at end position."
            };
            var calfRaises = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Standing Weighted Calf Raises", Category = "Calves",
                Description = "Dumbbells or barbell, feet hip-width apart. Push up onto toes keeping pressure on big toes. Control heels slowly back down. Progress by elevating toes on a weight plate for greater ROM."
            };
            var hammerCurls = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Hammer Curls", Category = "Biceps",
                Description = "Dumbbells at sides with neutral (hammer) grip. Curl up and slightly in across chest, alternating arms each rep. Keep elbow locked in place. Control all the way up and all the way down."
            };

            // Day 4
            var bulgarian = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Bulgarian Split Squat (Glute Focused)", Category = "Legs",
                Description = "Rear foot elevated. Wider stance for glutes, lean torso forward slightly. Squat down driving back knee to ground until front thigh parallel. Push through front heel. Start with weaker leg. Back leg is just a kickstand."
            };
            var chestDips = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Chest Dips", Category = "Chest",
                Description = "Grip parallel handles, arms locked, legs bent. Lean slightly forward. Lower by bending elbows back, squeeze shoulder blades, go until arms parallel to floor. Push through palms to return."
            };
            var legExt = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Seated Leg Extensions", Category = "Legs",
                Description = "Knees aligned with machine pivot. Pad above ankle at 90 degree angle. Toes straight up, extend legs forward keeping knees facing forward. Pause briefly at top, control weight down."
            };
            var latRow = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Lat Focused Cable Row", Category = "Back",
                Description = "Knees slightly bent on pad. Lean torso forward slightly. Pull elbows down and back towards back pockets, keep elbows tucked close to sides for lat engagement. Stop when elbows reach torso level."
            };
            var rearDelt = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Rear Delt Cable Fly", Category = "Shoulders",
                Description = "Cables at highest height, no handles - grab the ball. Crossover grip (left cable right hand). Step back, arms at shoulder height. Pull arms down at 45 degrees keeping arms straight. Pause at end."
            };
            var pushdown = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Cable Pushdowns (Elbow Friendly)", Category = "Triceps",
                Description = "Pulley at highest height, use two rope attachments. Step back 2-3 steps, bend torso forward ~30 degrees, slight knee bend. Elbows at sides angled slightly out. Extend arms down and out apart."
            };

            // Day 5
            var dbPress = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Seated Dumbbell Shoulder Press", Category = "Shoulders",
                Description = "Bench at 60-75 degrees (2-3 notches down from top). Kick dumbbells up over shoulders. Elbows forward at ~45 degrees. Press up until arms straight over shoulders. Lower until weights reach chin level."
            };
            var inclineLat = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Lying Incline Lateral Raises", Category = "Shoulders",
                Description = "Bench at ~45 degrees. Lay chest on bench, legs straight. Light dumbbells hanging by sides. Arms slightly bent, raise in Y position (15-30 degrees in front) to shoulder height. Use thumbless grip."
            };
            var decPushup = new Exercise
            {
                Id = Guid.NewGuid(), Name = "(Banded) Decline Push-Ups", Category = "Chest",
                Description = "Band in X on back, feet on elevated platform (bench/plates). Grip slightly wider than shoulder-width. Lower with elbows 45-60 degrees until chest almost touches ground. Let shoulder blades open at top."
            };
            var seatedRow = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Seated Cable Row (Mid/Upper Back)", Category = "Back",
                Description = "Use wide grip handle. Knees slightly bent, back straight. Pull elbows back at 45-60 degrees, squeeze shoulder blades together. Control back letting shoulder blades open up. Keep core tight."
            };
            var incCurl = new Exercise
            {
                Id = Guid.NewGuid(), Name = "Incline Dumbbell Curls", Category = "Biceps",
                Description = "Bench at ~60 degrees (2-3 notches down from top). Arms hanging straight, palms facing in. Keep elbows locked, curl up rotating palms to face ceiling at top. Alternate arms each rep."
            };

            context.Exercises.AddRange(
                backSquat, inclinePress, legCurl, latPulldown, cableCurl,
                benchPress, rdl, dbRow, cableLateral, ropeExt,
                pullups, legPress, cableFlyes, calfRaises, hammerCurls,
                bulgarian, chestDips, legExt, latRow, rearDelt, pushdown,
                dbPress, inclineLat, decPushup, seatedRow, incCurl
            );

            // ===== DAY 1 =====
            var day1Id = Guid.NewGuid();
            context.WorkoutDays.Add(new WorkoutDay { Id = day1Id, PlanId = planId, DayNumber = 1, Title = "Day 1 - Full Body" });

            context.WorkoutDayExercises.AddRange(
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day1Id, ExerciseId = backSquat.Id, TargetSets = 3, TargetReps = "6-8", RestTimeMinutes = 2.5m, Notes = "Experiment with foot stance, squat down to at least parallel, elevate heels onto weight plates if needed." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day1Id, ExerciseId = inclinePress.Id, TargetSets = 3, TargetReps = "8-10", RestTimeMinutes = 1.75m, Notes = "Set bench 1-2 notches up from bottom, keep chest up, avoid flaring elbows out." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day1Id, ExerciseId = legCurl.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.75m, Notes = "Keep toes pointed straight up, control the weight, avoid arching lower back." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day1Id, ExerciseId = latPulldown.Id, TargetSets = 3, TargetReps = "8-10", RestTimeMinutes = 2.0m, Notes = "Grip outside shoulder width, lean back slightly, pull bar to just under chin." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day1Id, ExerciseId = cableCurl.Id, TargetSets = 3, TargetReps = "10-12", RestTimeMinutes = 1.75m, Notes = "Take small step forward from cable, let arm hang behind you, curl cable up." }
            );

            // ===== DAY 2 =====
            var day2Id = Guid.NewGuid();
            context.WorkoutDays.Add(new WorkoutDay { Id = day2Id, PlanId = planId, DayNumber = 2, Title = "Day 2 - Full Body" });

            context.WorkoutDayExercises.AddRange(
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day2Id, ExerciseId = benchPress.Id, TargetSets = 3, TargetReps = "6-8", RestTimeMinutes = 2.5m, Notes = "Grip slightly outside shoulder-width, keep chest up, lower bar to level of nipples, avoid flaring elbows out." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day2Id, ExerciseId = rdl.Id, TargetSets = 3, TargetReps = "6-8", RestTimeMinutes = 2.5m, Notes = "Push hips back, slight bend in knees, lower until hands reach level of shins." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day2Id, ExerciseId = dbRow.Id, TargetSets = 3, TargetReps = "10-12", RestTimeMinutes = 1.75m, Notes = "Set bench 2 notches up from bottom, angle elbows out, squeeze shoulder blades together. Mid/upper back focused." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day2Id, ExerciseId = cableLateral.Id, TargetSets = 3, TargetReps = "15-20", RestTimeMinutes = 1.75m, Notes = "Raise arm in scapular plane, align cable with arm, think of pushing hand 'out' not 'up'." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day2Id, ExerciseId = ropeExt.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.75m, Notes = "Perform one arm at a time, keep elbow locked, extend arm up and out." }
            );

            // ===== DAY 3 =====
            var day3Id = Guid.NewGuid();
            context.WorkoutDays.Add(new WorkoutDay { Id = day3Id, PlanId = planId, DayNumber = 3, Title = "Day 3 - Full Body" });

            context.WorkoutDayExercises.AddRange(
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day3Id, ExerciseId = pullups.Id, TargetSets = 3, TargetReps = "6-12", RestTimeMinutes = 2.5m, Notes = "Grip outside shoulder-width, pull until chin over bar, use alternative if unable to do 6 reps in a row." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day3Id, ExerciseId = legPress.Id, TargetSets = 3, TargetReps = "10-12", RestTimeMinutes = 2.5m, Notes = "Use low foot stance, let knees drive forward over toes, avoid raising heels up." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day3Id, ExerciseId = cableFlyes.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.75m, Notes = "Set cables to chest height, squeeze arms together, pause at end position." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day3Id, ExerciseId = calfRaises.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.75m, Notes = "Feet hip width apart, elevate toes on weight plate, press up on big toes." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day3Id, ExerciseId = hammerCurls.Id, TargetSets = 3, TargetReps = "10-12", RestTimeMinutes = 1.75m, Notes = "Grab dumbbells, hands by side with palms facing in, neutral grip, curl weight up and slightly in front of body." }
            );

            // ===== DAY 4 =====
            var day4Id = Guid.NewGuid();
            context.WorkoutDays.Add(new WorkoutDay { Id = day4Id, PlanId = planId, DayNumber = 4, Title = "Day 4 - Full Body" });

            context.WorkoutDayExercises.AddRange(
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day4Id, ExerciseId = bulgarian.Id, TargetSets = 3, TargetReps = "8-10 per leg", RestTimeMinutes = 1.0m, Notes = "Use wider foot stance, lean torso forward slightly, do a set on one leg then rest 1 min then do the other leg." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day4Id, ExerciseId = chestDips.Id, TargetSets = 3, TargetReps = "6-12", RestTimeMinutes = 1.75m, Notes = "Set up on a dip machine, grip handles with arms locked, lean slightly forward, bend elbows and slowly lower body." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day4Id, ExerciseId = legExt.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.75m, Notes = "Pull down on handles, pause for 1 second at top position, control weight down." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day4Id, ExerciseId = latRow.Id, TargetSets = 3, TargetReps = "10-12", RestTimeMinutes = 1.75m, Notes = "Lean torso forward slightly, pull elbows down, keep elbows tight to sides." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day4Id, ExerciseId = rearDelt.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.75m, Notes = "Set cables to highest height, grab pulleys with no handles, take a few steps up, and pull arms away from body keeping arms straight." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day4Id, ExerciseId = pushdown.Id, TargetSets = 3, TargetReps = "8-10", RestTimeMinutes = 1.75m, Notes = "Use two rope attachments if possible, keep elbow locked, push down and out." }
            );

            // ===== DAY 5 =====
            var day5Id = Guid.NewGuid();
            context.WorkoutDays.Add(new WorkoutDay { Id = day5Id, PlanId = planId, DayNumber = 5, Title = "Day 5 - Full Body" });

            context.WorkoutDayExercises.AddRange(
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day5Id, ExerciseId = dbPress.Id, TargetSets = 3, TargetReps = "8-10", RestTimeMinutes = 2.5m, Notes = "Set bench 2-3 notches down from top position, press in scapular plane." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day5Id, ExerciseId = inclineLat.Id, TargetSets = 3, TargetReps = "15-20", RestTimeMinutes = 1.75m, Notes = "Set bench 2-3 notches down from top position, lay chest on bench with dumbbells in hand, keep arms slightly bent and raise arms in a Y position in front of you." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day5Id, ExerciseId = decPushup.Id, TargetSets = 3, TargetReps = "10-20", RestTimeMinutes = 1.75m, Notes = "Wrap band around back, place feet on elevated platform (bench or weight plates), get into push-up position and lower body with elbows at a 45-60 degree angle." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day5Id, ExerciseId = seatedRow.Id, TargetSets = 3, TargetReps = "10-12", RestTimeMinutes = 1.75m, Notes = "Use wide grip handle if possible, angle elbows out, squeeze shoulder-blades together." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day5Id, ExerciseId = incCurl.Id, TargetSets = 3, TargetReps = "8-10", RestTimeMinutes = 1.75m, Notes = "Move bench 2-3 notches down from top position, alternate arms each rep, keep elbow locked." },
                new WorkoutDayExercise { Id = Guid.NewGuid(), WorkoutDayId = day5Id, ExerciseId = calfRaises.Id, TargetSets = 3, TargetReps = "10-15", RestTimeMinutes = 1.75m, Notes = "Feet hip width apart, elevate toes on weight plate, press up on big toes." }
            );

            context.SaveChanges();
        }
    }
}
