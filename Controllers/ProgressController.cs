using System.Security.Claims;
using BodyBuilderAPI.DATA;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BodyBuilderAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ProgressController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ProgressController(AppDbContext context)
        {
            _context = context;
        }

        private Guid GetUserId() => Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        [HttpGet("history/{WorkoutDayExerciseId}")]
        public async Task<IActionResult> GetPreviousSessionPerformance(Guid WorkoutDayExerciseId)
        {
            var userId = GetUserId();

            // Specifically grabs what the user lifted the LAST time they did this specific exercise in this exact plan
            var lastPerformance = await _context.ExerciseRecords
                .Include(r => r.Session)
                .Where(r => r.Session.UserId == userId && r.WorkoutDayExerciseId == WorkoutDayExerciseId && r.Session.Status == "Completed")
                .OrderByDescending(r => r.SetCompletedAt)
                .Take(5) // Gets the last 5 sets (usually 3 sets per exercise based on PDF)
                .Select(r => new
                {
                    r.SetNumber,
                    r.WeightUsed,
                    r.RepsCompleted,
                    r.SetCompletedAt,
                    PastSessionDate = r.Session.CheckInTime
                })
                .ToListAsync();

            if (!lastPerformance.Any()) return Ok(new { Message = "No previous history for this exercise. Time to set a baseline!" });

            return Ok(lastPerformance);
        }
        
        [HttpGet("personal-records")]
        public async Task<IActionResult> GetPersonalRecords()
        {
            var records = await _context.ProgressiveOverloadHistories
                .Include(p => p.Exercise)
                .Where(p => p.UserId == GetUserId())
                .Select(p => new
                {
                    p.Exercise.Name,
                    p.PersonalBestWeight,
                    p.DateAchieved
                })
                .ToListAsync();

            return Ok(records);
        }
    }
}
