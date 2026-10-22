typedef Json = Map<String, dynamic>;

class Session {
  const Session(
      {required this.token, required this.expiresAt, required this.user});
  final String token;
  final DateTime expiresAt;
  final Json user;
  factory Session.fromJson(Json json) => Session(
        token: json['accessToken'] as String,
        expiresAt: DateTime.parse(json['expiresAtUtc'] as String),
        user: json['user'] as Json,
      );
  Json toJson() => {
        'accessToken': token,
        'expiresAtUtc': expiresAt.toIso8601String(),
        'user': user
      };
  bool get expired => !expiresAt.isAfter(DateTime.now().toUtc());
  String get name =>
      '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
  String get initials => [user['firstName'], user['lastName']]
      .whereType<String>()
      .where((name) => name.trim().isNotEmpty)
      .map((name) => name.trim()[0])
      .join()
      .toUpperCase();
}

class Exercise {
  const Exercise(
      {required this.id,
      required this.name,
      required this.group,
      required this.active});
  final String id;
  final String name;
  final String group;
  final bool active;
  factory Exercise.fromJson(Json json) => Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      group: json['muscleGroupName'] as String? ?? '',
      active: json['isActive'] as bool? ?? false);
}

class Workout {
  const Workout(
      {required this.id,
      required this.title,
      required this.date,
      this.duration,
      this.volume = 0,
      this.notes,
      this.exercises = const []});
  final String id;
  final String title;
  final DateTime date;
  final int? duration;
  final double volume;
  final String? notes;
  final List<Json> exercises;
  factory Workout.fromJson(Json json) => Workout(
        id: json['id'] as String,
        title: json['title'] as String,
        date: DateTime.parse(json['sessionDate'] as String).toLocal(),
        duration: (json['durationMinutes'] as num?)?.toInt(),
        volume: (json['totalVolume'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String?,
        exercises: (json['exercises'] as List? ?? []).cast<Json>(),
      );
}

class WorkoutPage {
  const WorkoutPage(this.items, this.total, this.hasMore);
  final List<Workout> items;
  final int total;
  final bool hasMore;
  factory WorkoutPage.fromJson(Json json) => WorkoutPage(
        (json['items'] as List)
            .map((item) => Workout.fromJson(item as Json))
            .toList(),
        json['total'] as int,
        json['hasMore'] as bool,
      );
}

class SetDraft {
  String weight = '';
  String reps = '';
  String rpe = '';
  String note = '';
  bool warmup = false;
  static double? decimal(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));
  Json toJson(int index) => {
        'setNumber': index + 1,
        'weight': decimal(weight),
        'reps': int.parse(reps),
        'rpe': decimal(rpe),
        'resistanceNote': note.trim().isEmpty ? null : note.trim(),
        'isWarmup': warmup,
      };
}

class ExerciseDraft {
  ExerciseDraft(this.exerciseId);
  String exerciseId;
  String notes = '';
  final List<SetDraft> sets = [SetDraft()];
  Json toJson(int index) => {
        'exerciseId': exerciseId,
        'orderIndex': index + 1,
        'notes': notes.trim().isEmpty ? null : notes.trim(),
        'sets': [for (var i = 0; i < sets.length; i++) sets[i].toJson(i)],
      };
}
