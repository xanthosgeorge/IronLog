using System.Security.Claims;
using IronLog.Api.Controllers;
using IronLog.Domain.Entities;
using IronLog.Persistence;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IronLog.Tests;

public class WorkoutSessionPagingTests
{
    [Fact]
    public async Task Recent_PagesTenBySessionDateAndExcludesOtherUsers()
    {
        await using var db = new ApplicationDbContext(new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString()).Options);
        var owner = Guid.NewGuid();
        var start = new DateTime(2026, 10, 1, 0, 0, 0, DateTimeKind.Utc);
        for (var i = 0; i < 23; i++)
            db.WorkoutSessions.Add(new WorkoutSession { UserId = owner, Title = $"Session {i}",
                SessionDate = start.AddDays(i), CreatedAt = start.AddDays(-i) });
        db.WorkoutSessions.Add(new WorkoutSession { UserId = Guid.NewGuid(), Title = "Private", SessionDate = start.AddYears(1) });
        await db.SaveChangesAsync();
        var controller = new WorkoutSessionsController(db)
        {
            ControllerContext = new ControllerContext { HttpContext = new DefaultHttpContext {
                User = new ClaimsPrincipal(new ClaimsIdentity([new Claim(ClaimTypes.NameIdentifier, owner.ToString())], "Test"))
            } }
        };
        var first = Assert.IsType<WorkoutSessionPageDto>(Assert.IsType<OkObjectResult>(await controller.GetRecent()).Value);
        var second = Assert.IsType<WorkoutSessionPageDto>(Assert.IsType<OkObjectResult>(await controller.GetRecent(10)).Value);
        var third = Assert.IsType<WorkoutSessionPageDto>(Assert.IsType<OkObjectResult>(await controller.GetRecent(20)).Value);
        Assert.Equal(23, first.Total);
        Assert.Equal(10, first.Items.Count);
        Assert.Equal("Session 22", first.Items[0].Title);
        Assert.Equal("Session 12", second.Items[0].Title);
        Assert.True(second.HasMore);
        Assert.Equal(3, third.Items.Count);
        Assert.False(third.HasMore);
        Assert.Equal(23, first.Items.Concat(second.Items).Concat(third.Items).Select(x => x.Id).Distinct().Count());
        Assert.IsType<BadRequestObjectResult>(await controller.GetRecent(-1));
    }
}
