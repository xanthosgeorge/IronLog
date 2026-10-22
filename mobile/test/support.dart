import 'dart:convert';
import 'package:ironlog_mobile/data/session_store.dart';

class MemorySessionStore implements SessionStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

Map<String, dynamic> sessionJson({bool expired = false}) => {
      'accessToken': 'test-token',
      'expiresAtUtc': DateTime.now()
          .toUtc()
          .add(Duration(days: expired ? -1 : 1))
          .toIso8601String(),
      'user': {
        'id': 'user-1',
        'firstName': 'George',
        'lastName': 'Xanthos',
        'email': 'test@example.invalid'
      },
    };
String storedSession({bool expired = false}) =>
    jsonEncode(sessionJson(expired: expired));
Map<String, dynamic> workoutJson(String id) => {
      'id': id,
      'title': 'Upper A',
      'sessionDate': '2026-10-05T14:00:00Z',
      'durationMinutes': 60,
      'totalVolume': 1440,
      'exercises': [],
    };
