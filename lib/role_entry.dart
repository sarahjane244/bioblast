import 'package:flutter/material.dart';
import 'common.dart';
import 'home.dart';
import 'student_account.dart';
import 'teacher_login.dart';

/// Separate role entry. Online teacher mode uses server authentication.
/// The local device-only fallback is exclusively for demos without an API URL.
class BioBlastRoleEntry extends StatelessWidget {
  const BioBlastRoleEntry({super.key});

  void _openStudent(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => StudentAccount.signedIn
          ? const HomeScreen()
          : const StudentEntryScreen(),
    ));
  }

  void _openTeacher(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => const TeacherLoginScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) => OrientationLock(
    portrait: true,
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                const Icon(Icons.biotech_rounded, color: cGreen, size: 76),
                const SizedBox(height: 12),
                const Text('BioBlast', textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 40, color: cGreen)),
                const SizedBox(height: 8),
                const Text('Choose how to open the app', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17)),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => _openStudent(context),
                  icon: const Icon(Icons.school_rounded),
                  label: const Text('STUDENT'),
                  style: FilledButton.styleFrom(backgroundColor: cGreen, foregroundColor: cDark,
                    minimumSize: const Size.fromHeight(60)),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => _openTeacher(context),
                  icon: const Icon(Icons.groups_rounded),
                  label: const Text('TEACHER LOGIN'),
                  style: OutlinedButton.styleFrom(foregroundColor: cBlue,
                    side: const BorderSide(color: cBlue, width: 2),
                    minimumSize: const Size.fromHeight(60)),
                ),
                const SizedBox(height: 18),
                const Text('When a server URL is configured, teacher sign-in securely checks '
                  'the server and opens synchronized student records in one dashboard. '
                  'Demo backend only — not for real student data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
