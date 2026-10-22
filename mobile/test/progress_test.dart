import 'package:flutter_test/flutter_test.dart';
import 'package:ironlog_mobile/data/models.dart';
import 'package:ironlog_mobile/data/progress.dart';
import 'package:ironlog_mobile/preferences.dart';
import 'package:ironlog_mobile/config.dart';

void main() {
  Workout workout(int day, List<Json> sets) => Workout(
          id: '$day',
          title: 'Training',
          date: DateTime(2026, 10, day),
          exercises: [
            {'exerciseId': 'bench', 'sets': sets}
          ]);
  test(
      'progress matches Angular: excludes warmups, sorts dates and computes each metric',
      () {
    final workouts = [
      workout(10, [
        {'weight': 60, 'reps': 8},
        {'weight': 50, 'reps': 10},
        {'weight': 100, 'reps': 3, 'isWarmup': true}
      ]),
      workout(1, [
        {'weight': 50, 'reps': 8},
        {'weight': 500, 'reps': 0}
      ]),
    ];
    final weight = exerciseProgress(workouts, 'bench', ProgressMetric.weight);
    expect(weight.map((p) => p.value), [50, 60]);
    expect(progressChange(weight), 20);
    expect(
        exerciseProgress(workouts, 'bench', ProgressMetric.reps)
            .map((p) => p.value),
        [8, 10]);
    expect(
        exerciseProgress(workouts, 'bench', ProgressMetric.volume)
            .map((p) => p.value),
        [400, 980]);
    expect(exerciseProgress(workouts, 'other', ProgressMetric.weight), isEmpty);
  });
  test(
      'bodyweight exercises support reps but not missing weights; zero baseline is not a percentage',
      () {
    final workouts = [
      workout(1, [
        {'weight': null, 'reps': 12}
      ]),
      workout(2, [
        {'weight': 0, 'reps': 14}
      ])
    ];
    expect(exerciseProgress(workouts, 'bench', ProgressMetric.reps).length, 2);
    final weight = exerciseProgress(workouts, 'bench', ProgressMetric.weight);
    expect(weight.length, 1);
    expect(progressChange(weight), isNull);
    expect(
        progressChange([
          ProgressPoint(DateTime(2026), '', 0),
          ProgressPoint(DateTime(2027), '', 10)
        ]),
        isNull);
  });
  test(
      'preferences default to screenshot palette and avatar stays scoped to account',
      () async {
    final preferences = AppPreferences();
    expect(preferences.theme, 'turquoise');
    expect(palettes.length, 6);
    expect(preferences.translate('Welcome back'), 'Καλώς ήρθες');
    await preferences.setLanguage('en');
    expect(preferences.translate('Καλώς ήρθες'), 'Welcome back');
    expect(preferences.photo('other-user'), isNull);
  });
  test('default backend is Azure over HTTPS', () {
    final url = Uri.parse(AppConfig.apiBaseUrl);
    expect(url.scheme, 'https');
    expect(url.host, endsWith('.azurewebsites.net'));
  });
}
