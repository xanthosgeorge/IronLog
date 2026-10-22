import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_controller.dart';
import '../preferences.dart';
import '../ui.dart';
import 'catalog_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool busy = false;
  AppPreferences get preferences => widget.controller.preferences;
  String get userId => widget.controller.session!.user['id'].toString();
  Future<void> update(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (failure) {
      if (mounted) showFailure(context, failure);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> photo() async {
    await update(() async {
      final image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 256,
          maxHeight: 256,
          imageQuality: 85,
          requestFullMetadata: false);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception(
            preferences.translate('The image must be smaller than 5 MB.'));
      }
      final decoded = await decodeImageFromList(bytes);
      decoded.dispose();
      await preferences.setPhoto(userId, bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    PreferenceScope.of(context);
    final session = widget.controller.session!;
    final picture = preferences.photo(userId);
    return ListView(padding: const EdgeInsets.all(20), children: [
      const Copy('Profile photo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 20),
      Row(children: [
        CircleAvatar(
            radius: 32,
            backgroundColor: IronColors.panel,
            foregroundImage: picture == null ? null : MemoryImage(picture),
            child: Text(session.initials)),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(session.name,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(session.user['email'] as String,
              style: const TextStyle(color: IronColors.muted),
              overflow: TextOverflow.ellipsis),
        ])),
      ]),
      const SizedBox(height: 16),
      Wrap(spacing: 8, children: [
        OutlinedButton.icon(
            onPressed: busy ? null : photo,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Copy(picture == null ? 'Add photo' : 'Change photo')),
        if (picture != null)
          IconButton(
              tooltip: preferences.translate('Remove photo'),
              onPressed: busy
                  ? null
                  : () => update(() => preferences.setPhoto(userId, null)),
              icon: const Icon(Icons.delete_outline)),
      ]),
      const SizedBox(height: 24),
      const Divider(),
      const SizedBox(height: 24),
      const Copy('Language',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      SegmentedButton<String>(
          selected: {
            preferences.language
          },
          segments: const [
            ButtonSegment(value: 'el', label: Text('Ελληνικά')),
            ButtonSegment(value: 'en', label: Text('English'))
          ],
          onSelectionChanged: busy
              ? null
              : (value) => update(() => preferences.setLanguage(value.first))),
      const SizedBox(height: 24),
      const Divider(),
      const SizedBox(height: 24),
      const Copy('Appearance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      RadioGroup<String>(
          groupValue: preferences.theme,
          onChanged: (value) {
            if (!busy && value != null) {
              update(() => preferences.setTheme(value));
            }
          },
          child: Column(children: [
            for (final palette in palettes)
              Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: IronColors.panel,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                            color: preferences.theme == palette.id
                                ? palette.soft
                                : IronColors.border)),
                    child: RadioListTile<String>(
                      value: palette.id,
                      activeColor: palette.soft,
                      enabled: !busy,
                      title: Row(children: [
                        Container(
                            width: 32,
                            height: 26,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(stops: const [
                                  .5,
                                  .5
                                ], colors: [
                                  palette.color,
                                  const Color(0xff555b65)
                                ]))),
                        const SizedBox(width: 12),
                        Expanded(child: Copy(palette.label))
                      ]),
                    ),
                  )),
          ])),
      const SizedBox(height: 24),
      const Divider(),
      const SizedBox(height: 16),
      OutlinedButton.icon(
          onPressed: busy ? null : () => update(widget.controller.logout),
          icon: const Icon(Icons.logout),
          label: const Copy('Log out')),
    ]);
  }
}
