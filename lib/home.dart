import 'dart:async';
import 'package:flutter/material.dart';
import 'common.dart';
import 'hub.dart';
import 'learn_list.dart';
import 'play.dart';
import 'shop.dart';
import 'visuals.dart';
import 'student_account.dart';
import 'cell_cafe.dart';

// =====================================================================
// HOME (mockup screen 2) + MAIN MENU (mockup screen 3)
// The very first screen after the splash. PLAY opens the sessions
// (LEARN -> EXPLORE -> SIMULATE -> PLAY), and the bottom bar / menu jump
// to Learn, Play, My Cafe and Progress.
// =====================================================================

const _kStepKeys = ['learn', 'explore', 'sim', 'play'];
const _kStepNames = ['Learn', 'Explore', 'Simulate', 'Play'];
const _kSessions = 8;

/// Small helpers about how far the student has got (all read from [Store]).
class Journey {
  /// First session whose PLAY step is not finished yet (8 when everything is done).
  static int currentSession() {
    for (var s = 1; s <= _kSessions; s++) {
      if (!Store.isDone('play', s)) return s;
    }
    return _kSessions;
  }

  static bool allDone() => Store.isDone('play', _kSessions);

  /// Name of the next step to do inside [s].
  static String nextStep(int s) {
    for (var i = 0; i < _kStepKeys.length; i++) {
      if (!Store.isDone(_kStepKeys[i], s)) return _kStepNames[i];
    }
    return 'Done';
  }

  /// Highest session where [step] is finished, or null.
  static int? lastWith(String step) {
    for (var s = _kSessions; s >= 1; s--) {
      if (Store.isDone(step, s)) return s;
    }
    return null;
  }

  static int stepsDone() {
    var n = 0;
    for (var s = 1; s <= _kSessions; s++) {
      for (final k in _kStepKeys) {
        if (Store.isDone(k, s)) n++;
      }
    }
    return n;
  }

  static int sessionsDone() {
    var n = 0;
    for (var s = 1; s <= _kSessions; s++) {
      if (Store.isDone('play', s)) n++;
    }
    return n;
  }

  /// A level goes up every 3 finished steps.
  static const stepsPerLevel = 3;
  static int level() => 1 + stepsDone() ~/ stepsPerLevel;
  static double levelProgress() => (stepsDone() % stepsPerLevel) / stepsPerLevel;
}

/// Where each button goes. Every action returns a message when it is blocked
/// (so the caller can show it), or null when it navigated.
class Go {
  static void sessions(BuildContext c, [int? session]) {
    Navigator.push(c, MaterialPageRoute(builder: (_) => HubScreen(initial: session ?? Journey.currentSession())));
  }

  static String? learn(BuildContext c) {
    Navigator.push(c, MaterialPageRoute(builder: (_) => const LearnListScreen()));
    return null;
  }

  static String? play(BuildContext c) {
    final s = Journey.lastWith('sim');
    if (s == null) {
      return 'Finish Learn, Explore and Simulate first to unlock the games.';
    }
    Store.cur = s;
    Navigator.push(c, MaterialPageRoute(builder: (_) => const PlayStartScreen()));
    return null;
  }

  static String? cafe(BuildContext c) {
    final s = Journey.lastWith('play');
    if (s == null) return 'Play the 3 rounds of a session to open My Cafe.';
    Store.cur = s;
    Navigator.push(c, MaterialPageRoute(builder: (_) => ShopScreen(session: s)));
    return null;
  }

  static void progress(BuildContext c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const ProgressScreen()));
  static void settings(BuildContext c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const SettingsScreen()));
}

