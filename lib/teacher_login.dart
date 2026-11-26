import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common.dart';
import 'cloud_sync.dart';
import 'teacher_dashboard.dart';

/// FOR LOCAL TESTING ONLY. SharedPreferences is not secure account storage.
/// Production needs a backend identity service and server-enforced teacher roles.
class TeacherPrototypeAuth {
  static const _emailKey = 'teacher_preview_email_v1';
  static const _saltKey = 'teacher_preview_salt_v1';
  static const _hashKey = 'teacher_preview_hash_v1';
  static bool signedIn = false;
  // The online mode authenticates against the server; local fallback is for demos only.
  static bool get onlineMode => CloudSync.configured;

  static String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  static Future<bool> isConfigured() async {
    final p = await SharedPreferences.getInstance();
    return p.containsKey(_emailKey) && p.containsKey(_hashKey);
  }

  static Future<String?> setUp(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized)) {
      return 'Enter a valid email address.';
    }
    if (password.length < 8) return 'Use at least 8 characters for the password.';
    final p = await SharedPreferences.getInstance();
    if (await isConfigured()) return 'A local teacher profile already exists.';
    final random = Random.secure();
    final salt = base64UrlEncode(List<int>.generate(24, (_) => random.nextInt(256)));
    await p.setString(_emailKey, normalized);
    await p.setString(_saltKey, salt);
    await p.setString(_hashKey, _hash(salt, password));
    signedIn = true;
    return null;
  }

  static Future<bool> signIn(String email, String password) async {
    final p = await SharedPreferences.getInstance();
    final savedEmail = p.getString(_emailKey);
    final salt = p.getString(_saltKey);
    final savedHash = p.getString(_hashKey);
    final ok = savedEmail != null && salt != null && savedHash != null &&
        savedEmail == email.trim().toLowerCase() &&
        savedHash == _hash(salt, password);
    signedIn = ok;
    return ok;
  }

  static void signOut() => signedIn = false;
}

class TeacherLoginScreen extends StatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  State<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends State<TeacherLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  bool _hasAccount = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final exists = await TeacherPrototypeAuth.isConfigured();
    if (mounted) setState(() { _hasAccount = exists; _loading = false; });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    if (!TeacherPrototypeAuth.onlineMode && !_hasAccount && _password.text != _confirm.text) {
      setState(() { _busy = false; _error = 'Passwords do not match.'; });
      return;
    }
    String? error;
    if (TeacherPrototypeAuth.onlineMode) {
      // A single sign-in acquires the server token used by the dashboard.
      // Do not store a second copy of the teacher's password.
      error = await CloudSync.teacherSignIn(_email.text, _password.text);
      TeacherPrototypeAuth.signedIn = error == null;
    } else if (_hasAccount) {
      final ok = await TeacherPrototypeAuth.signIn(_email.text, _password.text);
      if (!ok) error = 'Incorrect email or password.';
    } else {
      error = await TeacherPrototypeAuth.setUp(_email.text, _password.text);
    }
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => const TeacherDashboardScreen(),
      ));
    } else {
      setState(() { _busy = false; _error = error; });
    }
  }

  @override
  Widget build(BuildContext context) => OrientationLock(
    portrait: true,
    child: Scaffold(
      appBar: AppBar(title: const Text('Teacher Access'), backgroundColor: cDark),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(22), children: [
          const Icon(Icons.school_rounded, color: cBlue, size: 68),
          const SizedBox(height: 12),
          Text(TeacherPrototypeAuth.onlineMode || _hasAccount ? 'Teacher Sign In' : 'Set Up Teacher Preview',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(TeacherPrototypeAuth.onlineMode
            ? 'Sign in once with the teacher account configured on the BioBlast server. '
              'Synchronized student records will appear on your dashboard. '
              'Local-network demonstration only — not for real student data.'
            : 'OFFLINE PREVIEW ONLY: This device-only profile cannot access online records. '
              'Start the app with BIOBLAST_API_URL to use server teacher login.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
          const SizedBox(height: 18),
          if (_loading) const Center(child: CircularProgressIndicator()) else ...[
            TextField(controller: _email, keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Teacher email',
                border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 14),
            TextField(controller: _password, obscureText: _hidePassword,
              decoration: InputDecoration(labelText: TeacherPrototypeAuth.onlineMode ? 'Server teacher password' : 'Password (8+ characters)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off)))),
            if (!TeacherPrototypeAuth.onlineMode && !_hasAccount) ...[
              const SizedBox(height: 14),
              TextField(controller: _confirm, obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm password',
                  border: OutlineInputBorder(), prefixIcon: Icon(Icons.verified_user_outlined))),
            ],
            if (_error != null) Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.orangeAccent))),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.login),
              label: Text(_busy ? 'Please wait...' : TeacherPrototypeAuth.onlineMode || _hasAccount ? 'SIGN IN' : 'CREATE LOCAL TEACHER PROFILE'),
              style: FilledButton.styleFrom(backgroundColor: cGreen,
                foregroundColor: cDark, minimumSize: const Size.fromHeight(54))),
          ],
        ]),
      )),
    ),
  );
}
