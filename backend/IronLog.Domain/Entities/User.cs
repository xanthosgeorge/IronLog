
namespace IronLog.Domain.Entities;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string FirstName { get; set; } = string.Empty;

    public string LastName { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string PasswordHash { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<WorkoutSession> WorkoutSessions { get; set; } = new List<WorkoutSession>();

    public ICollection<MuscleGroup> MuscleGroups { get; set; } = new List<MuscleGroup>();

    public ICollection<Exercise> Exercises { get; set; } = new List<Exercise>();
}
