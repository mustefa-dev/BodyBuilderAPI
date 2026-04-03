using BodyBuilderAPI.DATA;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BodyBuilderAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]

    public class PlansController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PlansController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/plans
        [HttpGet]
        public async Task<IActionResult> GetPlans()
        {
            var plans = await _context.WorkoutPlans.ToListAsync();
            return Ok(plans);
        }

        // GET: api/plans/{planId}/days
        [HttpGet("{planId}/days")]
        public async Task<IActionResult> GetPlanDays(Guid planId)
        {
            var days = await _context.WorkoutDays
                .Where(d => d.PlanId == planId)
                .OrderBy(d => d.DayNumber)
                .ToListAsync();

            if (!days.Any()) return NotFound("No days found for this plan.");
            return Ok(days);
        }

        // GET: api/plans/day/{dayId}/exercises
        [HttpGet("day/{dayId}/exercises")]
        public async Task<IActionResult> GetExercisesForDay(Guid dayId)
        {
            var exercises = await _context.WorkoutDayExercises
                .Include(wde => wde.Exercise)
                .Where(wde => wde.WorkoutDayId == dayId)
                .Select(wde => new
                {
                    wde.Id, // WorkoutDayExerciseId
                    wde.Exercise.Name,
                    wde.Exercise.Category,
                    wde.TargetSets,
                    wde.TargetReps,
                    wde.RestTimeMinutes,
                    wde.Notes
                })
                .ToListAsync();

            return Ok(exercises);
        }
    }
}
