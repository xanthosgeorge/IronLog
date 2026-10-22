import 'package:flutter/material.dart';
import '../data/api_client.dart';
import '../data/models.dart';
import '../preferences.dart';
import '../ui.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, required this.api, this.groups = false});
  final ApiClient api;
  final bool groups;
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<Json> items = [], groups = [];
  String search = '', group = '', equipment = '';
  bool loading = true;
  String? error;
  String get endpoint => widget.groups ? 'MuscleGroups' : 'Exercises';
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
      final data =
          (await widget.api.request('GET', endpoint) as List).cast<Json>();
      final muscleGroups = widget.groups
          ? <Json>[]
          : (await widget.api.request('GET', 'MuscleGroups') as List)
              .cast<Json>();
      if (mounted) {
        setState(() {
          items = data;
          groups = muscleGroups;
          if (!groups.any((g) => g['id'] == group)) group = '';
          if (!items.any((e) => e['equipmentType'] == equipment)) {
            equipment = '';
          }
        });
      }
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit([Json? item]) async {
    final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CatalogForm(
              api: widget.api,
              groups: groups,
              muscleGroup: widget.groups,
              item: item,
            ));
    if (saved == true && mounted) await load();
  }

  Future<void> remove(Json item) async {
    if (!await confirmDelete(context, item['name'] as String)) return;
    try {
      await widget.api.request('DELETE', '$endpoint/${item['id']}');
      if (mounted) await load();
    } catch (failure) {
      if (mounted) showFailure(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = items
        .where((item) =>
            normalizeName(item['name'] as String)
                .contains(normalizeName(search)) &&
            (group.isEmpty || item['muscleGroupId'] == group) &&
            (equipment.isEmpty || item['equipmentType'] == equipment))
        .toList();
    final equipmentTypes = items
        .map((item) => item['equipmentType'])
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return RefreshIndicator(
        onRefresh: load,
        child: ListView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Copy(
                  widget.groups
                      ? 'Organize the muscle groups behind your exercise library.'
                      : 'Manage your training exercise library.',
                  style: const TextStyle(color: IronColors.muted)),
              const SizedBox(height: 20),
              PrimaryButton(
                  onPressed: loading ? null : () => edit(),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                            child: Copy(widget.groups
                                ? 'Create muscle group'
                                : 'Create exercise')),
                      ])),
              const SizedBox(height: 24),
              FieldLabel('Search by name',
                  child: TextField(
                      onChanged: (value) => setState(() => search = value),
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search)))),
              if (!widget.groups) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                    initialValue: group,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                          value: '', child: Copy('All muscle groups')),
                      for (final g in groups)
                        DropdownMenuItem(
                            value: g['id'] as String,
                            child: Text(g['name'] as String))
                    ],
                    onChanged: (value) => setState(() => group = value ?? '')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                    initialValue: equipment,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: '', child: Copy('All equipment')),
                      for (final e in equipmentTypes)
                        DropdownMenuItem(value: e, child: Text(e))
                    ],
                    onChanged: (value) =>
                        setState(() => equipment = value ?? '')),
              ],
              const SizedBox(height: 24),
              if (loading) const Center(child: CircularProgressIndicator()),
              if (error != null) ...[
                Copy(error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                TextButton(onPressed: load, child: const Copy('Refresh'))
              ],
              if (!loading && error == null && visible.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Copy('No exercises match your filters.',
                        textAlign: TextAlign.center)),
              for (final item in visible) ...[
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(item['name'] as String,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(
                                    widget.groups
                                        ? item['description'] as String? ?? ''
                                        : '${item['muscleGroupName']} · ${item['equipmentType'] ?? ''}',
                                    style: const TextStyle(
                                        color: IronColors.muted)),
                                if (!widget.groups)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Copy(
                                          item['isActive'] == true
                                              ? 'Active'
                                              : 'Inactive',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              fontSize: 12))),
                              ])),
                          IconButton(
                              tooltip:
                                  PreferenceScope.of(context).translate('Edit'),
                              onPressed: loading ? null : () => edit(item),
                              icon: const Icon(Icons.edit_outlined)),
                          IconButton(
                              tooltip: PreferenceScope.of(context)
                                  .translate('Delete'),
                              onPressed: loading ? null : () => remove(item),
                              color: Theme.of(context).colorScheme.error,
                              icon: const Icon(Icons.delete_outline)),
                        ])),
                const Divider(height: 1),
              ],
            ]));
  }
}

