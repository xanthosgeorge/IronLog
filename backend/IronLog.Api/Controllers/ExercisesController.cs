using IronLog.Application;
using IronLog.Domain.Entities;
using IronLog.Persistence;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IronLog.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ExercisesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public ExercisesController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<List<ExerciseDto>>> GetAll()
    {
        var exercises = await _context.Exercises
            .AsNoTracking()
            .OrderBy(x => x.Name)
            .Select(x => new ExerciseDto
            {
                Id = x.Id,
                MuscleGroupId = x.MuscleGroupId,
                MuscleGroupName = x.MuscleGroup != null ? x.MuscleGroup.Name : string.Empty,
                Name = x.Name,
                EquipmentType = x.EquipmentType,
                IsActive = x.IsActive
            })
            .ToListAsync();

        return Ok(exercises);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ExerciseDto>> GetById(Guid id)
    {
        var exercise = await _context.Exercises
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new ExerciseDto
            {
                Id = x.Id,
                MuscleGroupId = x.MuscleGroupId,
                MuscleGroupName = x.MuscleGroup != null ? x.MuscleGroup.Name : string.Empty,
                Name = x.Name,
                EquipmentType = x.EquipmentType,
                IsActive = x.IsActive
            })
            .FirstOrDefaultAsync();

        if (exercise is null)
            return NotFound();

        return Ok(exercise);
    }

    [HttpPost]
    public async Task<ActionResult<ExerciseDto>> Create(CreateExerciseRequest request)
    {
        var muscleGroupExists = await _context.MuscleGroups
            .AnyAsync(x => x.Id == request.MuscleGroupId);

        if (!muscleGroupExists)
            return BadRequest("Muscle group does not exist.");

        var normalizedName = request.Name.Trim();

        var exists = await _context.Exercises
            .AnyAsync(x => x.Name.ToLower() == normalizedName.ToLower());

        if (exists)
            return Conflict("Exercise already exists.");

        var exercise = new Exercise
        {
            Id = Guid.NewGuid(),
            MuscleGroupId = request.MuscleGroupId,
            Name = normalizedName,
            EquipmentType = request.EquipmentType?.Trim() ?? string.Empty,
            IsActive = true
        };

        _context.Exercises.Add(exercise);
        await _context.SaveChangesAsync();

        var dto = await _context.Exercises
            .AsNoTracking()
            .Where(x => x.Id == exercise.Id)
            .Select(x => new ExerciseDto
            {
                Id = x.Id,
                MuscleGroupId = x.MuscleGroupId,
                MuscleGroupName = x.MuscleGroup != null ? x.MuscleGroup.Name : string.Empty,
                Name = x.Name,
                EquipmentType = x.EquipmentType,
                IsActive = x.IsActive
            })
            .FirstAsync();

        return CreatedAtAction(nameof(GetById), new { id = exercise.Id }, dto);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, UpdateExerciseRequest request)
    {
        var exercise = await _context.Exercises.FindAsync(id);

        if (exercise is null)
            return NotFound();

        var muscleGroupExists = await _context.MuscleGroups
            .AnyAsync(x => x.Id == request.MuscleGroupId);

        if (!muscleGroupExists)
            return BadRequest("Muscle group does not exist.");

        exercise.MuscleGroupId = request.MuscleGroupId;
        exercise.Name = request.Name.Trim();
        exercise.EquipmentType = request.EquipmentType?.Trim() ?? string.Empty;
        exercise.IsActive = request.IsActive;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var exercise = await _context.Exercises
            .Include(x => x.WorkoutExercises)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (exercise is null)
            return NotFound();

        if (exercise.WorkoutExercises.Any())
            return BadRequest("Cannot delete exercise because it is used in workout sessions.");

        _context.Exercises.Remove(exercise);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}