namespace IronLog.Domain.Entities;

public class MuscleGroup
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    public User? User { get; set; }

    public ICollection<Exercise> Exercises { get; set; } = new List<Exercise>();
}
