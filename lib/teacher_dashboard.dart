import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'common.dart';
import 'hub.dart' show sessionTitle;
import 'student_account.dart';
import 'teacher_login.dart';
import 'cloud_sync.dart';

/// Local-only teacher preview. Reads profiles and progress stored in this
/// installation; cross-device monitoring requires a backend and authentication.
class TeacherStudentSnapshot {
  final String id;
  final String name;
  final List<int> stepsPerLesson;
  final List<bool> completed;
  final List<String?> scores;
  final String? lastUpdated;

  const TeacherStudentSnapshot({
    required this.id, required this.name, required this.stepsPerLesson,
    required this.completed, required this.scores, this.lastUpdated,
  });

  int get completedLessons => completed.where((done) => done).length;
  int get completedSteps => stepsPerLesson.fold(0, (a, b) => a + b);

  /// Convert the server's eight-lesson snapshot into the same model used by
  /// local preview, without mixing student records from separate sources.
  static TeacherStudentSnapshot fromServer(Map<String, dynamic> data) {
    final rawLessons = data['lessons'] as List<dynamic>? ?? const [];
    final byNumber = <int, Map<String, dynamic>>{};
    for (final raw in rawLessons) {
      if (raw is! Map) continue;
      final lesson = Map<String, dynamic>.from(raw);
      final number = lesson['number'];
      if (number is int && number >= 1 && number <= 8) byNumber[number] = lesson;
    }
    final steps = <int>[];
    final completed = <bool>[];
    final scores = <String?>[];
    for (var n = 1; n <= 8; n++) {
      final lesson = byNumber[n] ?? const <String, dynamic>{};
      final fields = lesson['steps'] is Map
          ? Map<String, dynamic>.from(lesson['steps'] as Map)
          : const <String, dynamic>{};
      steps.add(['learn', 'explore', 'sim', 'play'].where((k) => fields[k] == true).length);
      completed.add(fields['play'] == true);
      final correct = lesson['scoreCorrect'];
      final total = lesson['scoreTotal'];
      scores.add(correct is int && total is int && total > 0
          ? '$correct / $total (${(correct * 100 / total).round()}%)' : null);
    }
    return TeacherStudentSnapshot(
      id: (data['id'] ?? '').toString(), name: (data['name'] ?? 'Student').toString(),
      stepsPerLesson: steps, completed: completed, scores: scores,
      lastUpdated: (data['receivedAt'] ?? data['changedAt'])?.toString(),
    );
  }

