using System.Security.Claims;
using IronLog.Api.Controllers;
using IronLog.Domain.Entities;
using IronLog.Persistence;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace IronLog.Tests;

public class ExerciseOwnershipTests
{
    [Fact]
    public async Task GetAll_ReturnsOnlyExercisesOwnedByAuthenticatedUser()
    {
        await using var context = CreateDbContext();
        var athleteOne = new User { Id = Guid.NewGuid(), FirstName = "Athlete", LastName = "One", Email = "one@example.com", PasswordHash = "hash" };
        var athleteTwo = new User { Id = Guid.NewGuid(), FirstName = "Athlete", LastName = "Two", Email = "two@example.com", PasswordHash = "hash" };
        var groupOne = new MuscleGroup { Id = Guid.NewGuid(), UserId = athleteOne.Id, Name = "Chest" };
        var groupTwo = new MuscleGroup { Id = Guid.NewGuid(), UserId = athleteTwo.Id, Name = "Back" };
        var exerciseOne = new Exercise { Id = Guid.NewGuid(), UserId = athleteOne.Id, MuscleGroupId = groupOne.Id, Name = "Bench Press", EquipmentType = "Barbell" };
        var exerciseTwo = new Exercise { Id = Guid.NewGuid(), UserId = athleteTwo.Id, MuscleGroupId = groupTwo.Id, Name = "Barbell Row", EquipmentType = "Barbell" };

        context.AddRange(athleteOne, athleteTwo, groupOne, groupTwo, exerciseOne, exerciseTwo);
        await context.SaveChangesAsync();

        var controller = new ExercisesController(context)
        {
            ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext
                {
                    User = new ClaimsPrincipal(new ClaimsIdentity(
                        [new Claim(ClaimTypes.NameIdentifier, athleteOne.Id.ToString())],
                        authenticationType: "Test"))
                }
            }
        };

        var response = await controller.GetAll();

        var okResult = Assert.IsType<OkObjectResult>(response.Result);
        var exercises = Assert.IsType<List<ExerciseDto>>(okResult.Value);
        var exercise = Assert.Single(exercises);
        Assert.Equal(exerciseOne.Id, exercise.Id);
        Assert.DoesNotContain(exercises, item => item.Id == exerciseTwo.Id);
    }

    private static ApplicationDbContext CreateDbContext()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        return new ApplicationDbContext(options);
    }
}
