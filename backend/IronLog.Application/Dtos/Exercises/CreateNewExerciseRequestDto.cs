public class CreateExerciseRequest

{

    public Guid MuscleGroupId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string? EquipmentType { get; set; }

}