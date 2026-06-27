public class ExerciseDto

{

    public Guid Id { get; set; }

    public Guid MuscleGroupId { get; set; }

    public string MuscleGroupName { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public string? EquipmentType { get; set; }

    public bool IsActive { get; set; }

}