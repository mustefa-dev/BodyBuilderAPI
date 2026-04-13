using System.Security.Claims;
using BodyBuilderAPI.DATA;
using BodyBuilderAPI.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BodyBuilderAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize] // All these require a logged-in user
    public class WorkoutSessionsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public WorkoutSessionsController(AppDbContext context)
        {
            _context = context;
        }

        private Guid GetUserId() => Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        [HttpPost("check-in")]
        public async Task<IActionResult> CheckIn([FromBody] CheckInDto request)
        {
            var userId = GetUserId();
            var existingSession = await _context.WorkoutSessions.FirstOrDefaultAsync(s => s.UserId == userId && s.Status == "InProgress");
            if (existingSession != null)
            {
                return BadRequest("You already have an active workout session.");
            }

            var session = new WorkoutSession
            {
                UserId = userId,
                WorkoutDayId = request.WorkoutDayId,
                CheckInTime = DateTime.UtcNow,
                Status = "InProgress"
            };

            _context.WorkoutSessions.Add(session);
            await _context.SaveChangesAsync();

            return Ok(new { SessionId = session.Id, Message = "Workout started! Time is ticking." });
        }

        [HttpPost("{sessionId}/record-set")]
        public async Task<IActionResult> RecordSet(Guid sessionId, [FromBody] RecordSetDto request)
        {
            // Verify session belongs to user and is active
            var session = await _context.WorkoutSessions.FirstOrDefaultAsync(s => s.Id == sessionId && s.UserId == GetUserId());
            if (session == null || session.Status != "InProgress") return BadRequest("Invalid or inactive session.");

            // Find last set for this specific exercise to calculate true rest time
            var lastSet = await _context.ExerciseRecords
                .Where(r => r.SessionId == sessionId && r.WorkoutDayExerciseId == request.WorkoutDayExerciseId)
                .OrderByDescending(r => r.SetCompletedAt)
                .FirstOrDefaultAsync();

            int restTimeSeconds = 0;
            if (lastSet != null)
            {
                restTimeSeconds = (int)(DateTime.UtcNow - lastSet.SetCompletedAt).TotalSeconds;
            }

            var record = new ExerciseRecord
            {
                SessionId = sessionId,
                WorkoutDayExerciseId = request.WorkoutDayExerciseId,
                SetNumber = request.SetNumber,
                WeightUsed = request.WeightUsed,
                RepsCompleted = request.RepsCompleted,
                IsFailureReached = request.IsFailureReached,
                SetCompletedAt = DateTime.UtcNow,
                RestTimeTakenSeconds = restTimeSeconds
            };

            _context.ExerciseRecords.Add(record);
            
            // Update Progressive Overload History blindly for now (can optimize later)
            var exerciseId = await _context.WorkoutDayExercises
                .Where(w => w.Id == request.WorkoutDayExerciseId)
                .Select(w => w.ExerciseId)
                .FirstOrDefaultAsync();

            var po = await _context.ProgressiveOverloadHistories.FirstOrDefaultAsync(p => p.UserId == GetUserId() && p.ExerciseId == exerciseId);
            if (po == null)
            {
                _context.ProgressiveOverloadHistories.Add(new ProgressiveOverloadHistory { UserId = GetUserId(), ExerciseId = exerciseId, PersonalBestWeight = request.WeightUsed });
            }
            else if (request.WeightUsed > po.PersonalBestWeight)
            {
                po.PersonalBestWeight = request.WeightUsed;
                po.DateAchieved = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            return Ok(new { Message = "Set recorded", RestTimeTakenSeconds = restTimeSeconds });
        }

        [HttpPut("{sessionId}/check-out")]
        public async Task<IActionResult> CheckOut(Guid sessionId)
        {
            var session = await _context.WorkoutSessions.FirstOrDefaultAsync(s => s.Id == sessionId && s.UserId == GetUserId());
            if (session == null || session.Status != "InProgress") return BadRequest("Session not active.");

            session.CheckOutTime = DateTime.UtcNow;
            session.TotalDurationMinutes = (session.CheckOutTime.Value - session.CheckInTime).TotalMinutes;
            session.Status = "Completed";

            await _context.SaveChangesAsync();
            return Ok(new { Message = "Workout completed!", TotalDurationMinutes = session.TotalDurationMinutes });
        }

        [HttpGet("active")]
        public async Task<IActionResult> GetActiveSession()
        {
            var session = await _context.WorkoutSessions
                .Include(s => s.Records)
                .FirstOrDefaultAsync(s => s.UserId == GetUserId() && s.Status == "InProgress");

            if (session == null) return NotFound("No active session found.");

            return Ok(new
            {
                session.Id,
                session.WorkoutDayId,
                session.CheckInTime,
                ElapsedTimeMinutes = (DateTime.UtcNow - session.CheckInTime).TotalMinutes,
                CompletedSetsCount = session.Records.Count
            });
        }

        [HttpGet("{sessionId}/details")]
        public async Task<IActionResult> GetSessionDetails(Guid sessionId)
        {
            var userId = GetUserId();
            var session = await _context.WorkoutSessions
                .Include(s => s.WorkoutDay)
                .Include(s => s.Records)
                    .ThenInclude(r => r.WorkoutDayExercise)
                        .ThenInclude(wde => wde.Exercise)
                .FirstOrDefaultAsync(s => s.Id == sessionId && s.UserId == userId);

            if (session == null) return NotFound("Session not found.");

            var exercises = session.Records
                .GroupBy(r => new { r.WorkoutDayExerciseId, ExerciseName = r.WorkoutDayExercise.Exercise.Name, Category = r.WorkoutDayExercise.Exercise.Category })
                .Select(g => new
                {
                    ExerciseName = g.Key.ExerciseName,
                    Category = g.Key.Category,
                    Sets = g.OrderBy(r => r.SetNumber).Select(r => new
                    {
                        r.SetNumber,
                        r.WeightUsed,
                        r.RepsCompleted,
                        r.IsFailureReached
                    }).ToList()
                })
                .ToList();

            return Ok(new
            {
                session.Id,
                Title = session.WorkoutDay.Title,
                session.CheckInTime,
                session.CheckOutTime,
                session.TotalDurationMinutes,
                Exercises = exercises
            });
        }

        [HttpGet("history")]
        public async Task<IActionResult> GetWorkoutHistory()
        {
            var history = await _context.WorkoutSessions
                .Include(s => s.WorkoutDay)
                .Where(s => s.UserId == GetUserId() && s.Status == "Completed")
                .OrderByDescending(s => s.CheckOutTime)
                .Select(s => new
                {
                    s.Id,
                    s.WorkoutDay.Title,
                    s.CheckInTime,
                    s.CheckOutTime,
                    s.TotalDurationMinutes
                })
                .ToListAsync();

            return Ok(history);
        }
    }

    public class CheckInDto { public Guid WorkoutDayId { get; set; } }
    
    public class RecordSetDto
    {
        public Guid WorkoutDayExerciseId { get; set; }
        public int SetNumber { get; set; }
        public decimal WeightUsed { get; set; }
        public int RepsCompleted { get; set; }
        public bool IsFailureReached { get; set; }
    }
}
