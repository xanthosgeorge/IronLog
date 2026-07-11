namespace IronLog.Application.WorkoutSessions;

public class CreateWorkoutSessionRequest
{
    public Guid UserId { get; set; }

    public string Title { get; set; } = string.Empty;

    public DateTime SessionDate { get; set; }

    public decimal? BodyWeight { get; set; }

    public int? DurationMinutes { get; set; }

    public string? Notes { get; set; }

    public List<CreateWorkoutExerciseRequest> Exercises { get; set; } = [];
}
