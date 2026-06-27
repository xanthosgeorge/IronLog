using IronLog.Domain.Entities;
using IronLog.Persistence;
using Microsoft.EntityFrameworkCore;

namespace IronLog.Tests;

public class MuscleGroupTests
{
    private static ApplicationDbContext CreateDbContext()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        return new ApplicationDbContext(options);
    }

    [Fact]
    public async Task CreateMuscleGroup_ShouldAddMuscleGroup()
    {
        await using var context = CreateDbContext();

        var muscleGroup = new MuscleGroup
        {
            Id = Guid.NewGuid(),
            Name = "Chest",
            Description = "Chest muscles"
        };

        context.MuscleGroups.Add(muscleGroup);
        await context.SaveChangesAsync();

        var result = await context.MuscleGroups.FirstOrDefaultAsync(x => x.Name == "Chest");

        Assert.NotNull(result);
        Assert.Equal("Chest", result.Name);
        Assert.Equal("Chest muscles", result.Description);
    }

    [Fact]
    public async Task UpdateMuscleGroup_ShouldUpdateName()
    {
        await using var context = CreateDbContext();

        var muscleGroup = new MuscleGroup
        {
            Id = Guid.NewGuid(),
            Name = "Chest"
        };

        context.MuscleGroups.Add(muscleGroup);
        await context.SaveChangesAsync();

        muscleGroup.Name = "Upper Chest";
        await context.SaveChangesAsync();

        var result = await context.MuscleGroups.FindAsync(muscleGroup.Id);

        Assert.NotNull(result);
        Assert.Equal("Upper Chest", result!.Name);
    }

    [Fact]
    public async Task DeleteMuscleGroup_ShouldRemoveMuscleGroup()
    {
        await using var context = CreateDbContext();

        var muscleGroup = new MuscleGroup
        {
            Id = Guid.NewGuid(),
            Name = "Back"
        };

        context.MuscleGroups.Add(muscleGroup);
        await context.SaveChangesAsync();

        context.MuscleGroups.Remove(muscleGroup);
        await context.SaveChangesAsync();

        var result = await context.MuscleGroups.FindAsync(muscleGroup.Id);

        Assert.Null(result);
    }
}