// ---------------------------------------------------------------------
// HOME SCREEN (portrait, like the phone mockup)
// ---------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool menuOpen = false;
  String? toast;
  Timer? toastTimer;

  @override
  void dispose() {
    toastTimer?.cancel();
    super.dispose();
  }

  void say(String? msg) {
    if (msg == null) return;
    toastTimer?.cancel();
    setState(() => toast = msg);
    toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => toast = null);
    });
  }

  void closeMenu() => setState(() => menuOpen = false);

  // ---- top-left: who you are ----
  Widget profile() => Container(
        height: 56,
        padding: const EdgeInsets.fromLTRB(5, 4, 14, 4),
        decoration: BoxDecoration(color: cPanel.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(28), border: Border.all(color: cBlue.withValues(alpha: 0.6), width: 2)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white70, width: 2)),
            child: HeroAvatar(hero: Store.hero.value.clamp(0, 3).toInt(), size: 44),
          ),
          const SizedBox(width: 8),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hi, ${StudentAccount.fullName.split(' ').first}!', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Row(children: [
              Text('Level ${Journey.level()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF8BE04A))),
              const SizedBox(width: 6),
              Container(
                width: 40,
                height: 7,
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(widthFactor: Journey.levelProgress().clamp(0.05, 1.0).toDouble(), child: Container(decoration: BoxDecoration(color: const Color(0xFF8BE04A), borderRadius: BorderRadius.circular(4)))),
                ),
              ),
            ]),
          ]),
        ]),
      );

  Widget menuButton() => Pressable(
        onTap: () => setState(() => menuOpen = true),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle, color: cPanel, border: Border.all(color: Colors.white70, width: 2)),
          child: const Icon(Icons.menu_rounded, size: 26),
        ),
      );

  Widget continueLine() {
    final s = Journey.currentSession();
    final text = Journey.allDone() ? 'All 8 sessions complete! Replay any time.' : 'Next up: Session $s  •  ${Journey.nextStep(s)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: cPanel.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(20), border: Border.all(color: cBlue.withValues(alpha: 0.5), width: 1.5)),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFB3E5FC))),
    );
  }

  Widget bottomNav() => AppBottomNav(on: 'HOME', say: say);

  // ---- main navigation menu (mockup screen 3) ----
  Widget menuTile(String title, String sub, IconData icon, Color color, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Pressable(
          onTap: () {
            closeMenu();
            onTap();
          },
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2147),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color, width: 2.5),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 10)],
            ),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(color, Colors.white, 0.3)!, color])),
                child: Icon(icon, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ]),
          ),
        ),
      );

  Widget menuOverlay() => Positioned.fill(
        child: GestureDetector(
          onTap: closeMenu,
          child: Container(
            color: Colors.black.withValues(alpha: 0.72),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: GestureDetector(
              onTap: () {},
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  decoration: BoxDecoration(color: cDark.withValues(alpha: 0.98), borderRadius: BorderRadius.circular(28), border: Border.all(color: cBlue, width: 2.5), boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 24)]),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      const Expanded(child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: 130, height: 44, child: FittedBox(child: BioWordmark(size: 24))))),
                      Pressable(
                        onTap: closeMenu,
                        child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: cPanel, border: Border.all(color: Colors.white70, width: 2)), child: const Icon(Icons.close_rounded, size: 24)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    menuTile('HOME', 'Back to main lab', Icons.home_rounded, const Color(0xFF39E36B), () {}),
                    menuTile('LEARN', 'Explore lessons', Icons.menu_book_rounded, cBlue, () => say(Go.learn(context))),
                    menuTile('PLAY', 'Interactive games', Icons.sports_esports_rounded, const Color(0xFFFFC107), () => say(Go.play(context))),
                    menuTile('CELL CAFÉ', 'New cellular respiration café game', Icons.local_cafe_rounded, cOrange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CellCafeMenu()))),
                    menuTile('PROGRESS', 'View achievements', Icons.bar_chart_rounded, const Color(0xFF2EAE4F), () => Go.progress(context)),
                    menuTile('MY DASHBOARD', 'Full name and lesson completion', Icons.person_rounded, cBlue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentDashboardScreen()))),
                    const SizedBox(height: 2),
                    Pressable(
                      onTap: () {
                        closeMenu();
                        Go.settings(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.settings_rounded, size: 22, color: Color(0xFF8FD3FF)),
                          SizedBox(width: 8),
                          Text('Settings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF8FD3FF))),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => PortraitStage(
        child: AnimatedBuilder(
          animation: Listenable.merge([...Store.flags.values, Store.coins, Store.hero]),
          builder: (context, _) => Stack(children: [
            Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(children: [profile(), const Spacer(), CoinPill(coins: Store.coins.value), const SizedBox(width: 10), menuButton()]),
              ),
              Expanded(
                child: Column(children: [
                  const SizedBox(height: 14),
                  const FittedBox(fit: BoxFit.scaleDown, child: BioWordmark(size: 58)),
                  const SizedBox(height: 4),
                  const Tagline(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                      child: const FittedBox(fit: BoxFit.contain, child: GlowPlant()),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: continueLine()),
                  const SizedBox(height: 16),
                ]),
              ),
              bottomNav(),
            ]),
            if (toast != null)
              Positioned(
                left: 24,
                right: 24,
                bottom: 88,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFFFC107), borderRadius: BorderRadius.circular(22)),
                  child: Text(toast!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF5A3200))),
                ),
              ),
            if (menuOpen) menuOverlay(),
          ]),
        ),
      );
}

// ---------------------------------------------------------------------
// Bottom navigation bar shared by Home and Progress (mockup bottom bar)
// ---------------------------------------------------------------------
class AppBottomNav extends StatelessWidget {
  final String on;
  final void Function(String?) say;
  const AppBottomNav({super.key, required this.on, required this.say});

