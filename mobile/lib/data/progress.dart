import 'dart:math';
import 'models.dart';

enum ProgressMetric { weight, reps, volume }

class ProgressPoint {
  const ProgressPoint(this.date, this.title, this.value);
  final DateTime date;
  final String title;
  final double value;
}

List<ProgressPoint> exerciseProgress(
    List<Workout> workouts, String exerciseId, ProgressMetric metric) {
  final points = <ProgressPoint>[];
  for (final workout in workouts) {
    final sets = workout.exercises
        .where((exercise) => exercise['exerciseId'] == exerciseId)
        .expand((exercise) => (exercise['sets'] as List).cast<Json>())
        .where((set) => set['isWarmup'] != true && (set['reps'] as num) > 0);
    final working = metric == ProgressMetric.reps
        ? sets
        : sets.where((set) =>
            set['weight'] is num &&
            (set['weight'] as num).isFinite &&
            (set['weight'] as num) >= 0);
    if (working.isEmpty) continue;
    final values = working.map((set) => switch (metric) {
          ProgressMetric.reps => (set['reps'] as num).toDouble(),
          ProgressMetric.weight => (set['weight'] as num).toDouble(),
          ProgressMetric.volume =>
            (set['weight'] as num).toDouble() * (set['reps'] as num),
        });
    final value = metric == ProgressMetric.volume
        ? values.fold(0.0, (a, b) => a + b)
        : values.reduce(max);
    points.add(ProgressPoint(workout.date, workout.title, value));
  }
  return points..sort((a, b) => a.date.compareTo(b.date));
}

double? progressChange(List<ProgressPoint> points) =>
    points.length < 2 || points.first.value == 0
        ? null
        : (points.last.value - points.first.value) / points.first.value * 100;
