import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'common.dart';
import 'home.dart';
import 'student_account.dart';
import 'role_entry.dart';
import 'visuals.dart' show LoadingView;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Store.load();
  await StudentAccount.initialize();
  runApp(const BioBlastApp());
}

class BioBlastApp extends StatelessWidget {
  const BioBlastApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BioBlast',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: cDark, colorSchemeSeed: cGreen, useMaterial3: true),
        navigatorObservers: [routeObserver],
        home: const SplashScreen(),
      );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int pct = 0;
  Timer? t;
  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(milliseconds: 40), (_) {
      setState(() => pct += 2);
      if (pct >= 100) {
        t?.cancel();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BioBlastRoleEntry()));
      }
    });
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OrientationLock(portrait: true, child: Scaffold(body: LoadingView(pct: pct)));
}
