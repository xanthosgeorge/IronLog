import 'package:flutter/material.dart';
import '../preferences.dart';
import '../data/api_client.dart';
import '../data/models.dart';

class NewWorkoutScreen extends StatefulWidget {
  const NewWorkoutScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<NewWorkoutScreen> createState() => _NewWorkoutScreenState();
}

class _NewWorkoutScreenState extends State<NewWorkoutScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final duration = TextEditingController();
  final notes = TextEditingController();
  final bodyWeight = TextEditingController();
  final List<ExerciseDraft> selected = [];
  List<Exercise> catalog = [];
  DateTime date = DateTime.now();
  bool loading = true, saving = false, dirty = false;
  String? error;
  String tr(String value) => PreferenceScope.of(context).translate(value);

  @override
  void initState() {
    super.initState();
    loadCatalog();
  }

  @override
  void dispose() {
    for (final controller in [title, duration, notes, bodyWeight]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> loadCatalog() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final exercises = await widget.api.exercises();
      if (mounted) {
        setState(() {
          catalog = exercises..sort((a, b) => a.name.compareTo(b.name));
          if (catalog.isNotEmpty && selected.isEmpty) {
            selected.add(ExerciseDraft(catalog.first.id));
          }
        });
      }
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    if (selected.isEmpty) {
      setState(() => error = 'Πρόσθεσε τουλάχιστον μία άσκηση.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.api.createWorkout({
        'title': title.text.trim(),
        'sessionDate': DateTime(date.year, date.month, date.day, 12)
            .toUtc()
            .toIso8601String(),
        'durationMinutes': int.tryParse(duration.text),
        'bodyWeight': SetDraft.decimal(bodyWeight.text),
        'notes': notes.text.trim().isEmpty ? null : notes.text.trim(),
        'exercises': [
          for (var i = 0; i < selected.length; i++) selected[i].toJson(i)
        ],
      });
      if (mounted) {
        setState(() {
          dirty = false;
          saving = false;
        });
        Navigator.of(context).pop(true);
      }
    } catch (failure) {
      if (mounted) {
        setState(() {
          error = failure.toString();
          saving = false;
        });
      }
    }
  }

  String? decimalValidator(String? value,
      {double minimum = 0, double? maximum}) {
    if (value == null || value.trim().isEmpty) return null;
    final number = SetDraft.decimal(value);
    return number == null ||
            !number.isFinite ||
            number < minimum ||
            (maximum != null && number > maximum)
        ? tr('Μη έγκυρη τιμή')
        : null;
  }

  Future<void> close() async {
    if (saving) return;
    if (dirty) {
      final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Copy('Απόρριψη προπόνησης;'),
                content: const Copy('Οι αλλαγές δεν έχουν αποθηκευτεί.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Copy('Συνέχεια')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Copy('Απόρριψη'))
                ],
              ));
      if (discard != true) return;
    }
    if (mounted) {
      setState(() => dirty = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !saving && !dirty,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) close();
        },
        child: Scaffold(
          appBar: AppBar(
              leading: IconButton(
                  tooltip: 'Κλείσιμο',
                  onPressed: saving ? null : close,
                  icon: const Icon(Icons.close)),
              title: const Copy('Νέα προπόνηση')),
          body: loading
              ? const Center(child: CircularProgressIndicator())
              : catalog.isEmpty
                  ? Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Copy(
                                error ??
                                    'Δεν υπάρχουν ενεργές ασκήσεις στη βιβλιοθήκη σου.',
                                textAlign: TextAlign.center),
                            if (error != null)
                              TextButton(
                                  onPressed: loadCatalog,
                                  child: const Copy('Δοκίμασε ξανά')),
                          ])))
                  : AbsorbPointer(
                      absorbing: saving,
                      child: Form(
                        key: form,
                        onChanged: () {
                          if (!dirty) setState(() => dirty = true);
                        },
                        child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              TextFormField(
                                  controller: title,
                                  decoration: InputDecoration(
                                      labelText: PreferenceScope.of(context)
                                          .translate('Τίτλος')),
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  validator: (value) => value!.trim().isEmpty
                                      ? tr('Συμπλήρωσε τίτλο.')
                                      : null),
                              const SizedBox(height: 16),
                              ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Copy('Ημερομηνία'),
                                  subtitle: Copy(
                                      MaterialLocalizations.of(context)
                                          .formatFullDate(date)),
                                  trailing:
                                      const Icon(Icons.calendar_today_outlined),
                                  onTap: () async {
                                    final chosen = await showDatePicker(
                                        context: context,
                                        initialDate: date,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime.now());
                                    if (chosen != null && mounted) {
                                      setState(() {
                                        date = chosen;
                                        dirty = true;
                                      });
                                    }
                                  }),
                              const SizedBox(height: 16),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                        child: TextFormField(
                                            controller: duration,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                                labelText: PreferenceScope.of(
                                                        context)
                                                    .translate(
                                                        'Διάρκεια (λεπτά)')),
                                            validator: (value) => value!
                                                        .isEmpty ||
                                                    (int.tryParse(value) !=
                                                            null &&
                                                        int.parse(value) >= 0)
                                                ? null
                                                : tr('Μη έγκυρη διάρκεια'))),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: TextFormField(
                                            controller: bodyWeight,
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                                decimal: true),
                                            decoration: InputDecoration(
                                                labelText: PreferenceScope.of(
                                                        context)
                                                    .translate(
                                                        'Βάρος σώματος (kg)')),
                                            validator: (value) =>
                                                decimalValidator(value,
                                                    minimum: 0.1))),
                                  ]),
                              const SizedBox(height: 16),
                              TextFormField(
                                  controller: notes,
                                  decoration: InputDecoration(
                                      labelText: PreferenceScope.of(context)
                                          .translate('Σημειώσεις')),
                                  minLines: 2,
                                  maxLines: 4),
                              const SizedBox(height: 32),
                              Copy('Ασκήσεις',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              for (final entry in selected.asMap().entries)
                                _exercise(entry.key, entry.value),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                  onPressed: () => setState(() {
                                        selected.add(
                                            ExerciseDraft(catalog.first.id));
                                        dirty = true;
                                      }),
                                  icon: const Icon(Icons.add),
                                  label: const Copy('Προσθήκη άσκησης')),
                              if (error != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Copy(error!,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error))),
                            ]),
                      )),
          bottomNavigationBar: SafeArea(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: FilledButton.icon(
                      onPressed:
                          loading || saving || catalog.isEmpty ? null : save,
                      icon: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check),
                      label: Copy(saving
                          ? 'Αποθήκευση...'
                          : 'Αποθήκευση προπόνησης')))),
        ),
      );

  Widget _exercise(int index, ExerciseDraft exercise) => Padding(
        key: ObjectKey(exercise),
        padding: const EdgeInsets.only(top: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Divider(),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: Copy('Άσκηση ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            if (selected.length > 1)
              IconButton(
                  tooltip: 'Αφαίρεση άσκησης',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() {
                        selected.removeAt(index);
                        dirty = true;
                      }))
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
              initialValue: exercise.exerciseId,
              isExpanded: true,
              decoration: InputDecoration(
                  labelText: PreferenceScope.of(context).translate('Άσκηση')),
              items: [
                for (final item in catalog)
                  DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name, overflow: TextOverflow.ellipsis))
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    exercise.exerciseId = value;
                    dirty = true;
                  });
                }
              }),
          const SizedBox(height: 12),
          TextFormField(
              initialValue: exercise.notes,
              decoration: InputDecoration(
                  labelText: PreferenceScope.of(context)
                      .translate('Σημειώσεις άσκησης')),
              onChanged: (value) => exercise.notes = value),
          for (final entry in exercise.sets.asMap().entries)
            _set(exercise, entry.key, entry.value),
          TextButton.icon(
              onPressed: () => setState(() {
                    exercise.sets.add(SetDraft());
                    dirty = true;
                  }),
              icon: const Icon(Icons.add),
              label: const Copy('Προσθήκη σετ')),
        ]),
      );

  Widget _set(ExerciseDraft exercise, int index, SetDraft set) => Padding(
        key: ObjectKey(set),
        padding: const EdgeInsets.only(top: 20),
        child: Column(children: [
          Row(children: [
            Expanded(
                child: Copy('${tr('Sets')} ${index + 1}',
                    style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w700))),
            if (exercise.sets.length > 1)
              IconButton(
                  tooltip: 'Αφαίρεση σετ',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => setState(() {
                        exercise.sets.removeAt(index);
                        dirty = true;
                      }))
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: TextFormField(
                    initialValue: set.weight,
                    decoration: InputDecoration(
                        labelText: PreferenceScope.of(context)
                            .translate('Βάρος (kg)')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => set.weight = value,
                    validator: decimalValidator)),
            const SizedBox(width: 10),
            Expanded(
                child: TextFormField(
                    initialValue: set.reps,
                    decoration: InputDecoration(
                        labelText: PreferenceScope.of(context)
                            .translate('Επαναλήψεις')),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => set.reps = value,
                    validator: (value) =>
                        int.tryParse(value!) != null && int.parse(value) > 0
                            ? null
                            : tr('Απαιτείται > 0'))),
            const SizedBox(width: 10),
            Expanded(
                child: TextFormField(
                    initialValue: set.rpe,
                    decoration: InputDecoration(
                        labelText:
                            PreferenceScope.of(context).translate('RPE')),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => set.rpe = value,
                    validator: (value) =>
                        decimalValidator(value, minimum: 1, maximum: 10))),
          ]),
          CheckboxListTile(
              value: set.warmup,
              contentPadding: EdgeInsets.zero,
              title: const Copy('Προθέρμανση', style: TextStyle(fontSize: 14)),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) => setState(() {
                    set.warmup = value ?? false;
                    dirty = true;
                  })),
          TextFormField(
              initialValue: set.note,
              decoration: InputDecoration(
                  labelText:
                      PreferenceScope.of(context).translate('Σημείωση σετ')),
              onChanged: (value) => set.note = value),
        ]),
      );
}
