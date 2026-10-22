import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ironlog_mobile/app_controller.dart';
import 'package:ironlog_mobile/data/api_client.dart';
import 'package:ironlog_mobile/main.dart';
import 'support.dart';

void main() {
  testWidgets('login validates credentials at a small phone size',
      (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController(
        ApiClient(baseUrl: 'http://localhost:5090'), MemorySessionStore());
    await controller.restore();
    await tester.pumpWidget(IronLogApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('IRON LOG'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Σύνδεση'));
    await tester.pumpAndSettle();
    expect(find.text('Συμπλήρωσε ένα έγκυρο email.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'restored account opens workouts and the new workout form at iPhone 16 Pro Max dimensions',
      (tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient(
        baseUrl: 'http://localhost:5090',
        client: MockClient((request) async {
          if (request.url.path == '/api/WorkoutSessions') {
            return http.Response('[]', 200);
          }
          if (request.url.path.endsWith('/recent')) {
            return http.Response(
                jsonEncode({
                  'items': [workoutJson('1')],
                  'total': 1,
                  'hasMore': false
                }),
                200);
          }
          return http.Response(
              jsonEncode([
                {
                  'id': 'bench',
                  'name': 'Bench Press',
                  'muscleGroupName': 'Chest',
                  'isActive': true
                }
              ]),
              200);
        }));
    final controller =
        AppController(api, MemorySessionStore()..value = storedSession());
    await controller.restore();
    await tester.pumpWidget(IronLogApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Upper A'), findsOneWidget);
    await tester.tap(find.text('Νέα προπόνηση'));
    await tester.pumpAndSettle();
    expect(find.text('Αποθήκευση προπόνησης'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Αποθήκευση προπόνησης'));
    await tester.pumpAndSettle();
    expect(find.text('Συμπλήρωσε τίτλο.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login and registration remain scrollable with the keyboard open',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.reset);
    final controller = AppController(
        ApiClient(baseUrl: 'https://api.example.invalid'),
        MemorySessionStore());
    await controller.restore();
    await tester.pumpWidget(IronLogApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
        find.widgetWithText(TextButton, 'Δημιουργία λογαριασμού'));
    await tester.tap(find.widgetWithText(TextButton, 'Δημιουργία λογαριασμού'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(4));
    await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Δημιουργία λογαριασμού'));
    await tester
        .tap(find.widgetWithText(FilledButton, 'Δημιουργία λογαριασμού'));
    await tester.pumpAndSettle();
    expect(find.text('Συμπλήρωσε το πεδίο.'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'exercise popup saves to API, closes on success and stays open on failure',
      (tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final items = <Map<String, dynamic>>[];
    bool fail = false;
    final api = ApiClient(
        baseUrl: 'https://api.example.invalid',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/MuscleGroups')) {
            return http.Response(
                jsonEncode([
                  {'id': 'chest', 'name': 'Chest'}
                ]),
                200);
          }
          if (request.url.path.endsWith('/Exercises')) {
            if (request.method == 'POST') {
              if (fail) return http.Response('{}', 400);
              final data = jsonDecode(request.body) as Map<String, dynamic>;
              expect(data['muscleGroupId'], 'chest');
              expect(request.headers['Authorization'], 'Bearer test-token');
              items.add({...data, 'id': 'new', 'muscleGroupName': 'Chest'});
              return http.Response(jsonEncode(items.last), 201);
            }
            return http.Response(jsonEncode(items), 200);
          }
          return http.Response('[]', 200);
        }));
    final controller =
        AppController(api, MemorySessionStore()..value = storedSession());
    await controller.restore();
    await tester.pumpWidget(IronLogApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    Future<void> fill(String name) async {
      await tester.tap(find.text('Δημιουργία άσκησης'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, name);
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chest').last);
      await tester.pumpAndSettle();
    }

    await fill('Incline Bench');
    await tester.tap(find.text('Αποθήκευση'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Incline Bench'), findsOneWidget);
    fail = true;
    await fill('Unsaved exercise');
    await tester.tap(find.text('Αποθήκευση'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Έλεγξε τα στοιχεία που συμπλήρωσες.'), findsOneWidget);
    expect(
        find.widgetWithText(TextFormField, 'Unsaved exercise'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings switch language and accent without losing navigation',
      (tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = AppController(
        ApiClient(
            baseUrl: 'https://api.example.invalid',
            client: MockClient((_) async => http.Response('[]', 200))),
        MemorySessionStore()..value = storedSession());
    await controller.restore();
    await tester.pumpWidget(IronLogApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);
    await tester.ensureVisible(find.text('Blue / Gray'));
    await tester.tap(find.text('Blue / Gray'));
    await tester.pumpAndSettle();
    expect(controller.preferences.theme, 'blue');
    expect(controller.preferences.language, 'en');
    expect(tester.takeException(), isNull);
  });
}
