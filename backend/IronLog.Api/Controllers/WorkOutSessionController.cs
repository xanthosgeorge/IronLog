using IronLog.Application.WorkoutSessions;
using IronLog.Domain.Entities;
using IronLog.Persistence;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IronLog.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class WorkoutSessionsController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public WorkoutSessionsController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<List<WorkoutSessionDto>>> GetAll()
    {
        var sessions = await _context.WorkoutSessions
            .AsNoTracking()
            .OrderByDescending(x => x.SessionDate)
            .Select(x => new WorkoutSessionDto
            {
                Id = x.Id,
                Title = x.Title,
                SessionDate = x.SessionDate,
                BodyWeight = x.BodyWeight,
                DurationMinutes = x.DurationMinutes,
                Notes = x.Notes,
                TotalVolume = x.TotalLoad
            })
            .ToListAsync();

        return Ok(sessions);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<WorkoutSessionDto>> GetById(Guid id)
    {
        var session = await _context.WorkoutSessions
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new WorkoutSessionDto
            {
                Id = x.Id,
                Title = x.Title,
                SessionDate = x.SessionDate,
                BodyWeight = x.BodyWeight,
                DurationMinutes = x.DurationMinutes,
                Notes = x.Notes,
                TotalVolume = x.TotalLoad,
                Exercises = x.WorkoutExercises
                    .OrderBy(e => e.OrderIndex)
                    .Select(e => new WorkoutExerciseDto
                    {
                        Id = e.Id,
                        ExerciseId = e.ExerciseId,
                        ExerciseName = e.Exercise != null ? e.Exercise.Name : string.Empty,
                        OrderIndex = e.OrderIndex,
                        Notes = e.Notes,
                        Sets = e.WorkoutSets
                            .OrderBy(s => s.SetNumber)
                            .Select(s => new WorkoutSetDto
                            {
                                Id = s.Id,
                                SetNumber = s.SetNumber,
                                Weight = s.Weight,
                                Reps = s.Reps.GetValueOrDefault(),
                                ResistanceNote = s.ResistanceNote,
                                Rpe = s.Rpe,
                                IsWarmup = s.IsWarmup
                            })
                            .ToList()
                    })
                    .ToList()
            })
            .FirstOrDefaultAsync();

        if (session is null)
            return NotFound();

        return Ok(session);
    }

    [HttpPost]
    public async Task<ActionResult<WorkoutSessionDto>> Create(CreateWorkoutSessionRequest request)
    {
        var userExists = await _context.Users
            .AnyAsync(x => x.Id == request.UserId);

        if (!userExists)
            return BadRequest("User does not exist.");

        var exerciseIds = request.Exercises
            .Select(x => x.ExerciseId)
            .Distinct()
            .ToList();

        var existingExerciseCount = await _context.Exercises
            .CountAsync(x => exerciseIds.Contains(x.Id));

        if (existingExerciseCount != exerciseIds.Count)
            return BadRequest("One or more exercises do not exist.");

        var session = new WorkoutSession
        {
            Id = Guid.NewGuid(),
            UserId = request.UserId,
            Title = request.Title.Trim(),
            SessionDate = request.SessionDate,
            BodyWeight = request.BodyWeight,
            DurationMinutes = request.DurationMinutes,
            Notes = request.Notes?.Trim(),
            TotalLoad = CalculateTotalLoad(request),
            WorkoutExercises = request.Exercises.Select(exercise => new WorkoutExercise
            {
                Id = Guid.NewGuid(),
                ExerciseId = exercise.ExerciseId,
                OrderIndex = exercise.OrderIndex,
                Notes = exercise.Notes?.Trim(),
                WorkoutSets = exercise.Sets.Select(set => new WorkoutSet
                {
                    Id = Guid.NewGuid(),
                    SetNumber = set.SetNumber,
                    Weight = set.Weight,
                    Reps = set.Reps,
                    ResistanceNote = set.ResistanceNote?.Trim(),
                    Rpe = set.Rpe,
                    IsWarmup = set.IsWarmup
                }).ToList()
            }).ToList()
        };

        _context.WorkoutSessions.Add(session);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = session.Id }, new { session.Id });
    }

    private static decimal CalculateTotalLoad(CreateWorkoutSessionRequest request)
    {
        return request.Exercises
            .SelectMany(exercise => exercise.Sets)
            .Sum(set => (set.Weight ?? 0) * set.Reps);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var session = await _context.WorkoutSessions
            .Include(x => x.WorkoutExercises)
            .ThenInclude(x => x.WorkoutSets)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (session is null)
            return NotFound();

        _context.WorkoutSessions.Remove(session);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
