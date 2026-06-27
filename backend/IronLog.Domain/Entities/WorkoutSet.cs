namespace IronLog.Domain.Entities;

public class WorkoutSet
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid WorkoutExerciseId { get; set; }

    public int SetNumber { get; set; }

    public decimal? Weight { get; set; }

    public int? Reps { get; set; }

    public string? ResistanceNote { get; set; }

    public int? Rpe { get; set; }

    public bool IsWarmup { get; set; }

    public WorkoutExercise? WorkoutExercise { get; set; }
}