  static Future<List<TeacherStudentSnapshot>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await StudentAccount.profiles();
    final result = <TeacherStudentSnapshot>[];
    for (final p in profiles) {
      final id = p['id'] ?? '';
      if (id.isEmpty) continue;
      bool done(int session, String step) =>
          prefs.getBool('student_${id}_f_s${session}_$step') ?? false;
      final steps = <int>[];
      final completed = <bool>[];
      final scores = <String?>[];
      for (var s = 1; s <= 8; s++) {
        steps.add(['learn', 'explore', 'sim', 'play'].where((k) => done(s, k)).length);
        completed.add(done(s, 'play'));
        final correct = prefs.getInt('student_${id}_score_s${s}_correct');
        final total = prefs.getInt('student_${id}_score_s${s}_total');
        scores.add(correct == null || total == null || total == 0
            ? null : '$correct / $total (${(correct * 100 / total).round()}%)');
      }
      result.add(TeacherStudentSnapshot(
        id: id, name: p['fullName'] ?? 'Student',
        stepsPerLesson: steps, completed: completed, scores: scores,
        lastUpdated: prefs.getString('student_${id}_last_updated'),
      ));
    }
    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }
}

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});
  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  List<TeacherStudentSnapshot> students = [];
  bool loading = true;
  String search = '';
  String? loadError;

  @override
  void initState() { super.initState(); _refresh(); }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() { loading = true; loadError = null; });
    try {
      List<TeacherStudentSnapshot> list;
      if (TeacherPrototypeAuth.onlineMode) {
        final raw = await CloudSync.teacherStudents();
        list = raw.whereType<Map>().map((r) =>
            TeacherStudentSnapshot.fromServer(Map<String, dynamic>.from(r))).toList();
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      } else {
        list = await TeacherStudentSnapshot.loadAll();
      }
      if (mounted) setState(() { students = list; loading = false; });
    } catch (e) {
      if (mounted) setState(() { loading = false; loadError = e.toString(); });
    }
  }

  Widget _stat(String value, String label, IconData icon, Color color) =>
      Expanded(child: Card(color: cPanel, child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [Icon(icon, color: color, size: 26),
          const SizedBox(height: 7), Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70), textAlign: TextAlign.center),
        ]),
      )));

  @override
  Widget build(BuildContext context) {
    if (!TeacherPrototypeAuth.signedIn) {
      return const TeacherLoginScreen();
    }
    final shown = students.where((s) => s.name.toLowerCase().contains(search.toLowerCase())).toList();
    final finished = students.fold<int>(0, (a, s) => a + s.completedLessons);
    return OrientationLock(portrait: true, child: Scaffold(
      appBar: AppBar(title: const Text('BioBlast • Teacher'), backgroundColor: cDark,
        actions: [IconButton(tooltip: 'Refresh student records', icon: const Icon(Icons.refresh), onPressed: _refresh)]),
      body: RefreshIndicator(onRefresh: _refresh, child: ListView(
        padding: const EdgeInsets.all(16), children: [
        const Text('Teacher Dashboard', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(TeacherPrototypeAuth.onlineMode
          ? 'Online student records • Pull down or tap refresh to see the latest synced progress.'
          : 'Local device preview only. Restart with BIOBLAST_API_URL to view online records.',
          style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
        if (loadError != null) ...[
          const SizedBox(height: 12),
          Text('Cannot load student records: $loadError',
            style: const TextStyle(color: Colors.orangeAccent)),
          TextButton.icon(onPressed: _refresh,
            icon: const Icon(Icons.refresh), label: const Text('TRY AGAIN')),
        ],
        const SizedBox(height: 16),
        Row(children: [
          _stat('${students.length}', 'Students', Icons.groups, cBlue),
          _stat('$finished', 'Lessons finished', Icons.fact_check, cGreen),
          _stat('${students.isEmpty ? 0 : (finished * 100 / (students.length * 8)).round()}%',
              'Overall completion', Icons.trending_up, cOrange),
        ]),
        const SizedBox(height: 18),
        TextField(onChanged: (v) => setState(() => search = v),
          decoration: InputDecoration(hintText: 'Search student by full name',
            prefixIcon: const Icon(Icons.search), filled: true, fillColor: cPanel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
        const SizedBox(height: 18),
        Text('Students (${shown.length})', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (loading) const Center(child: CircularProgressIndicator())
        else if (shown.isEmpty) Padding(padding: const EdgeInsets.all(24),
          child: Text(TeacherPrototypeAuth.onlineMode ? 'No synchronized students yet. Students need to JOIN CLASS and SYNC NOW.' : 'No student records found on this device.', textAlign: TextAlign.center))
        else for (final student in shown) Card(color: cPanel,
          child: ExpansionTile(
            leading: const CircleAvatar(backgroundColor: cBlue, child: Icon(Icons.person, color: Colors.white)),
            title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${student.completedLessons} of 8 lessons completed'),
            childrenPadding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            children: [
              LinearProgressIndicator(value: student.completedLessons / 8, color: cGreen, minHeight: 8),
              const SizedBox(height: 12),
              for (var i = 0; i < 8; i++) ListTile(
                dense: true,
                leading: Icon(student.completed[i] ? Icons.check_circle : Icons.menu_book,
                  color: student.completed[i] ? cGreen : cBlue),
                title: Text('Lesson ${i + 1}: ${sessionTitle(i + 1)}',
                  style: const TextStyle(fontSize: 13)),
                subtitle: Text('${student.stepsPerLesson[i]}/4 steps • ${student.completed[i] ? 'Completed' : 'In progress / not started'}'
                  '${student.scores[i] == null ? '' : '\nGame score: ${student.scores[i]}'}',
                  style: const TextStyle(fontSize: 12)),
              ),
              if (student.lastUpdated != null) Text('Last ${TeacherPrototypeAuth.onlineMode ? 'server sync' : 'local update'}: ${student.lastUpdated}',
                style: const TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          )),
        const SizedBox(height: 24),
        OutlinedButton.icon(onPressed: () async {
          if (TeacherPrototypeAuth.onlineMode) await CloudSync.teacherSignOut();
          TeacherPrototypeAuth.signOut();
          if (!context.mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const TeacherLoginScreen()),
            (route) => route.isFirst,
          );
        },
          icon: const Icon(Icons.logout), label: const Text('Sign out')),
      ])),
    ));
  }
}
