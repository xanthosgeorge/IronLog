using System.Security.Claims;
using IronLog.Api.Controllers;
using IronLog.Application.BodyWeights;
using IronLog.Domain.Entities;
using IronLog.Persistence;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IronLog.Tests;

public class BodyWeightTests
{
    [Fact]
    public async Task History_IsOwnedAndOrderedByMeasurementDate()
    {
        await using var db = CreateContext();
        var owner = Guid.NewGuid();
        db.BodyWeightEntries.AddRange(
            new BodyWeightEntry { UserId = owner, RecordedOn = new(2026, 10, 18), WeightKg = 80.25m },
            new BodyWeightEntry { UserId = Guid.NewGuid(), RecordedOn = new(2026, 10, 17), WeightKg = 90 },
            new BodyWeightEntry { UserId = owner, RecordedOn = new(2026, 10, 16), WeightKg = 81 });
        await db.SaveChangesAsync();
        var controller = Controller(db, owner);
        var result = Assert.IsType<OkObjectResult>((await controller.GetAll()).Result);
        var entries = Assert.IsType<List<BodyWeightDto>>(result.Value);
        Assert.Equal(new decimal[] { 81, 80.25m }, entries.Select(x => x.WeightKg));
        var foreign = await db.BodyWeightEntries.SingleAsync(x => x.UserId != owner);
        Assert.IsType<NotFoundResult>((await controller.GetById(foreign.Id)).Result);
    }

    [Fact]
    public async Task Create_PreservesChosenDateAndDecimalWeightUnderAuthenticatedOwner()
    {
        await using var db = CreateContext();
        var owner = Guid.NewGuid();
        var request = new CreateBodyWeightRequest(new(2026, 10, 15), 75.55m);
        Assert.IsType<CreatedAtActionResult>((await Controller(db, owner).Create(request)).Result);
        var entry = await db.BodyWeightEntries.SingleAsync();
        Assert.Equal(owner, entry.UserId);
        Assert.Equal(request.RecordedOn, entry.RecordedOn);
        Assert.Equal(request.WeightKg, entry.WeightKg);
    }

    [Theory]
    [InlineData("0")]
    [InlineData("-1")]
    [InlineData("1000.01")]
    [InlineData("75.555")]
    public async Task Create_RejectsInvalidWeights(string weight)
    {
        await using var db = CreateContext();
        var request = new CreateBodyWeightRequest(new(2026, 10, 18), decimal.Parse(weight, System.Globalization.CultureInfo.InvariantCulture));
        Assert.IsType<BadRequestObjectResult>((await Controller(db, Guid.NewGuid()).Create(request)).Result);
        Assert.Empty(db.BodyWeightEntries);
    }

    [Fact]
    public async Task Create_RejectsMissingDateAndMissingIdentity()
    {
        await using var db = CreateContext();
        Assert.IsType<BadRequestObjectResult>((await Controller(db, Guid.NewGuid()).Create(new(default, 75))).Result);
        Assert.IsType<UnauthorizedResult>((await Controller(db, null).Create(new(new(2026, 10, 18), 75))).Result);
        Assert.Empty(db.BodyWeightEntries);
    }

    private static ApplicationDbContext CreateContext() => new(new DbContextOptionsBuilder<ApplicationDbContext>()
        .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);

    private static BodyWeightsController Controller(ApplicationDbContext db, Guid? owner) => new(db)
    {
        ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext
            {
                User = new ClaimsPrincipal(new ClaimsIdentity(owner.HasValue
                    ? new[] { new Claim(ClaimTypes.NameIdentifier, owner.Value.ToString()) }
                    : Array.Empty<Claim>(), "Test"))
            }
        }
    };
}
