import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'data/api_client.dart';
import 'data/models.dart';
import 'data/session_store.dart';
import 'preferences.dart';

class AppController extends ChangeNotifier {
  AppController(this.api, this.store, {AppPreferences? preferences})
      : preferences = preferences ?? AppPreferences() {
    api.onUnauthorized = expire;
  }
  final ApiClient api;
  final SessionStore store;
  final AppPreferences preferences;
  Session? session;
  bool restoring = true;
  String? notice;

  Future<void> restore() async {
    try {
      final saved = await store.read();
      if (saved != null) {
        final candidate = Session.fromJson(jsonDecode(saved) as Json);
        if (!candidate.expired) {
          session = candidate;
          api.token = candidate.token;
          await preferences.loadPhoto(candidate.user['id'].toString());
        } else {
          await store.clear();
        }
      }
    } catch (_) {
      notice = 'Δεν ήταν δυνατή η ανάκτηση της σύνδεσης. Συνδέσου ξανά.';
    }
    restoring = false;
    notifyListeners();
  }

  Future<void> authenticate(Json data, {bool register = false}) async {
    final authenticated = await api.authenticate(data, register: register);
    try {
      await store.write(jsonEncode(authenticated.toJson()));
    } catch (_) {
      throw const ApiException(
          'Δεν ήταν δυνατή η ασφαλής αποθήκευση της σύνδεσης. Δοκίμασε ξανά.');
    }
    session = authenticated;
    api.token = authenticated.token;
    await preferences.loadPhoto(authenticated.user['id'].toString());
    notice = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await store.clear();
    session = null;
    api.token = null;
    notifyListeners();
  }

  void expire() {
    session = null;
    api.token = null;
    notice = 'Η σύνδεσή σου έληξε. Συνδέσου ξανά.';
    store.clear().catchError((_) {});
    notifyListeners();
  }
}
