namespace IronLog.Application.WorkoutSessions;

public class WorkoutExerciseDto
{
    public Guid Id { get; set; }
    public Guid ExerciseId { get; set; }
    public string ExerciseName { get; set; } = string.Empty;
    public int OrderIndex { get; set; }
    public string? Notes { get; set; }
    public List<WorkoutSetDto> Sets { get; set; } = [];
}
