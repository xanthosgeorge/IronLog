namespace IronLog.Application.BodyWeights;

public record CreateBodyWeightRequest(DateOnly RecordedOn, decimal WeightKg);
public record BodyWeightDto(Guid Id, DateOnly RecordedOn, decimal WeightKg);
