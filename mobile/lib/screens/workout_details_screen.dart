import 'package:flutter/material.dart';
import '../preferences.dart';
import '../data/api_client.dart';
import '../data/models.dart';

class WorkoutDetailsScreen extends StatefulWidget {
  const WorkoutDetailsScreen({super.key, required this.api, required this.id});
  final ApiClient api;
  final String id;
  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  late Future<Workout> future;
  @override
  void initState() {
    super.initState();
    future = widget.api.workout(widget.id);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Copy('Προπόνηση')),
        body: FutureBuilder<Workout>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Copy(snapshot.error.toString(),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          OutlinedButton(
                              onPressed: () => setState(
                                  () => future = widget.api.workout(widget.id)),
                              child: const Copy('Δοκίμασε ξανά')),
                        ])));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final workout = snapshot.data!;
              return ListView(padding: const EdgeInsets.all(24), children: [
                Text(workout.title,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                Copy(
                    MaterialLocalizations.of(context)
                        .formatFullDate(workout.date),
                    style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 24),
                Wrap(spacing: 24, runSpacing: 12, children: [
                  Copy('${workout.duration ?? 0} λεπτά'),
                  Copy(
                      '${workout.volume.toStringAsFixed(0)} kg συνολικός όγκος')
                ]),
                if (workout.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 20),
                  Copy(workout.notes!)
                ],
                const SizedBox(height: 24),
                for (final exercise in workout.exercises) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(exercise['exerciseName'] as String,
                      style: Theme.of(context).textTheme.titleLarge),
                  if (exercise['notes'] case final String notes) ...[
                    const SizedBox(height: 8),
                    Copy(notes)
                  ],
                  const SizedBox(height: 12),
                  for (final set in (exercise['sets'] as List).cast<Json>())
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                width: 36,
                                child: Copy('#${set['setNumber']}',
                                    style: const TextStyle(
                                        color: Colors.white54))),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Copy(
                                      '${set['weight'] ?? 0} kg × ${set['reps']} επαναλήψεις',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  if (set['isWarmup'] == true)
                                    const Copy('Προθέρμανση',
                                        style:
                                            TextStyle(color: Colors.white54)),
                                  if (set['resistanceNote']
                                      case final String note)
                                    Copy(note,
                                        style: const TextStyle(
                                            color: Colors.white60)),
                                ])),
                            if (set['rpe'] != null) Copy('RPE ${set['rpe']}'),
                          ]),
                    ),
                  const SizedBox(height: 16),
                ],
              ]);
            }),
      );
}
