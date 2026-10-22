import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../data/api_client.dart';
import '../data/models.dart';
import '../data/progress.dart';
import '../preferences.dart';
import '../ui.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<Json> exercises = [];
  List<Workout> workouts = [];
  String? selected, error;
  ProgressMetric metric = ProgressMetric.weight;
  bool loading = true;
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
      final catalog = (await widget.api.request('GET', 'Exercises') as List)
          .cast<Json>()
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      final summaries =
          (await widget.api.request('GET', 'WorkoutSessions') as List)
              .cast<Json>();
      final details = <Workout>[];
      // Bound requests like the Angular dashboard rather than flooding the API.
      for (var i = 0; i < summaries.length; i += 6) {
        details.addAll(await Future.wait(summaries
            .skip(i)
            .take(6)
            .map((s) => widget.api.workout(s['id'] as String))));
      }
      if (!mounted) return;
      setState(() {
        exercises = catalog;
        workouts = details;
        if (!catalog.any((e) => e['id'] == selected)) {
          selected = catalog
                  .where((e) => details.any((w) => w.exercises
                      .any((entry) => entry['exerciseId'] == e['id'])))
                  .firstOrNull?['id'] as String? ??
              catalog.firstOrNull?['id'] as String?;
        }
      });
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = exerciseProgress(workouts, selected ?? '', metric);
    final change = progressChange(points);
    final unit = metric == ProgressMetric.reps
        ? PreferenceScope.of(context).translate('reps')
        : 'kg';
    return RefreshIndicator(
        onRefresh: load,
        child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const Copy('Track your progress. Break your limits.',
                  style: TextStyle(color: IronColors.muted)),
              const SizedBox(height: 24),
              if (loading) const Center(child: CircularProgressIndicator()),
              if (error != null) ...[
                Copy(error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                TextButton(onPressed: load, child: const Copy('Refresh'))
              ],
              if (!loading && error == null) ...[
                FieldLabel('Exercise',
                    child: DropdownButtonFormField<String>(
                        key: ValueKey(selected),
                        initialValue: selected,
                        isExpanded: true,
                        items: [
                          for (final exercise in exercises)
                            DropdownMenuItem(
                                value: exercise['id'] as String,
                                child: Text(exercise['name'] as String,
                                    overflow: TextOverflow.ellipsis))
                        ],
                        onChanged: (value) =>
                            setState(() => selected = value))),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ProgressMetric>(
                      showSelectedIcon: false,
                      selected: {metric},
                      segments: const [
                        ButtonSegment(
                            value: ProgressMetric.weight,
                            label: Copy('Weight')),
                        ButtonSegment(
                            value: ProgressMetric.reps, label: Copy('Reps')),
                        ButtonSegment(
                            value: ProgressMetric.volume, label: Copy('Volume'))
                      ],
                      onSelectionChanged: (value) =>
                          setState(() => metric = value.first),
                    )),
                const SizedBox(height: 28),
                Copy(
                    switch (metric) {
                      ProgressMetric.weight => 'Max working weight',
                      ProgressMetric.reps => 'Max reps per set',
                      ProgressMetric.volume => 'Training volume'
                    },
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                if (points.isEmpty)
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Copy('No history for this exercise yet.',
                          textAlign: TextAlign.center))
                else ...[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                        child: _stat('First session',
                            '${points.first.value.toStringAsFixed(1)} $unit')),
                    Expanded(
                        child: _stat('Latest session',
                            '${points.last.value.toStringAsFixed(1)} $unit')),
                    Expanded(
                        child: _stat(
                            'Change',
                            change == null
                                ? '—'
                                : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                            accent: true)),
                  ]),
                  const SizedBox(height: 28),
                  HistoryChart(points: points, unit: unit),
                  const SizedBox(height: 24),
                  for (final point in points.reversed) ...[
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(point.title),
                        subtitle: Text(MaterialLocalizations.of(context)
                            .formatMediumDate(point.date)),
                        trailing: Text(
                            '${point.value.toStringAsFixed(1)} $unit',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700))),
                    const Divider(height: 1),
                  ],
                ],
              ],
            ]));
  }

  Widget _stat(String label, String value, {bool accent = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Copy(label,
            style: const TextStyle(color: IronColors.muted, fontSize: 12)),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: accent
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white)),
      ]);
}

class HistoryChart extends StatelessWidget {
  const HistoryChart({super.key, required this.points, required this.unit});
  final List<ProgressPoint> points;
  final String unit;
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
        height: 250,
        child: LineChart(LineChartData(
          minX: 0,
          maxX: points.length > 1 ? (points.length - 1).toDouble() : 1,
          minY: 0,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: IronColors.border, strokeWidth: 1)),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                            fontSize: 11, color: IronColors.muted)))),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: points.length <= 3 ? 1 : (points.length - 1) / 2,
                    getTitlesWidget: (value, meta) {
                      final i = value.round();
                      if (i < 0 || i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      final date = points[i].date;
                      return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('${date.day}/${date.month}',
                              style: const TextStyle(
                                  fontSize: 11, color: IronColors.muted)));
                    })),
          ),
          lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((spot) {
                        final p = points[spot.spotIndex];
                        return LineTooltipItem(
                            '${p.date.day}/${p.date.month} · ${p.title}\n${p.value.toStringAsFixed(1)} $unit',
                            const TextStyle(color: Colors.white, fontSize: 12));
                      }).toList())),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].value)
              ],
              color: color,
              barWidth: 3,
              isCurved: false,
              dotData: const FlDotData(show: true),
              belowBarData:
                  BarAreaData(show: true, color: color.withValues(alpha: .12)),
            )
          ],
        )));
  }
}
