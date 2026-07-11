namespace IronLog.Application.WorkoutSessions;

public class WorkoutSessionDto
{
    public Guid Id { get; set; }

    public string Title { get; set; } = string.Empty;

    public DateTime SessionDate { get; set; }

    public decimal? BodyWeight { get; set; }

    public int? DurationMinutes { get; set; }

    public string? Notes { get; set; }

    public decimal? TotalVolume { get; set; }

    public List<WorkoutExerciseDto> Exercises { get; set; } = [];
}
