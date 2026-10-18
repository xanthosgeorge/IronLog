using System.Security.Claims;
using IronLog.Application.BodyWeights;
using IronLog.Domain.Entities;
using IronLog.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IronLog.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public class BodyWeightsController(ApplicationDbContext context) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<BodyWeightDto>>> GetAll()
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();
        return Ok(await context.BodyWeightEntries.AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderBy(x => x.RecordedOn).ThenBy(x => x.CreatedAt).ThenBy(x => x.Id)
            .Select(x => new BodyWeightDto(x.Id, x.RecordedOn, x.WeightKg)).ToListAsync());
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<BodyWeightDto>> GetById(Guid id)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();
        var entry = await context.BodyWeightEntries.AsNoTracking()
            .Where(x => x.Id == id && x.UserId == userId)
            .Select(x => new BodyWeightDto(x.Id, x.RecordedOn, x.WeightKg)).FirstOrDefaultAsync();
        return entry is null ? NotFound() : Ok(entry);
    }

    [HttpPost]
    public async Task<ActionResult<BodyWeightDto>> Create(CreateBodyWeightRequest request)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();
        if (request.RecordedOn == default) return BadRequest("Choose a valid date.");
        if (request.WeightKg <= 0 || request.WeightKg > 1000 || decimal.Round(request.WeightKg, 2) != request.WeightKg)
            return BadRequest("Enter a weight between 0.01 and 1000 kg with up to two decimal places.");
        var entry = new BodyWeightEntry { UserId = userId, RecordedOn = request.RecordedOn, WeightKg = request.WeightKg };
        context.BodyWeightEntries.Add(entry);
        await context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetById), new { id = entry.Id },
            new BodyWeightDto(entry.Id, entry.RecordedOn, entry.WeightKg));
    }

    private bool TryGetUserId(out Guid userId) =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out userId);
}
