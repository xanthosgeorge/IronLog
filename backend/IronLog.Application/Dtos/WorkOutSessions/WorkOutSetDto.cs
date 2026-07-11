namespace IronLog.Application.WorkoutSessions;

public class WorkoutSetDto
{
    public Guid Id { get; set; }
    public int SetNumber { get; set; }
    public decimal? Weight { get; set; }
    public int Reps { get; set; }
    public string? ResistanceNote { get; set; }
    public int? Rpe { get; set; }
    public bool IsWarmup { get; set; }
}
