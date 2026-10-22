import 'package:flutter/material.dart';
import '../data/api_client.dart';
import '../data/models.dart';
import '../data/progress.dart';
import '../preferences.dart';
import '../ui.dart';
import 'progress_screen.dart';

class BodyWeightScreen extends StatefulWidget {
  const BodyWeightScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<BodyWeightScreen> createState() => _BodyWeightScreenState();
}

class _BodyWeightScreenState extends State<BodyWeightScreen> {
  List<Json> items = [];
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = (await widget.api.request('GET', 'BodyWeights') as List)
          .cast<Json>()
        ..sort((a, b) =>
            (a['recordedOn'] as String).compareTo(b['recordedOn'] as String));
      if (mounted) setState(() => items = data);
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> add() async {
    final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _WeightForm(api: widget.api));
    if (saved == true && mounted) await load();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
      onRefresh: load,
      child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const Copy('Track your body weight over time.',
                style: TextStyle(color: IronColors.muted)),
            const SizedBox(height: 20),
            PrimaryButton(
                onPressed: loading ? null : add,
                child: const Copy('Record body weight')),
            const SizedBox(height: 28),
            if (loading) const Center(child: CircularProgressIndicator()),
            if (error != null) ...[
              Copy(error!),
              TextButton(onPressed: load, child: const Copy('Refresh'))
            ],
            if (!loading && error == null && items.isEmpty)
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Copy(
                      'Record your first body weight to see your progress.',
                      textAlign: TextAlign.center)),
            if (items.isNotEmpty) ...[
              HistoryChart(points: [
                for (final item in items)
                  ProgressPoint(DateTime.parse(item['recordedOn'] as String),
                      '', (item['weightKg'] as num).toDouble())
              ], unit: 'kg'),
              const SizedBox(height: 24),
              for (final item in items.reversed) ...[
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(MaterialLocalizations.of(context)
                        .formatMediumDate(
                            DateTime.parse(item['recordedOn'] as String))),
                    trailing: Text('${item['weightKg']} kg',
                        style: const TextStyle(fontWeight: FontWeight.w700))),
                const Divider(height: 1),
              ],
            ],
          ]));
}

class _WeightForm extends StatefulWidget {
  const _WeightForm({required this.api});
  final ApiClient api;
  @override
  State<_WeightForm> createState() => _WeightFormState();
}

class _WeightFormState extends State<_WeightForm> {
  final form = GlobalKey<FormState>();
  final weight = TextEditingController();
  DateTime date = DateTime.now();
  bool saving = false;
  String? error;
  @override
  void dispose() {
    weight.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await widget.api.request('POST', 'BodyWeights', body: {
        'recordedOn':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'weightKg': SetDraft.decimal(weight.text)
      });
      if (mounted) {
        setState(() => saving = false);
        Navigator.pop(context, true);
      }
    } catch (failure) {
      if (mounted) {
        setState(() {
          saving = false;
          error = failure.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !saving,
      child: AlertDialog(
        title: const Copy('Record body weight'),
        content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
                child: Form(
                    key: form,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Copy('Date'),
                          subtitle: Text(MaterialLocalizations.of(context)
                              .formatMediumDate(date)),
                          trailing: const Icon(Icons.calendar_today_outlined),
                          onTap: saving
                              ? null
                              : () async {
                                  final chosen = await showDatePicker(
                                      context: context,
                                      initialDate: date,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now());
                                  if (chosen != null && mounted) {
                                    setState(() => date = chosen);
                                  }
                                }),
                      const SizedBox(height: 16),
                      FieldLabel('Weight in kg',
                          child: TextFormField(
                              controller: weight,
                              enabled: !saving,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (value) {
                                final n = SetDraft.decimal(value ?? '');
                                return n == null ||
                                        !n.isFinite ||
                                        n <= 0 ||
                                        n > 1000 ||
                                        !RegExp(r'^\d+([.,]\d{1,2})?$')
                                            .hasMatch(value!.trim())
                                    ? PreferenceScope.of(context).translate(
                                        'Enter a weight between 0.01 and 1000 kg with up to two decimal places.')
                                    : null;
                              })),
                      if (error != null) Copy(error!),
                    ])))),
        actions: [
          TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Copy('Close')),
          FilledButton(
              onPressed: saving ? null : save,
              child: Copy(saving ? 'Please wait...' : 'Save'))
        ],
      ));
}
