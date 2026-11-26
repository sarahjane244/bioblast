import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'visuals.dart' show BioWordmark;
import 'cloud_sync.dart';

/// Turn on while testing: shows "Skip video" and "Reset progress" shortcuts.
const kTestMode = false;

const cDark = Color(0xFF06142E);
const cPanel = Color(0xFF0C2A55);
const cGreen = Color(0xFF39E36B);
const cBlue = Color(0xFF2D9CFF);
const cOrange = Color(0xFFFF8A1F);
const cGray = Color(0xFF78909C);

// ---------------------------------------------------------------------
// Progress saved on the phone (offline)
// ---------------------------------------------------------------------
class Store {
  static SharedPreferences? _p;
  static const steps = ['learn', 'explore', 'sim', 'play', 'finish'];

  /// The session the student is currently inside (1 or 2). Set by the hub.
  static int cur = 1;

  static final Map<String, ValueNotifier<bool>> flags = {};
  static final coins = ValueNotifier<int>(0);
  static final bag = ValueNotifier<List<String>>([]);
  static final hero = ValueNotifier<int>(0);

  // Local records are tied to the active Student ID, never shared across learners.
  static String _studentId = '';
  static String _key(String value) => 'student_${_studentId}_$value';
  static String _k(int s, String step) => 's${s}_$step';
  static bool get hasStudent => _studentId.isNotEmpty;
  static bool get pendingSync => _p?.getBool(_key('pending_sync')) ?? false;
  static String? get lastUpdated => _p?.getString(_key('last_updated'));
  static Timer? _syncTimer;
  static void _changed() {
    if (!hasStudent) return;
    _p?.setBool(_key('pending_sync'), true);
    _p?.setString(_key('last_updated'), DateTime.now().toIso8601String());
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 4), () async {
      if (await CloudSync.enrolled) await CloudSync.sync();
    });
  }


  static ValueNotifier<bool> flag(int s, String step) => flags.putIfAbsent(_k(s, step), () => ValueNotifier<bool>(false));

  static Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    await loadStudent(_p!.getString('bioblast_active_student') ?? '');
  }

  static Future<void> loadStudent(String studentId) async {
    _p ??= await SharedPreferences.getInstance();
    _studentId = studentId;
    cur = 1;
    for (var s = 1; s <= 8; s++) {
      for (final st in steps) {
        flag(s, st).value = hasStudent
            ? (_p!.getBool(_key('f_${_k(s, st)}')) ?? false)
            : false;
      }
    }
    coins.value = hasStudent ? (_p!.getInt(_key('coins')) ?? 0) : 0;
    bag.value = hasStudent ? (_p!.getStringList(_key('bag')) ?? []) : [];
    hero.value = hasStudent ? (_p!.getInt(_key('hero')) ?? 0) : 0;
  }

  static bool isDone(String step, [int? s]) => flag(s ?? cur, step).value;

  static void mark(String step) {
    flag(cur, step).value = true;
    _p?.setBool(_key('f_${_k(cur, step)}'), true);
    _changed();
  }

  /// Save a per-session game score for local teacher progress monitoring.
  static void recordScore(int session, int correct, int total) {
    if (!hasStudent || total <= 0) return;
    _p?.setInt(_key('score_s${session}_correct'), correct);
    _p?.setInt(_key('score_s${session}_total'), total);
    _changed();
  }

  static void addCoins(int n) {
    coins.value += n;
    _p?.setInt(_key('coins'), coins.value);
    _changed();
  }

  static bool buy(String id, int cost) {
    if (coins.value < cost || bag.value.contains(id)) return false;
    coins.value -= cost;
    bag.value = [...bag.value, id];
    _p?.setInt(_key('coins'), coins.value);
    _changed();
    _p?.setStringList(_key('bag'), bag.value);
    _changed();
    return true;
  }

  static void setHero(int i) {
    hero.value = i;
    _p?.setInt(_key('hero'), i);
    _changed();
  }

  static Future<void> reset() async {
    for (var s = 1; s <= 8; s++) {
      for (final st in steps) {
        flag(s, st).value = false;
        await _p?.setBool(_key('f_${_k(s, st)}'), false);

      }
    }
    coins.value = 0;
    bag.value = [];
    hero.value = 0;
    await _p?.setInt(_key('coins'), 0);
    await _p?.setStringList(_key('bag'), []);
    await _p?.setInt(_key('hero'), 0);
    _changed();
  }
}

