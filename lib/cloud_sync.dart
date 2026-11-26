import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'student_account.dart';

/// Use --dart-define=BIOBLAST_API_URL=https://your-server.example when running.
/// Never include API passwords or class join codes in Flutter source.
class CloudSync {
  static const apiUrl = String.fromEnvironment('BIOBLAST_API_URL', defaultValue: '');
  static bool get configured => apiUrl.startsWith('https://') ||
      apiUrl.startsWith('http://localhost:') ||
      apiUrl.startsWith('http://127.0.0.1:') ||
      apiUrl.startsWith('http://10.') || apiUrl.startsWith('http://192.168.');
  static String get base => apiUrl.replaceFirst(RegExp(r'/$'), '');
  static String studentKey(String id) => 'cloud_token_$id';
  static const _teacherKey = 'cloud_teacher_token';

  static Future<String?> enroll(String code) async {
    if (!configured) return 'Server URL not configured. See ONLINE_SYNC_SETUP.md.';
    if (!StudentAccount.signedIn) return 'Choose a student profile first.';
    try {
      final r = await http.post(Uri.parse('$base/api/students/enroll'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'code': code.trim(), 'name': StudentAccount.fullName,
          'studentId': StudentAccount.id})).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return 'Join failed: ${_error(r)}';
      final token = (jsonDecode(r.body) as Map)['token']?.toString();
      if (token == null || token.isEmpty) return 'Server did not return a token.';
      final p = await SharedPreferences.getInstance();
      await p.setString(studentKey(StudentAccount.id), token);
      return await sync();
    } catch (_) { return 'Cannot reach server. Check internet and server URL.'; }
  }

  static Future<bool> get enrolled async {
    if (!StudentAccount.signedIn) return false;
    final p = await SharedPreferences.getInstance();
    return (p.getString(studentKey(StudentAccount.id)) ?? '').isNotEmpty;
  }

  /// Sends a complete snapshot. It is idempotent, so retries do not duplicate scores.
  /// If offline, the local pending_sync flag stays true until the server acknowledges.
  static Future<String?> sync() async {
    if (!configured || !StudentAccount.signedIn) return 'Cloud is not configured.';
    final p = await SharedPreferences.getInstance();
    final id = StudentAccount.id;
    final token = p.getString(studentKey(id));
    if (token == null || token.isEmpty) return 'Enter teacher-provided class join code first.';
    final lessons = <Map<String, dynamic>>[];
    for (var n = 1; n <= 8; n++) {
      bool done(String step) => p.getBool('student_${id}_f_s${n}_$step') ?? false;
      lessons.add({'number': n,
        'steps': {for (final k in ['learn', 'explore', 'sim', 'play']) k: done(k)},
        'scoreCorrect': p.getInt('student_${id}_score_s${n}_correct'),
        'scoreTotal': p.getInt('student_${id}_score_s${n}_total')});
    }
    final changedAt = p.getString('student_${id}_last_updated') ?? DateTime.now().toUtc().toIso8601String();
    try {
      final r = await http.post(Uri.parse('$base/api/students/sync'),
        headers: {'content-type': 'application/json', 'authorization': 'Bearer $token'},
        body: jsonEncode({'changedAt': changedAt, 'lessons': lessons})).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return 'Sync failed: ${_error(r)}';
      // Only clear pending if local data did not change while the request was in flight.
      if (p.getString('student_${id}_last_updated') == changedAt) {
        await p.setBool('student_${id}_pending_sync', false);
      }
      await p.setString('student_${id}_last_sync', DateTime.now().toIso8601String());
      return null;
    } catch (_) { return 'Offline. Your progress remains saved locally.'; }
  }

  static Future<String?> teacherSignIn(String email, String password) async {
    if (!configured) return 'Server URL not configured.';
    try {
      final r = await http.post(Uri.parse('$base/api/teacher/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password})).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return 'Sign in failed: ${_error(r)}';
      final token = (jsonDecode(r.body) as Map)['token']?.toString();
      if (token == null || token.isEmpty) return 'Invalid server reply.';
      final p = await SharedPreferences.getInstance();
      await p.setString(_teacherKey, token);
      return null;
    } catch (_) { return 'Cannot reach the online server.'; }
  }

  static Future<List<dynamic>> teacherStudents() async {
    if (!configured) throw Exception('Server URL is not configured.');
    final p = await SharedPreferences.getInstance();
    final token = p.getString(_teacherKey);
    if (token == null) throw Exception('Sign in to the online teacher account first.');
    final r = await http.get(Uri.parse('$base/api/teacher/students'),
      headers: {'authorization': 'Bearer $token'}).timeout(const Duration(seconds: 12));
    if (r.statusCode != 200) throw Exception(_error(r));
    return (jsonDecode(r.body) as Map)['students'] as List<dynamic>? ?? [];
  }

  static Future<void> teacherSignOut() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_teacherKey);
  }
  static String _error(http.Response r) {
    try { return (jsonDecode(r.body) as Map)['error']?.toString() ?? 'HTTP ${r.statusCode}'; }
    catch (_) { return 'HTTP ${r.statusCode}'; }
  }
}
