import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
      : client = client ?? http.Client();
  final String baseUrl;
  final http.Client client;
  String? token;
  void Function()? onUnauthorized;

  Future<dynamic> request(String method, String path,
      {Json? body, bool authenticated = true}) async {
    final uri =
        Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}/api/$path');
    try {
      final request = http.Request(method, uri);
      final requestToken = token;
      request.headers['Content-Type'] = 'application/json';
      if (authenticated && requestToken != null) {
        request.headers['Authorization'] = 'Bearer $requestToken';
      }
      if (body != null) request.body = jsonEncode(body);
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 401 &&
          authenticated &&
          token == requestToken) {
        onUnauthorized?.call();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = switch (response.statusCode) {
          401 => authenticated
              ? 'Η σύνδεσή σου έληξε. Συνδέσου ξανά.'
              : 'Λάθος email ή κωδικός.',
          409 => authenticated
              ? 'Υπάρχει ήδη καταχώριση με αυτό το όνομα.'
              : 'Υπάρχει ήδη λογαριασμός με αυτό το email.',
          400 => 'Έλεγξε τα στοιχεία που συμπλήρωσες.',
          _ => 'Το αίτημα δεν ολοκληρώθηκε. Δοκίμασε ξανά.',
        };
        throw ApiException(message, status: response.statusCode);
      }
      return response.body.isEmpty ? null : jsonDecode(response.body);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Η σύνδεση καθυστέρησε. Δοκίμασε ξανά.');
    } catch (_) {
      throw const ApiException(
          'Δεν ήταν δυνατή η σύνδεση. Έλεγξε το δίκτυό σου και δοκίμασε ξανά.');
    }
  }

  Future<Session> authenticate(Json data, {bool register = false}) async =>
      Session.fromJson(await request(
          'POST', register ? 'Auth/register' : 'Auth/login',
          body: data, authenticated: false) as Json);
  Future<WorkoutPage> workouts(int skip) async => WorkoutPage.fromJson(
      await request('GET', 'WorkoutSessions/recent?skip=$skip') as Json);
  Future<Workout> workout(String id) async =>
      Workout.fromJson(await request('GET', 'WorkoutSessions/$id') as Json);
  Future<List<Exercise>> exercises() async =>
      (await request('GET', 'Exercises') as List)
          .map((item) => Exercise.fromJson(item as Json))
          .where((item) => item.active)
          .toList();
  Future<void> createWorkout(Json data) async {
    await request('POST', 'WorkoutSessions', body: data);
  }

  void dispose() => client.close();
}