// ---------------------------------------------------------------------
// Read-aloud / narration (works offline with the phone's own voice)
// ---------------------------------------------------------------------
class Voice {
  static final FlutterTts _t = FlutterTts();
  static bool _ready = false;
  static double volume = 0.9;

  static Future<void> _setup() async {
    if (_ready) return;
    _ready = true;
    try {
      await _t.setLanguage('en-US');
      await _t.setSpeechRate(0.42);
      await _t.setPitch(1.1);
    } catch (_) {}
  }

  static Future<void> say(String text) async {
    if (volume <= 0) return;
    try {
      await _setup();
      await _t.setVolume(volume);
      await _t.stop();
      await _t.speak(text);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _t.stop();
    } catch (_) {}
  }
}

// ---------------------------------------------------------------------
// Backdrop: dark lab with floating particles (or sunny gradient for Learn)
// ---------------------------------------------------------------------
class Backdrop extends StatefulWidget {
  final bool light;
  final Widget child;
  const Backdrop({super.key, this.light = false, required this.child});
  @override
  State<Backdrop> createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
  static const _emoji = ['🍎', '🍞', '⚡', '🍚', '🧫', '🍎', '⚡', '🍞'];

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Widget _floaters(double t) => Stack(children: [
        for (var i = 0; i < _emoji.length; i++)
          Align(
            alignment: Alignment(-0.92 + (i % 4) * 0.61 + math.sin((t + i / 8) * 2 * math.pi) * 0.05, (i < 4 ? -0.82 : 0.82) + math.cos((t * 2 + i / 8) * math.pi) * 0.06),
            child: Opacity(opacity: 0.8, child: Text(_emoji[i], style: const TextStyle(fontSize: 34))),
          ),
      ]);

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Container(
          decoration: BoxDecoration(
            gradient: widget.light
                ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFE96B), Color(0xFF9BE04A), Color(0xFF2EAE4F)])
                : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF04102A), Color(0xFF0A2350), Color(0xFF06142E)]),
          ),
        ),
        AnimatedBuilder(
          animation: c,
          builder: (_, __) => widget.light ? _floaters(c.value) : CustomPaint(painter: _DotsPainter(c.value), size: Size.infinite),
        ),
        widget.child,
      ]);
}

class _DotsPainter extends CustomPainter {
  final double t;
  _DotsPainter(this.t);
  @override
  void paint(Canvas c, Size s) {
    final r = math.Random(5);
    for (var i = 0; i < 6; i++) {
      final x = r.nextDouble() * s.width, y = r.nextDouble() * s.height, rad = 40 + r.nextDouble() * 60;
      c.drawCircle(Offset(x + math.sin((t + i) * 2 * math.pi) * 10, y), rad, Paint()..color = (i.isEven ? const Color(0xFF7E57C2) : cBlue).withValues(alpha: 0.10));
    }
    for (var i = 0; i < 36; i++) {
      final x = r.nextDouble() * s.width, b = r.nextDouble(), sp = 0.3 + r.nextDouble() * 0.7;
      final y = (b - t * sp) % 1.0;
      c.drawCircle(Offset(x, y * s.height), 1.5 + r.nextDouble() * 3.5, Paint()..color = Colors.cyanAccent.withValues(alpha: 0.25));
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) => old.t != t;
}

// ---------------------------------------------------------------------
// Orientation: Home / Menu / Learn list are PORTRAIT (like the phone mockup),
// every lesson step stays LANDSCAPE. Each screen re-applies its own
// orientation when it is shown again after a pop.
// ---------------------------------------------------------------------
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class OrientationLock extends StatefulWidget {
  final bool portrait;
  final Widget child;
  const OrientationLock({super.key, required this.portrait, required this.child});
  @override
  State<OrientationLock> createState() => _OrientationLockState();
}

class _OrientationLockState extends State<OrientationLock> with RouteAware {
  void _apply() => SystemChrome.setPreferredOrientations(widget.portrait
      ? [DeviceOrientation.portraitUp]
      : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

  @override
  void initState() {
    super.initState();
    _apply();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = ModalRoute.of(context);
    if (r != null) routeObserver.subscribe(this, r);
  }

  @override
  void didPopNext() => _apply();

  @override
  void didPush() => _apply();

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ---------------------------------------------------------------------
// Stage: lesson screens are built on a 16:9 landscape canvas (960 x 540)
// ---------------------------------------------------------------------
class Stage extends StatelessWidget {
  final Widget child;
  final bool light;
  const Stage({super.key, required this.child, this.light = false});
  @override
  Widget build(BuildContext context) => OrientationLock(
        portrait: false,
        child: Scaffold(
          body: Backdrop(
            light: light,
            child: SafeArea(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: FittedBox(fit: BoxFit.contain, child: SizedBox(width: 960, height: 540, child: child)),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Portrait canvas for the phone-style screens (Home, Menu, Learn list).
class PortraitStage extends StatelessWidget {
  final Widget child;
  const PortraitStage({super.key, required this.child});
  @override
  Widget build(BuildContext context) => OrientationLock(
        portrait: true,
        child: Scaffold(
          body: Stack(fit: StackFit.expand, children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF04102A), Color(0xFF0A2350), Color(0xFF06142E)]),
              ),
            ),
            SafeArea(child: child),
          ]),
        ),
      );
}

BoxDecoration panelDeco({Color border = cBlue, double r = 22, double alpha = 0.92}) => BoxDecoration(
      color: cPanel.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: border.withValues(alpha: 0.7), width: 2),
      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4))],
    );

