namespace IronLog.Domain.Entities;

public class BodyWeightEntry
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public DateOnly RecordedOn { get; set; }
    public decimal WeightKg { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public User? User { get; set; }
}
