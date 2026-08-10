namespace IronLog.Domain.Entities;

public class Exercise
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }

    public Guid MuscleGroupId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string EquipmentType { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;

    public User? User { get; set; }

    public MuscleGroup? MuscleGroup { get; set; }

    public ICollection<WorkoutExercise> WorkoutExercises { get; set; } = new List<WorkoutExercise>();
}