String normalizeName(String value) {
  const accents = {
    'ά': 'α',
    'έ': 'ε',
    'ή': 'η',
    'ί': 'ι',
    'ϊ': 'ι',
    'ΐ': 'ι',
    'ό': 'ο',
    'ύ': 'υ',
    'ϋ': 'υ',
    'ΰ': 'υ',
    'ώ': 'ω',
    'ς': 'σ'
  };
  return value
      .toLowerCase()
      .split('')
      .map((c) => accents[c] ?? c)
      .join()
      .trim();
}

class _CatalogForm extends StatefulWidget {
  const _CatalogForm(
      {required this.api,
      required this.groups,
      required this.muscleGroup,
      this.item});
  final ApiClient api;
  final List<Json> groups;
  final bool muscleGroup;
  final Json? item;
  @override
  State<_CatalogForm> createState() => _CatalogFormState();
}

class _CatalogFormState extends State<_CatalogForm> {
  final form = GlobalKey<FormState>();
  late final name =
      TextEditingController(text: widget.item?['name'] as String?);
  late final extra = TextEditingController(
      text: widget.item?[widget.muscleGroup ? 'description' : 'equipmentType']
          as String?);
  late String? group = widget.item?['muscleGroupId'] as String?;
  late bool active = widget.item?['isActive'] as bool? ?? true;
  bool saving = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    extra.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final endpoint = widget.muscleGroup ? 'MuscleGroups' : 'Exercises';
      await widget.api.request(widget.item == null ? 'POST' : 'PUT',
          widget.item == null ? endpoint : '$endpoint/${widget.item!['id']}',
          body: {
            'name': name.text.trim(),
            if (widget.muscleGroup) 'description': extra.text.trim(),
            if (!widget.muscleGroup) ...{
              'equipmentType': extra.text.trim(),
              'muscleGroupId': group,
              'isActive': active
            },
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
        title: Copy(widget.item != null
            ? 'Edit'
            : widget.muscleGroup
                ? 'Create muscle group'
                : 'Create exercise'),
        content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
                child: Form(
                    key: form,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FieldLabel('Name',
                              child: TextFormField(
                                  controller: name,
                                  enabled: !saving,
                                  autofocus: true,
                                  validator: (value) => value!.trim().isEmpty
                                      ? PreferenceScope.of(context)
                                          .translate('Name is required.')
                                      : null)),
                          const SizedBox(height: 17),
                          if (!widget.muscleGroup) ...[
                            FieldLabel('Muscle group',
                                child: DropdownButtonFormField<String>(
                                    initialValue: group,
                                    isExpanded: true,
                                    items: [
                                      for (final g in widget.groups)
                                        DropdownMenuItem(
                                            value: g['id'] as String,
                                            child: Text(g['name'] as String))
                                    ],
                                    onChanged: saving
                                        ? null
                                        : (value) =>
                                            setState(() => group = value),
                                    validator: (value) => value == null
                                        ? PreferenceScope.of(context)
                                            .translate('Choose a muscle group.')
                                        : null)),
                            const SizedBox(height: 17),
                          ],
                          FieldLabel(
                              widget.muscleGroup
                                  ? 'Description'
                                  : 'Equipment type',
                              child: TextFormField(
                                  controller: extra,
                                  enabled: !saving,
                                  minLines: widget.muscleGroup ? 3 : 1,
                                  maxLines: widget.muscleGroup ? 5 : 1)),
                          if (!widget.muscleGroup)
                            CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: const Copy('Active exercise'),
                                value: active,
                                onChanged: saving
                                    ? null
                                    : (value) =>
                                        setState(() => active = value!)),
                          if (error != null)
                            Copy(error!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
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

void showFailure(BuildContext context, Object failure) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Copy(failure.toString())));
Future<bool> confirmDelete(BuildContext context, String name) async =>
    await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Copy('Delete'),
              content: Text(name),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Copy('Close')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Copy('Delete',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error))),
              ],
            )) ??
    false;
