
using IronLog.Domain.Entities;
using IronLog.Persistence;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;

namespace IronLog.Api.Controllers;

[ApiController]
[Authorize]
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
        if (!TryGetUserId(out var userId))
            return Unauthorized();

        var muscleGroups = await _context.MuscleGroups
            .AsNoTracking()
            .Where(x => x.UserId == userId)
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
        if (!TryGetUserId(out var userId))
            return Unauthorized();

        var muscleGroup = await _context.MuscleGroups
            .AsNoTracking()
            .Where(x => x.Id == id && x.UserId == userId)
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
        if (!TryGetUserId(out var userId))
            return Unauthorized();

        var normalizedName = request.Name.Trim();
        var exists = await _context.MuscleGroups
            .AnyAsync(x => x.UserId == userId && x.Name.ToLower() == normalizedName.ToLower());

        if (exists)
            return Conflict("Muscle group already exists.");

        var muscleGroup = new MuscleGroup
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Name = normalizedName,
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
        if (!TryGetUserId(out var userId))
            return Unauthorized();

        var muscleGroup = await _context.MuscleGroups.FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);

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
        if (!TryGetUserId(out var userId))
            return Unauthorized();

        var muscleGroup = await _context.MuscleGroups
            .Include(x => x.Exercises)
            .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId);

        if (muscleGroup is null)
            return NotFound();

        if (muscleGroup.Exercises.Any())
            return BadRequest("Cannot delete muscle group because it has exercises.");

        _context.MuscleGroups.Remove(muscleGroup);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    private bool TryGetUserId(out Guid userId)
    {
        var claim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(claim, out userId);
    }
}
