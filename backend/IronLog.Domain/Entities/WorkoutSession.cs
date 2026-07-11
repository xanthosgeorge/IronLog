namespace IronLog.Domain.Entities;

public class WorkoutSession
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }

    public string Title { get; set; } = string.Empty;

    public DateTime SessionDate { get; set; } = DateTime.UtcNow;

    public decimal? BodyWeight { get; set; }

    public int? DurationMinutes { get; set; }

    public decimal TotalLoad { get; set; }

    public string? Notes { get; set; }

    public string? AiSummary { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }

    public ICollection<WorkoutExercise> WorkoutExercises { get; set; } = new List<WorkoutExercise>();
}
