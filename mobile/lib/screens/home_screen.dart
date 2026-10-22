import 'package:flutter/material.dart';
import '../app_controller.dart';
import '../preferences.dart';
import '../ui.dart';
import 'body_weight_screen.dart';
import 'catalog_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'workouts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selected = 0;
  static const labels = [
    'Progress',
    'Exercises',
    'Muscle Groups',
    'Workout Sessions',
    'Body weight',
    'Settings'
  ];
  static const icons = [
    Icons.show_chart,
    Icons.fitness_center,
    Icons.accessibility_new,
    Icons.calendar_month_outlined,
    Icons.monitor_weight_outlined,
    Icons.settings_outlined
  ];
  @override
  Widget build(BuildContext context) {
    final preferences = PreferenceScope.of(context);
    final session = widget.controller.session!;
    final photo = preferences.photo(session.user['id'].toString());
    final pages = [
      ProgressScreen(api: widget.controller.api),
      CatalogScreen(api: widget.controller.api),
      CatalogScreen(api: widget.controller.api, groups: true),
      WorkoutsScreen(controller: widget.controller),
      BodyWeightScreen(api: widget.controller.api),
      SettingsScreen(controller: widget.controller),
    ];
    return Scaffold(
      appBar: AppBar(title: Copy(labels[selected])),
      drawer: Drawer(
          backgroundColor: IronColors.background,
          shape: const RoundedRectangleBorder(),
          child: SafeArea(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                const Padding(padding: EdgeInsets.all(24), child: IronBrand()),
                const Divider(height: 1),
                Expanded(
                    child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 20),
                        children: [
                      for (var i = 0; i < labels.length; i++)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              selected: selected == i,
                              selectedTileColor: preferences.palette.color,
                              selectedColor: Colors.white,
                              leading: Text('${i + 1}'.padLeft(2, '0'),
                                  style: TextStyle(
                                      color: selected == i
                                          ? Colors.white70
                                          : IronColors.muted,
                                      fontWeight: FontWeight.w700)),
                              title: Copy(labels[i],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() => selected = i);
                              },
                            )),
                    ])),
                const Divider(height: 1),
                Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(children: [
                      CircleAvatar(
                          radius: 22,
                          backgroundColor: IronColors.panel,
                          foregroundImage:
                              photo == null ? null : MemoryImage(photo),
                          child: Text(session.initials)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(session.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text(session.user['email'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: IronColors.muted)),
                          ])),
                      IconButton(
                          tooltip: preferences.translate('Settings'),
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() => selected = 5);
                          },
                          icon: const Icon(Icons.settings_outlined)),
                    ])),
              ]))),
      body: KeyedSubtree(key: ValueKey(selected), child: pages[selected]),
      bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: IronColors.border))),
          child: NavigationBar(
            selectedIndex: switch (selected) {
              0 => 0,
              3 => 1,
              1 || 2 || 4 => 2,
              _ => 3
            },
            onDestinationSelected: (value) =>
                setState(() => selected = [0, 3, 1, 5][value]),
            destinations: [
              for (final i in [0, 3, 1, 5])
                NavigationDestination(
                    icon: Icon(icons[i]),
                    label: preferences.translate(labels[i])),
            ],
          )),
    );
  }
}
