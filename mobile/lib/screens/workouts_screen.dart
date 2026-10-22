import 'package:flutter/material.dart';
import '../preferences.dart';
import '../app_controller.dart';
import '../data/models.dart';
import 'new_workout_screen.dart';
import 'workout_details_screen.dart';
import '../ui.dart';
import 'catalog_screen.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  final List<Workout> items = [];
  int total = 0, nextSkip = 0;
  bool busy = false, hasMore = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load(refresh: true);
  }

  Future<void> load({bool refresh = false}) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final page = await widget.controller.api.workouts(refresh ? 0 : nextSkip);
      if (!mounted) return;
      setState(() {
        if (refresh) {
          items.clear();
          nextSkip = 0;
        }
        final known = items.map((item) => item.id).toSet();
        items.addAll(page.items.where((item) => known.add(item.id)));
        nextSkip += page.items.length;
        total = page.total;
        hasMore = page.hasMore;
      });
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> create() async {
    final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog.fullscreen(
            child: NewWorkoutScreen(api: widget.controller.api)));
    if (saved == true && mounted) await load(refresh: true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: RefreshIndicator(
          onRefresh: () => load(refresh: true),
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 112),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const Copy(
                    'Κατάγραψε προπονήσεις με ασκήσεις, σετ, βάρη, επαναλήψεις και RPE.',
                    style: TextStyle(color: IronColors.muted)),
                const SizedBox(height: 20),
                PrimaryButton(
                    onPressed: create,
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 8),
                          Copy('Νέα προπόνηση')
                        ])),
                const SizedBox(height: 24),
                Copy('Πρόσφατες προπονήσεις',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Copy(
                    '$total ${PreferenceScope.of(context).translate('logged sessions')}',
                    style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 24),
                if (busy && items.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator())),
                if (error != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(children: [
                        Copy(error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                        TextButton.icon(
                            onPressed: busy
                                ? null
                                : () => load(refresh: items.isEmpty),
                            icon: const Icon(Icons.refresh),
                            label: const Copy('Δοκίμασε ξανά')),
                      ])),
                if (!busy && error == null && items.isEmpty)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 64),
                      child: Copy('Δεν υπάρχουν ακόμη προπονήσεις.',
                          textAlign: TextAlign.center)),
                for (final workout in items) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.fitness_center,
                            color: Theme.of(context).colorScheme.primary)),
                    title: Text(workout.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Copy(
                            '${MaterialLocalizations.of(context).formatMediumDate(workout.date)}\n${workout.duration ?? 0} ${PreferenceScope.of(context).translate('min')}  ·  ${workout.volume.toStringAsFixed(0)} kg',
                            style: const TextStyle(height: 1.6))),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.chevron_right),
                      IconButton(
                          tooltip: 'Διαγραφή',
                          color: Theme.of(context).colorScheme.error,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: busy
                              ? null
                              : () async {
                                  if (!await confirmDelete(
                                      context, workout.title)) {
                                    return;
                                  }
                                  try {
                                    await widget.controller.api.request(
                                        'DELETE',
                                        'WorkoutSessions/${workout.id}');
                                    if (mounted) await load(refresh: true);
                                  } catch (failure) {
                                    if (context.mounted) {
                                      showFailure(context, failure);
                                    }
                                  }
                                }),
                    ]),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => WorkoutDetailsScreen(
                            api: widget.controller.api, id: workout.id))),
                  ),
                  const Divider(height: 1),
                ],
                if (hasMore)
                  Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton(
                          onPressed: busy ? null : load,
                          child: Copy(busy
                              ? 'Φόρτωση...'
                              : 'Περισσότερες προπονήσεις'))),
              ]),
        ),
      );
}
