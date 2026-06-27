namespace IronLog.Domain.Entities;

public class WorkoutExercise
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid WorkoutSessionId { get; set; }

    public Guid ExerciseId { get; set; }

    public int OrderIndex { get; set; }

    public string? Notes { get; set; }

    public WorkoutSession? WorkoutSession { get; set; }

    public Exercise? Exercise { get; set; }

    public ICollection<WorkoutSet> WorkoutSets { get; set; } = new List<WorkoutSet>();
}