  Widget item(String label, IconData icon, {bool locked = false, VoidCallback? onTap}) {
    final isOn = on == label;
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Opacity(
          opacity: locked ? 0.5 : 1,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isOn ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8BE04A), Color(0xFF2EAE4F)]) : null,
              boxShadow: isOn ? [BoxShadow(color: cGreen.withValues(alpha: 0.5), blurRadius: 12)] : null,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(locked ? Icons.lock_rounded : icon, size: 26, color: isOn ? Colors.white : const Color(0xFF8FB4D9)),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isOn ? Colors.white : const Color(0xFF8FB4D9)))),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        height: 66,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: cPanel.withValues(alpha: 0.96), borderRadius: BorderRadius.circular(24), border: Border.all(color: cBlue.withValues(alpha: 0.6), width: 2), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12)]),
        child: Row(children: [
          item('HOME', Icons.home_rounded, onTap: () {
            if (on != 'HOME') Navigator.of(context).popUntil((r) => r.isFirst);
          }),
          item('LEARN', Icons.menu_book_rounded, onTap: () => say(Go.learn(context))),
          item('PLAY', Icons.sports_esports_rounded, locked: Journey.lastWith('sim') == null, onTap: () => say(Go.play(context))),
          item('MY CAFE', Icons.local_cafe_rounded, locked: Journey.lastWith('play') == null, onTap: () => say(Go.cafe(context))),
          item('PROGRESS', Icons.bar_chart_rounded, onTap: () {
            if (on != 'PROGRESS') Go.progress(context);
          }),
        ]),
      );
}

// ---------------------------------------------------------------------
// PROGRESS (mockup screen 15): level, your stats, achievements
// ---------------------------------------------------------------------
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String? toast;
  Timer? toastTimer;

  @override
  void dispose() {
    toastTimer?.cancel();
    super.dispose();
  }

  void say(String? msg) {
    if (msg == null) return;
    toastTimer?.cancel();
    setState(() => toast = msg);
    toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => toast = null);
    });
  }

  int count(String step) {
    var n = 0;
    for (var s = 1; s <= _kSessions; s++) {
      if (Store.isDone(step, s)) n++;
    }
    return n;
  }

  Widget profileCard() {
    final into = Journey.stepsDone() % Journey.stepsPerLevel;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: panelDeco(border: cBlue),
      child: Row(children: [
        Container(
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white70, width: 2)),
          child: HeroAvatar(hero: Store.hero.value.clamp(0, 3).toInt(), size: 62),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(StudentAccount.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            Text('Level ${Journey.level()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF8BE04A))),
            const SizedBox(height: 8),
            Stack(alignment: Alignment.center, children: [
              Container(
                height: 20,
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: Journey.levelProgress().clamp(0.06, 1.0).toDouble(),
                    child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: const LinearGradient(colors: [Color(0xFF8BE04A), Color(0xFF43D854)]))),
                  ),
                ),
              ),
              Text('$into/${Journey.stepsPerLevel} steps to next level', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget statCard(String big, String label, IconData icon, Color color) => Expanded(
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: panelDeco(border: color, r: 16),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color.lerp(color, Colors.white, 0.3)!, color])), child: Icon(icon, size: 22, color: Colors.white)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w700)),
                FittedBox(fit: BoxFit.scaleDown, child: Text(big, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
              ]),
            ),
          ]),
        ),
      );

  Widget badge(String label, IconData icon, Color color, bool earned) => SizedBox(
        width: 74,
        child: Column(children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: earned ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(color, Colors.white, 0.35)!, color]) : const LinearGradient(colors: [Color(0xFF37474F), Color(0xFF263238)]),
              border: Border.all(color: earned ? Colors.white : Colors.white24, width: 2.5),
              boxShadow: earned ? [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 14)] : null,
            ),
            child: Icon(earned ? icon : Icons.lock_rounded, size: 30, color: earned ? Colors.white : Colors.white38),
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: earned ? Colors.white : Colors.white38, height: 1.1)),
        ]),
      );

  Widget sessionRow(int s) {
    final done = Store.isDone('finish', s);
    return Container(
      height: 46,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF0A2147), borderRadius: BorderRadius.circular(12), border: Border.all(color: done ? cGreen : cBlue.withValues(alpha: 0.5), width: 1.5)),
      child: Row(children: [
        Expanded(child: Text('Session $s  •  ${sessionTitle(s)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
        for (var i = 0; i < 4; i++) ...[
          const SizedBox(width: 5),
          Icon(Store.isDone(_kStepKeys[i], s) ? Icons.check_circle_rounded : Icons.circle_outlined, size: 20, color: Store.isDone(_kStepKeys[i], s) ? cGreen : Colors.white30),
        ],
        if (done) ...[const SizedBox(width: 6), const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFC107), size: 22)],
      ]),
    );
  }

  Widget heading(String t) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Align(alignment: Alignment.centerLeft, child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
      );

  @override
  Widget build(BuildContext context) => PortraitStage(
        child: AnimatedBuilder(
          animation: Listenable.merge([...Store.flags.values, Store.coins, Store.bag, Store.hero]),
          builder: (context, _) => Stack(children: [
            Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 8),
                child: Row(children: [
                  Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: cPanel, border: Border.all(color: Colors.white70, width: 2)), child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Progress', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
                  CoinPill(coins: Store.coins.value),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                  child: Column(children: [
                    profileCard(),
                    heading('Your Stats'),
                    Row(children: [
                      statCard('${count('learn')}/$_kSessions', 'Lessons', Icons.menu_book_rounded, cBlue),
                      const SizedBox(width: 10),
                      statCard('${count('sim') + count('play')}/${_kSessions * 2}', 'Challenges', Icons.flag_rounded, cOrange),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      statCard('${Store.bag.value.length}', 'Cafe Items', Icons.local_cafe_rounded, const Color(0xFFB36B2E)),
                      const SizedBox(width: 10),
                      statCard('${Store.coins.value}', 'Total Points', Icons.star_rounded, const Color(0xFFFFC107)),
                    ]),
                    heading('Achievements'),
                    Wrap(spacing: 8, runSpacing: 14, alignment: WrapAlignment.spaceBetween, children: [
                      badge('First Step', Icons.eco_rounded, const Color(0xFF39E36B), count('learn') > 0),
                      badge('Explorer', Icons.ondemand_video_rounded, cBlue, count('explore') > 0),
                      badge('Scientist', Icons.science_rounded, const Color(0xFF9B59B6), count('sim') > 0),
                      badge('Champion', Icons.emoji_events_rounded, const Color(0xFFFFC107), count('play') > 0),
                      badge('Cafe Owner', Icons.local_cafe_rounded, const Color(0xFFB36B2E), Store.bag.value.isNotEmpty),
                      badge('Week Master', Icons.military_tech_rounded, cOrange, count('finish') > 0),
                      badge('Level 3', Icons.workspace_premium_rounded, const Color(0xFF8BE04A), Journey.level() >= 3),
                      badge('All Done', Icons.flag_rounded, const Color(0xFFE91E63), Journey.allDone()),
                    ]),
                    heading('Sessions'),
                    for (var s = 1; s <= _kSessions; s++) sessionRow(s),
                  ]),
                ),
              ),
              AppBottomNav(on: 'PROGRESS', say: say),
            ]),
            if (toast != null)
              Positioned(
                left: 24,
                right: 24,
                bottom: 88,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFFFC107), borderRadius: BorderRadius.circular(22)),
                  child: Text(toast!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF5A3200))),
                ),
              ),
          ]),
        ),
      );
}