// ---------------------------------------------------------------------
// Buttons (soft glow when available, pressed state, locked state)
// ---------------------------------------------------------------------
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Pressable({super.key, required this.child, this.onTap});
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => setState(() => down = true),
        onTapUp: (_) => setState(() => down = false),
        onTapCancel: () => setState(() => down = false),
        onTap: widget.onTap,
        child: AnimatedScale(scale: down ? 0.94 : 1, duration: const Duration(milliseconds: 90), child: widget.child),
      );
}

class GlowButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color color;
  final bool locked;
  final double width, height, font;
  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color = cGreen,
    this.locked = false,
    this.width = 220,
    this.height = 52,
    this.font = 20,
  });

  @override
  Widget build(BuildContext context) {
    final off = locked || onTap == null;
    return Pressable(
      onTap: off ? null : onTap,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: off ? const [Color(0xFF4A5A6E), Color(0xFF34424F)] : [Color.lerp(color, Colors.white, 0.3)!, color]),
          border: Border.all(color: Colors.white.withValues(alpha: off ? 0.25 : 0.8), width: 2),
          boxShadow: off ? null : [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 16)],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          if (locked) const Icon(Icons.lock, size: 22, color: Colors.white70) else if (icon != null) Icon(icon, size: font + 4, color: Colors.white),
          if (locked || icon != null) const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: TextStyle(fontSize: font, fontWeight: FontWeight.w900, color: off ? Colors.white70 : Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}

class CoinPill extends StatelessWidget {
  final int coins;
  const CoinPill({super.key, required this.coins});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: cPanel.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(24), border: Border.all(color: cBlue.withValues(alpha: 0.6), width: 2)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFFFFE082), Color(0xFFFFA000)])),
            child: const Icon(Icons.star_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text('$coins', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ]),
      );
}

class HomeButton extends StatelessWidget {
  const HomeButton({super.key});
  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () {
          Voice.stop();
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(shape: BoxShape.circle, color: cBlue, border: Border.all(color: Colors.white70, width: 2), boxShadow: [BoxShadow(color: cBlue.withValues(alpha: 0.5), blurRadius: 10)]),
          child: const Icon(Icons.home_rounded, size: 26),
        ),
      );
}

class TopBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool home;
  const TopBar({super.key, required this.title, this.trailing, this.home = true});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: SizedBox(
          height: 50,
          child: Row(children: [
            const SizedBox(width: 120, height: 46, child: FittedBox(child: BioWordmark(size: 26))),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: cPanel.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(26), border: Border.all(color: cBlue.withValues(alpha: 0.6), width: 2)),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            if (home) ...[const SizedBox(width: 12), const HomeButton()],
          ]),
        ),
      );
}

/// Text with **bold** key words.
Widget boldText(String s, TextStyle base, Color boldColor, {TextAlign align = TextAlign.center}) {
  final parts = s.split('**');
  return RichText(
    textAlign: align,
    text: TextSpan(style: base, children: [
      for (var i = 0; i < parts.length; i++) TextSpan(text: parts[i], style: i.isOdd ? TextStyle(color: boldColor, fontWeight: FontWeight.w900) : null),
    ]),
  );
}
