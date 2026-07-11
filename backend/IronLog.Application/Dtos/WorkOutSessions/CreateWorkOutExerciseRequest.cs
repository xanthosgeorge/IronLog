namespace IronLog.Application.WorkoutSessions;

public class CreateWorkoutExerciseRequest
{
    public Guid ExerciseId { get; set; }

    public int OrderIndex { get; set; }

    public string? Notes { get; set; }

    public List<CreateWorkoutSetRequest> Sets { get; set; } = [];
}