import 'package:flutter/material.dart';
import '../preferences.dart';
import '../app_controller.dart';
import '../ui.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final first = TextEditingController();
  final last = TextEditingController();
  bool register = false, busy = false;
  String? error;
  String tr(String value) => PreferenceScope.of(context).translate(value);
  @override
  void dispose() {
    for (final controller in [email, password, first, last]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.controller.authenticate({
        'email': email.text.trim(),
        'password': password.text,
        if (register) 'firstName': first.text.trim(),
        if (register) 'lastName': last.text.trim(),
      }, register: register);
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget nameField(
          String label, TextEditingController controller, String hint) =>
      FieldLabel(
        label,
        child: TextFormField(
          controller: controller,
          enabled: !busy,
          autofillHints: [hint],
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              value!.trim().isEmpty ? tr('Συμπλήρωσε το πεδίο.') : null,
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
            child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            minHeight: (constraints.maxHeight - 48)
                                .clamp(0, double.infinity)),
                        child: Center(
                            child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 470),
                          child: Container(
                            padding: EdgeInsets.all(
                                constraints.maxWidth < 400 ? 24 : 32),
                            decoration: BoxDecoration(
                              border: Border.all(color: IronColors.border),
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xff23262d),
                                    IronColors.panel
                                  ]),
                            ),
                            child: AutofillGroup(
                                child: Form(
                                    key: form,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const IronBrand(),
                                        const SizedBox(height: 34),
                                        Copy('ΠΡΟΣΒΑΣΗ ΑΘΛΗΤΗ',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 7),
                                        Copy(
                                            register
                                                ? 'Δημιούργησε λογαριασμό'
                                                : 'Καλώς ήρθες',
                                            style: const TextStyle(
                                                fontSize: 30,
                                                height: 1.2,
                                                fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 9),
                                        Copy(
                                            register
                                                ? 'Ξεκίνα την καταγραφή των προπονήσεών σου.'
                                                : 'Συνδέσου για να συνεχίσεις την καταγραφή.',
                                            style: const TextStyle(
                                                color: IronColors.muted,
                                                fontSize: 16,
                                                height: 1.5)),
                                        const SizedBox(height: 26),
                                        if (register) ...[
                                          Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                    child: nameField(
                                                        'First name',
                                                        first,
                                                        AutofillHints
                                                            .givenName)),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                    child: nameField(
                                                        'Last name',
                                                        last,
                                                        AutofillHints
                                                            .familyName)),
                                              ]),
                                          const SizedBox(height: 17),
                                        ],
                                        FieldLabel('Διεύθυνση email',
                                            child: TextFormField(
                                              controller: email,
                                              enabled: !busy,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              autofillHints: const [
                                                AutofillHints.email
                                              ],
                                              autocorrect: false,
                                              textInputAction:
                                                  TextInputAction.next,
                                              validator: (value) => RegExp(
                                                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                                      .hasMatch(value!.trim())
                                                  ? null
                                                  : tr(
                                                      'Συμπλήρωσε ένα έγκυρο email.'),
                                            )),
                                        const SizedBox(height: 17),
                                        FieldLabel('Κωδικός',
                                            child: TextFormField(
                                              controller: password,
                                              enabled: !busy,
                                              obscureText: true,
                                              autofillHints: [
                                                register
                                                    ? AutofillHints.newPassword
                                                    : AutofillHints.password
                                              ],
                                              autocorrect: false,
                                              enableSuggestions: false,
                                              textInputAction:
                                                  TextInputAction.done,
                                              onFieldSubmitted: (_) => submit(),
                                              validator: (value) => value!
                                                      .isEmpty
                                                  ? tr(
                                                      'Συμπλήρωσε τον κωδικό σου.')
                                                  : register && value.length < 8
                                                      ? tr(
                                                          'Τουλάχιστον 8 χαρακτήρες.')
                                                      : null,
                                            )),
                                        if (error ?? widget.controller.notice
                                            case final message?) ...[
                                          const SizedBox(height: 14),
                                          Copy(message,
                                              style: const TextStyle(
                                                  color: Color(0xffff8581),
                                                  fontSize: 13)),
                                        ],
                                        const SizedBox(height: 21),
                                        PrimaryButton(
                                            onPressed: busy ? null : submit,
                                            child: busy
                                                ? const SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                Colors.white))
                                                : Copy(register
                                                    ? 'Δημιουργία λογαριασμού'
                                                    : 'Σύνδεση')),
                                        const SizedBox(height: 24),
                                        Copy(
                                            register
                                                ? 'Έχεις ήδη λογαριασμό;'
                                                : 'Πρώτη φορά στο IronLog;',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                color: IronColors.muted,
                                                fontSize: 15)),
                                        TextButton(
                                          style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 8)),
                                          onPressed: busy
                                              ? null
                                              : () => setState(() {
                                                    register = !register;
                                                    error = null;
                                                    form.currentState!.reset();
                                                  }),
                                          child: Copy(
                                              register
                                                  ? 'Σύνδεση'
                                                  : 'Δημιουργία λογαριασμού',
                                              textAlign: TextAlign.center),
                                        ),
                                      ],
                                    ))),
                          ),
                        )),
                      ),
                    ))),
      );
}
