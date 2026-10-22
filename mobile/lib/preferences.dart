import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'translations.dart';

class AccentPalette {
  const AccentPalette(this.id, this.label, this.color, this.soft, this.dark);
  final String id, label;
  final Color color, soft, dark;
}

const palettes = [
  AccentPalette('red', 'Red / Gray', Color(0xffe53935), Color(0xffff8581),
      Color(0xffa90f0f)),
  AccentPalette('blue', 'Blue / Gray', Color(0xff287bdc), Color(0xff80baff),
      Color(0xff14519b)),
  AccentPalette('green', 'Green / Gray', Color(0xff23875e), Color(0xff71d5a8),
      Color(0xff156143)),
  AccentPalette('orange', 'Orange / Gray', Color(0xffc65b16), Color(0xffffb075),
      Color(0xff8f3c0a)),
  AccentPalette('fuchsia', 'Fuchsia / Gray', Color(0xffc62d91),
      Color(0xffff8dd4), Color(0xff8d1462)),
  AccentPalette('turquoise', 'Turquoise / Gray', Color(0xff0d9488),
      Color(0xff5eead4), Color(0xff0f766e)),
];

class AppPreferences extends ChangeNotifier {
  AppPreferences({this.storage});
  final SharedPreferencesAsync? storage;
  String language = 'el';
  String theme = 'turquoise';
  final Map<String, Uint8List> _photos = {};
  AccentPalette get palette => palettes.firstWhere((p) => p.id == theme);
  Future<void> load() async {
    final lang = await storage?.getString('ironlog.language');
    final color = await storage?.getString('ironlog.theme');
    if (lang == 'el' || lang == 'en') language = lang!;
    if (palettes.any((p) => p.id == color)) theme = color!;
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    await storage?.setString('ironlog.language', value);
    language = value;
    notifyListeners();
  }

  Future<void> setTheme(String value) async {
    await storage?.setString('ironlog.theme', value);
    theme = value;
    notifyListeners();
  }

  Uint8List? photo(String userId) => _photos[userId];
  Future<void> loadPhoto(String userId) async {
    try {
      final saved = await storage?.getString('ironlog.avatar.$userId');
      if (saved != null) _photos[userId] = base64Decode(saved);
    } catch (_) {
      _photos.remove(userId);
    }
    notifyListeners();
  }

  Future<void> setPhoto(String userId, Uint8List? value) async {
    if (value == null) {
      await storage?.remove('ironlog.avatar.$userId');
      _photos.remove(userId);
    } else {
      await storage?.setString('ironlog.avatar.$userId', base64Encode(value));
      _photos[userId] = value;
    }
    notifyListeners();
  }

  String translate(String value) {
    if (language == 'el') return greek[value] ?? value;
    return _english[value] ?? value;
  }

  static final _english = {
    for (final entry in greek.entries) entry.value: entry.key
  };
}

class PreferenceScope extends InheritedNotifier<AppPreferences> {
  const PreferenceScope(
      {super.key, required AppPreferences preferences, required super.child})
      : super(notifier: preferences);
  static AppPreferences of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PreferenceScope>()!.notifier!;
}

class Copy extends StatelessWidget {
  const Copy(this.data,
      {super.key, this.style, this.textAlign, this.overflow, this.maxLines});
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  @override
  Widget build(BuildContext context) =>
      Text(PreferenceScope.of(context).translate(data),
          style: style,
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines);
}