// ---------------------------------------------------------------------
// SETTINGS: narration volume and reset
// ---------------------------------------------------------------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool confirm = false;

  @override
  Widget build(BuildContext context) => Stage(
        child: Stack(children: [
          Column(children: [
            const TopBar(title: 'Settings'),
            Expanded(
              child: Center(
                child: Container(
                  width: 520,
                  padding: const EdgeInsets.all(24),
                  decoration: panelDeco(),
                  child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Narration volume', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    Row(children: [
                      Icon(Voice.volume <= 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: cBlue),
                      Expanded(
                        child: Slider(
                          value: Voice.volume.clamp(0.0, 1.0).toDouble(),
                          onChanged: (v) => setState(() => Voice.volume = v),
                          onChangeEnd: (_) => Voice.say('Hello, scientist!'),
                        ),
                      ),
                      Text('${(Voice.volume * 100).round()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 14),
                    const Text('Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('Start over: clears finished steps, coins and shop items on this device.', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 12),
                    GlowButton(label: 'Reset progress', icon: Icons.restart_alt_rounded, color: const Color(0xFFE53935), width: 260, height: 48, font: 18, onTap: () => setState(() => confirm = true)),
                  ]),
                ),
              ),
            ),
          ]),
          if (confirm)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: Container(
                  width: 430,
                  padding: const EdgeInsets.all(22),
                  decoration: panelDeco(border: const Color(0xFFE53935)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Reset all progress?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text('This cannot be undone.', style: TextStyle(fontSize: 16, color: Colors.white70)),
                    const SizedBox(height: 18),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      GlowButton(label: 'Cancel', color: cBlue, width: 150, height: 46, font: 18, onTap: () => setState(() => confirm = false)),
                      const SizedBox(width: 14),
                      GlowButton(
                        label: 'Reset',
                        color: const Color(0xFFE53935),
                        width: 150,
                        height: 46,
                        font: 18,
                        onTap: () async {
                          await Store.reset();
                          if (mounted) setState(() => confirm = false);
                        },
                      ),
                    ]),
                  ]),
                ),
              ),
            ),
        ]),
      );
}
