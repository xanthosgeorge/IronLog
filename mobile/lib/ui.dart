import 'package:flutter/material.dart';
import 'preferences.dart';

abstract final class IronColors {
  static const background = Color(0xff0f1115);
  static const panel = Color(0xff171a21);
  static const border = Color(0xff2a2f3a);
  static const muted = Color(0xffa5acb8);
  static const soft = Color(0xffd3d7df);
  static const accent = Color(0xff0d9488);
  static const accentSoft = Color(0xff5eead4);
  static const accentDark = Color(0xff0f766e);
}

ThemeData ironTheme(AccentPalette palette) {
  const outline = BorderSide(color: IronColors.border);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: palette.soft,
      onPrimary: Colors.white,
      secondary: palette.color,
      surface: IronColors.panel,
      onSurface: Colors.white,
      onSurfaceVariant: IronColors.muted,
      outline: IronColors.border,
      error: Color(0xffff8581),
    ),
    scaffoldBackgroundColor: IronColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: IronColors.background,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
    ),
    dividerTheme:
        const DividerThemeData(color: IronColors.border, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xff101217),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      labelStyle: const TextStyle(color: IronColors.soft, fontSize: 14),
      floatingLabelStyle: TextStyle(color: palette.soft),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: outline),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: outline),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: palette.color)),
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
      backgroundColor: palette.color,
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 48),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      shape: shape,
    )),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      minimumSize: const Size(0, 46),
      side: outline,
      shape: shape,
    )),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    )),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.color,
      foregroundColor: Colors.white,
      shape: shape,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: IronColors.background,
      indicatorColor: palette.color.withValues(alpha: .2),
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? palette.soft
              : IronColors.muted)),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? Colors.white
              : IronColors.muted)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
      shape: WidgetStatePropertyAll(shape),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
      backgroundColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? palette.color
              : Colors.transparent),
      side: const WidgetStatePropertyAll(outline),
    )),
    dialogTheme: DialogThemeData(
        backgroundColor: IronColors.panel,
        shape: shape.copyWith(side: outline)),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(fontSize: 15, height: 1.4),
    ),
  );
}

class IronBrand extends StatelessWidget {
  const IronBrand({super.key});
  @override
  Widget build(BuildContext context) => Row(children: [
        ClipPath(
            clipper: _MarkClipper(),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  PreferenceScope.of(context).palette.color,
                  PreferenceScope.of(context).palette.dark
                ],
              )),
              child: const Text('I',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic)),
            )),
        const SizedBox(width: 12),
        Flexible(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text.rich(
              TextSpan(children: [
                TextSpan(text: 'IRON '),
                TextSpan(
                    text: 'LOG',
                    style: TextStyle(
                        color: PreferenceScope.of(context).palette.color)),
              ]),
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Copy('Καταγραφή απόδοσης',
              style: TextStyle(fontSize: 12, color: IronColors.muted)),
        ])),
      ]);
}

class _MarkClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * .28, 0)
    ..lineTo(size.width * .88, 0)
    ..lineTo(size.width * .72, size.height)
    ..lineTo(size.width * .12, size.height)
    ..close();
  @override
  bool shouldReclip(_MarkClipper oldClipper) => false;
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Copy(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: IronColors.soft)),
        const SizedBox(height: 8),
        Semantics(
            label: PreferenceScope.of(context).translate(label), child: child),
      ]);
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {super.key, required this.onPressed, required this.child});
  final VoidCallback? onPressed;
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                PreferenceScope.of(context).palette.color,
                PreferenceScope.of(context).palette.dark
              ],
            )),
        child: FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent),
          onPressed: onPressed,
          child: child,
        ),
      );
}
