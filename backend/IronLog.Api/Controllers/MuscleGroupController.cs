
using IronLog.Domain.Entities;
using IronLog.Persistence;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IronLog.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MuscleGroupsController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public MuscleGroupsController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<List<MuscleGroupDto>>> GetAll()
    {
        var muscleGroups = await _context.MuscleGroups
            .AsNoTracking()
            .OrderBy(x => x.Name)
            .Select(x => new MuscleGroupDto
            {
                Id = x.Id,
                Name = x.Name,
                Description = x.Description
            })
            .ToListAsync();

        return Ok(muscleGroups);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<MuscleGroupDto>> GetById(Guid id)
    {
        var muscleGroup = await _context.MuscleGroups
            .AsNoTracking()
            .Where(x => x.Id == id)
            .Select(x => new MuscleGroupDto
            {
                Id = x.Id,
                Name = x.Name,
                Description = x.Description
            })
            .FirstOrDefaultAsync();

        if (muscleGroup is null)
            return NotFound();

        return Ok(muscleGroup);
    }

    [HttpPost]
    public async Task<ActionResult<MuscleGroupDto>> Create(CreateMuscleGroupRequest request)
    {
        var exists = await _context.MuscleGroups
            .AnyAsync(x => x.Name.ToLower() == request.Name.ToLower());

        if (exists)
            return Conflict("Muscle group already exists.");

        var muscleGroup = new MuscleGroup
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Description = request.Description?.Trim()
        };

        _context.MuscleGroups.Add(muscleGroup);
        await _context.SaveChangesAsync();

        var dto = new MuscleGroupDto
        {
            Id = muscleGroup.Id,
            Name = muscleGroup.Name,
            Description = muscleGroup.Description
        };

        return CreatedAtAction(nameof(GetById), new { id = muscleGroup.Id }, dto);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, UpdateMuscleGroupRequest request)
    {
        var muscleGroup = await _context.MuscleGroups.FindAsync(id);

        if (muscleGroup is null)
            return NotFound();

        muscleGroup.Name = request.Name.Trim();
        muscleGroup.Description = request.Description?.Trim();

        await _context.SaveChangesAsync();

        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var muscleGroup = await _context.MuscleGroups
            .Include(x => x.Exercises)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (muscleGroup is null)
            return NotFound();

        if (muscleGroup.Exercises.Any())
            return BadRequest("Cannot delete muscle group because it has exercises.");

        _context.MuscleGroups.Remove(muscleGroup);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}