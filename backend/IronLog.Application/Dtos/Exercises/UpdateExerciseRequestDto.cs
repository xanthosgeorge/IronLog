public class UpdateExerciseRequest

{

    public Guid MuscleGroupId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string? EquipmentType { get; set; }

    public bool IsActive { get; set; } = true;

}