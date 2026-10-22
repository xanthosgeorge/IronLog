import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ironlog_mobile/app_controller.dart';
import 'package:ironlog_mobile/data/api_client.dart';
import 'package:ironlog_mobile/data/models.dart';
import 'support.dart';

void main() {
  test('login sends credentials without a bearer token', () async {
    final api = ApiClient(
        baseUrl: 'http://localhost:5090/',
        client: MockClient((request) async {
          expect(request.url.path, '/api/Auth/login');
          expect(request.headers['Authorization'], isNull);
          expect(jsonDecode(request.body)['email'], 'test@example.invalid');
          return http.Response(jsonEncode(sessionJson()), 200);
        }));
    final session = await api
        .authenticate({'email': 'test@example.invalid', 'password': 'secret'});
    expect(session.name, 'George Xanthos');
    expect(session.initials, 'GX');
  });

  test('loads server-paged workouts with bearer authentication', () async {
    final api = ApiClient(
        baseUrl: 'http://localhost:5090',
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer test-token');
          expect(request.url.queryParameters['skip'], '10');
          return http.Response(
              jsonEncode({
                'items': [workoutJson('1')],
                'total': 16,
                'hasMore': false
              }),
              200);
        }))
      ..token = 'test-token';
    final page = await api.workouts(10);
    expect(page.items.single.volume, 1440);
    expect(page.hasMore, isFalse);
    expect(page.total, 16);
  });

  test('failed login does not invalidate an existing session', () async {
    var expired = false;
    final api = ApiClient(
        baseUrl: 'http://localhost:5090',
        client: MockClient((_) async => http.Response('', 401)))
      ..onUnauthorized = () => expired = true;
    await expectLater(api.authenticate({'email': 'bad', 'password': 'bad'}),
        throwsA(isA<ApiException>()));
    expect(expired, isFalse);
    await expectLater(api.workouts(0), throwsA(isA<ApiException>()));
    expect(expired, isTrue);
  });

  test('restores valid sessions and removes expired sessions', () async {
    final store = MemorySessionStore()..value = storedSession();
    final controller =
        AppController(ApiClient(baseUrl: 'http://localhost:5090'), store);
    await controller.restore();
    expect(controller.api.token, 'test-token');
    expect(controller.session, isNotNull);
    expect(controller.restoring, isFalse);
    controller.dispose();
    store.value = storedSession(expired: true);
    final expired =
        AppController(ApiClient(baseUrl: 'http://localhost:5090'), store);
    await expired.restore();
    expect(expired.session, isNull);
    expect(store.value, isNull);
    expired.dispose();
  });

  test('logout clears both secure storage and API credentials', () async {
    final store = MemorySessionStore()..value = storedSession();
    final controller =
        AppController(ApiClient(baseUrl: 'http://localhost:5090'), store);
    await controller.restore();
    await controller.logout();
    expect(controller.session, isNull);
    expect(controller.api.token, isNull);
    expect(store.value, isNull);
    controller.dispose();
  });

  test('set payload accepts decimal commas and numbers sets consistently', () {
    final exercise = ExerciseDraft('bench');
    exercise.sets.first
      ..weight = '57,5'
      ..reps = '8'
      ..rpe = '8,5';
    exercise.sets.add(SetDraft()
      ..weight = '20'
      ..reps = '10'
      ..warmup = true);
    final payload = exercise.toJson(1);
    expect(payload['orderIndex'], 2);
    expect(payload['sets'][0]['weight'], 57.5);
    expect(payload['sets'][0]['rpe'], 8.5);
    expect(payload['sets'][1]['setNumber'], 2);
    expect(payload['sets'][1]['isWarmup'], isTrue);
  });
}
