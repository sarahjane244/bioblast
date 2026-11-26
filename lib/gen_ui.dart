import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'art.dart';
import 'common.dart';
import 'gmodels.dart';
import 'gsessions.dart';
import 'gen_sim.dart';
import 'revised_audio.dart';

// =====================================================================
// bioIcon: one picture language for every session (glucose = orange hexagon,
// ATP = green battery, NADH = yellow taxi, FADH2 = scooter, etc.)
// =====================================================================
Widget _badge(String emoji, Color c, double size) => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: [Color.lerp(c, Colors.white, 0.5)!, c]),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: size * 0.04),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: size * 0.25)],
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.52)),
    );

Widget _balls(int n, Color c, double size, {String tag = ''}) {
  final d = size * 0.46;
  final pos = n == 3 ? [Offset(size * 0.27, 0), Offset(0, size * 0.5), Offset(size * 0.54, size * 0.5)] : [Offset(0, size * 0.25), Offset(size * 0.54, size * 0.25)];
  return SizedBox(
    width: size,
    height: size,
    child: Stack(children: [
      for (final p in pos) Positioned(left: p.dx, top: p.dy, child: Bubble(text: '', color: c, size: d)),
      if (tag.isNotEmpty) Positioned(left: 0, right: 0, bottom: 0, child: Center(child: Text(tag, style: TextStyle(fontSize: size * 0.2, fontWeight: FontWeight.w900)))),
    ]),
  );
}

Widget _ring(Color c, double size) {
  final d = size * 0.3, r = size * 0.35;
  return SizedBox(
    width: size,
    height: size,
    child: Stack(children: [
      for (var i = 0; i < 6; i++) Positioned(left: size / 2 + r * math.cos(i * math.pi / 3) - d / 2, top: size / 2 + r * math.sin(i * math.pi / 3) - d / 2, child: Bubble(text: '', color: c, size: d)),
      Center(child: Text('6C', style: TextStyle(fontSize: size * 0.2, fontWeight: FontWeight.w900))),
    ]),
  );
}

Widget _chainRow(double size) => SizedBox(
      width: size * 1.6,
      height: size * 0.6,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        for (final r in const ['I', 'II', 'III', 'IV'])
          Container(
            width: size * 0.34,
            height: size * 0.5,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFF8E44AD), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white70, width: 2)),
            child: Text(r, style: TextStyle(fontSize: size * 0.16, fontWeight: FontWeight.w900)),
          ),
      ]),
    );

Widget bioIcon(String k, {double size = 48}) {
  switch (k) {
    case 'coa':
      return Bubble(text: 'CoA', color: const Color(0xFF8E44AD), size: size);
    case 'acetylgroup':
      return _balls(2, const Color(0xFF14B8A6), size, tag: '2C');
    case 'partner':
      return Bubble(text: '4C', color: cGreen, size: size);
    case 'glucose':
      return HexIcon(size: size);
    case 'oxygen':
      return Bubble(text: 'O₂', color: cBlue, size: size);
    case 'oxygenpink':
      return Bubble(text: 'O₂', color: const Color(0xFFFF5C7A), size: size);
    case 'co2':
      return Bubble(text: 'CO₂', color: cGray, size: size);
    case 'water':
      return Bubble(text: 'H₂O', color: const Color(0xFF4FC3F7), size: size);
    case 'electron':
      return Bubble(text: 'e⁻', color: const Color(0xFFFFB300), size: size);
    case 'proton':
      return Bubble(text: 'H⁺', color: const Color(0xFFFF5252), size: size);
    case 'adp':
      return Bubble(text: 'ADP', color: const Color(0xFF26A69A), size: size);
    case 'atp':
      return BatteryIcon(width: size * 0.62, height: size);
    case 'atp2':
      return SizedBox(width: size * 1.3, height: size, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [BatteryIcon(width: size * 0.55, height: size * 0.9), SizedBox(width: size * 0.06), BatteryIcon(width: size * 0.55, height: size * 0.9)]));
    case 'mito':
    case 'matrix':
      return MitoArt(width: size * 1.5, glow: true, face: k == 'mito');
    case 'cristae':
      return MitoArt(width: size * 1.5);
    case 'mitoclosed':
      return SizedBox(width: size * 1.5, height: size * 0.85, child: Stack(alignment: Alignment.center, children: [MitoArt(width: size * 1.5), Icon(Icons.block, size: size * 0.8, color: const Color(0xFFE53935))]));
    case 'cell':
      return CellArt(width: size * 1.4, height: size);
    case 'resp':
      return TermIcon(i: 0, size: size);
    case 'aerobic':
      return TermIcon(i: 6, size: size);
    case 'anaerobic':
      return TermIcon(i: 7, size: size);
    case 'energy':
      return _badge('⚡', const Color(0xFFFFB300), size);
    case 'pyruvate':
      return _balls(3, const Color(0xFF14B8A6), size);
    case 'acetyl':
      return _balls(2, const Color(0xFF14B8A6), size, tag: 'CoA');
    case 'citrate':
      return _ring(const Color(0xFFFF9800), size);
    case 'nadh':
      return _badge('🚕', const Color(0xFFFFC107), size);
    case 'fad':
      return Bubble(text: 'FAD', color: cGray, size: size);
    case 'nad':
      return _badge('🚖', const Color(0xFF78909C), size);
    case 'fadh2':
      return _badge('🛵', const Color(0xFF42A5F5), size);
    case 'fadbus':
      return _badge('🚌', const Color(0xFFFB8C00), size);
    case 'carriers':
      return SizedBox(width: size * 1.5, height: size * 0.8, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [_badge('🚕', const Color(0xFFFFC107), size * 0.72), SizedBox(width: size * 0.06), _badge('🛵', const Color(0xFFFF9800), size * 0.72)]));
    case 'enzyme':
      return _badge('🔑', const Color(0xFF8E44AD), size);
    case 'cyto':
      return _badge('🫧', const Color(0xFF29B6F6), size);
    case 'glycolysis':
      return SizedBox(width: size * 1.7, height: size * 0.7, child: FittedBox(child: Row(mainAxisSize: MainAxisSize.min, children: [HexIcon(size: 40), const Icon(Icons.bolt, size: 30, color: Color(0xFFFFEB3B)), _balls(3, const Color(0xFF14B8A6), 34), const SizedBox(width: 4), _balls(3, const Color(0xFF14B8A6), 34)])));
    case 'net':
      return SizedBox(width: size * 1.7, height: size * 0.8, child: FittedBox(child: Row(mainAxisSize: MainAxisSize.min, children: const [BatteryIcon(width: 30, height: 48), SizedBox(width: 6), Text('= 2', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white))])));
    case 'yield':
      return SizedBox(width: size * 1.7, height: size * 0.8, child: FittedBox(child: Row(mainAxisSize: MainAxisSize.min, children: const [BatteryIcon(width: 30, height: 48, level: 0.2), SizedBox(width: 6), Text('2 ATP', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white))])));
    case 'wheel':
      return _badge('🎡', const Color(0xFFFF8F1F), size);
    case 'chain':
      return _chainRow(size);
    case 'innermem':
      return _badge('〰️', const Color(0xFFFF8F1F), size);
    case 'pump':
      return _badge('⛲', const Color(0xFFE53935), size);
    case 'turbine':
      return _badge('🌀', const Color(0xFF43A047), size);
    case 'ferment':
      return _badge('♻️', const Color(0xFF26A69A), size);
    case 'lactic':
      return _badge('💪', const Color(0xFFEC407A), size);
    case 'muscle':
      return _badge('💪', const Color(0xFFEC407A), size);
    case 'yeast':
      return _badge('🍄', const Color(0xFFFFA000), size);
    case 'ethanol':
      return _badge('⛽', const Color(0xFF8E44AD), size);
    case 'sprint':
      return _badge('🏃', const Color(0xFFEC407A), size);
    case 'bread':
      return _badge('🍞', const Color(0xFFFFA000), size);
    case 'yogurt':
      return _badge('🥛', const Color(0xFF90CAF9), size);
    case 'nooxygen':
      return SizedBox(width: size, height: size, child: Stack(alignment: Alignment.center, children: [Bubble(text: 'O₂', color: cBlue, size: size * 0.8), Icon(Icons.block, size: size, color: const Color(0xFFE53935))]));
    case 'sun':
      return _badge('☀️', const Color(0xFFFFB300), size);
    case 'chlorophyll':
      return _badge('🍃', const Color(0xFF43A047), size);
    case 'chloroplast':
      return _badge('🌿', const Color(0xFF2E7D32), size);
    default:
      return _badge('❓', cGray, size);
  }
}

double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0).toDouble();
Offset _lerp(Offset a, Offset b, double p) => Offset.lerp(a, b, Curves.easeInOut.transform(p))!;

// =====================================================================
// Loading animation shown before the game (3 to 5 seconds), one per session
// =====================================================================
Widget loadArt(String kind, double v) {
  switch (kind) {
    case 'mito':
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const MitoArt(width: 190, glow: true, face: true),
        const SizedBox(width: 14),
        const Icon(Icons.arrow_forward_rounded, size: 40),
        const SizedBox(width: 14),
        BatteryIcon(width: 56, height: 90, level: v),
      ]);
    case 'split':
      return SizedBox(
        height: 130,
        child: v < 0.5
            ? Transform.scale(scale: 1 + v * 0.3, child: bioIcon('glucose', size: 120))
            : Row(mainAxisSize: MainAxisSize.min, children: [bioIcon('pyruvate', size: 100), const Icon(Icons.bolt, size: 44, color: Color(0xFFFFEB3B)), bioIcon('pyruvate', size: 100)]),
      );
    case 'wheel':
      return Transform.rotate(angle: v * 2 * math.pi * 2, child: const Text('🎡', style: TextStyle(fontSize: 130)));
    case 'chain':
      return SizedBox(
        width: 380,
        height: 120,
        child: Stack(alignment: Alignment.center, children: [
          Center(child: _chainRow(150)),
          Positioned(left: 10 + v * 330, top: 38, child: Bubble(text: 'e⁻', color: const Color(0xFFFFB300), size: 44)),
        ]),
      );
    case 'nooxy':
      return SizedBox(
        height: 130,
        child: Stack(alignment: Alignment.center, children: [
          Transform.scale(scale: v < 0.7 ? 1 + v * 0.35 : math.max(0.0, 1 - (v - 0.7) * 2.2), child: Bubble(text: 'O₂', color: cBlue, size: 120)),
          if (v > 0.6) const Icon(Icons.block, size: 140, color: Color(0xFFE53935)),
        ]),
      );
    default:
      return bioIcon('mito', size: 120);
  }
}

// =====================================================================
// STEP 1: LEARN  (tap-to-flip cards, one at a time)
// =====================================================================
class GenLearnScreen extends StatefulWidget {
  final int session;
  const GenLearnScreen({super.key, required this.session});
  @override
  State<GenLearnScreen> createState() => _GenLearnState();
}

class _GenLearnState extends State<GenLearnScreen> with SingleTickerProviderStateMixin {
  late final SessionSpec spec = specFor(widget.session)!;
  int idx = 0;
  bool back = false;
  final flipped = <int>{};
  late final AnimationController flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  List<GTerm> get items => spec.terms;
  bool get allFlipped => flipped.length == items.length;

  @override
  void dispose() {
    flip.dispose();
    Voice.stop();
    super.dispose();
  }

  void toggle() {
    SystemSound.play(SystemSoundType.click);
    setState(() {
      back = !back;
      if (back) flipped.add(idx);
    });
    back ? flip.forward() : flip.reverse();
  }

  void go(int d) {
    Voice.stop();
    setState(() {
      idx += d;
      back = false;
    });
    flip.value = 0;
  }

  void speak() {
    final t = items[idx];
    Voice.say(widget.session == 4 || t.pictureOnly || back ? '${t.name}. ${t.plain}' : t.name);
  }

  Widget chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: fg)),
      );

  Widget tapHint(String text, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.touch_app, size: 18, color: c),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
      ]);

  Widget front(GTerm t) => Container(
        width: 400,
        height: 290,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(t.color, Colors.white, 0.35)!, t.color]),
          border: Border.all(color: Colors.white, width: 5),
          boxShadow: [BoxShadow(color: t.color.withValues(alpha: 0.7), blurRadius: 22)],
        ),
        child: Column(children: [
          if (!t.pictureOnly) chip(t.group.isEmpty ? 'Term' : t.group, Colors.white, t.color),
          Expanded(child: Center(child: t.image.isEmpty
            ? FittedBox(fit: BoxFit.scaleDown, child: bioIcon(t.icon, size: 110))
            : Padding(padding: const EdgeInsets.all(6), child: Image.asset(t.image, fit: BoxFit.contain, semanticLabel: t.name)))),
          if (!t.pictureOnly) Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(t.name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF16233B)))),
          ),
          const SizedBox(height: 6),
          tapHint('Tap to flip', Colors.white),
        ]),
      );

  Widget backFace(GTerm t) => Container(
        width: 400,
        height: 290,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: const Color(0xFFF4FAFF),
          border: Border.all(color: t.color, width: 7),
          boxShadow: [BoxShadow(color: t.color.withValues(alpha: 0.6), blurRadius: 22)],
        ),
        child: Column(children: [
          FittedBox(fit: BoxFit.scaleDown, child: chip(t.name, t.color, Colors.white)),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: 350,
                  child: boldText(t.def, const TextStyle(fontSize: 24, height: 1.3, color: Color(0xFF16233B), fontWeight: FontWeight.w600), t.color),
                ),
              ),
            ),
          ),
          tapHint('Tap to flip back', Colors.blueGrey),
        ]),
      );

  Widget progress() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: cPanel.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(24), border: Border.all(color: cBlue.withValues(alpha: 0.6), width: 2)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < items.length; i++)
            Container(
              width: items.length > 10 ? 7 : 11,
              height: items.length > 10 ? 7 : 11,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: flipped.contains(i) ? cGreen : Colors.transparent,
                border: Border.all(color: i == idx ? Colors.white : Colors.white54, width: i == idx ? 3 : 1.5),
              ),
            ),
          const SizedBox(width: 6),
          Text('${items.first.pictureOnly ? 'Card' : 'Term'} ${idx + 1} of ${items.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final t = items[idx];
    return Stage(
      light: !spec.darkLearn,
      child: Column(children: [
        TopBar(title: spec.learnTitle, trailing: progress()),
        Expanded(
          child: Center(
            child: GestureDetector(
              key: const ValueKey('revised_flip_card'),
              onTap: toggle,
              child: AnimatedBuilder(
                animation: flip,
                builder: (_, __) {
                  final v = flip.value;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(math.pi * v),
                    child: v > 0.5 ? Transform(alignment: Alignment.center, transform: Matrix4.identity()..rotateY(math.pi), child: backFace(t)) : front(t),
                  );
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            GlowButton(label: 'Previous', icon: Icons.arrow_back_rounded, color: cBlue, width: 190, onTap: idx > 0 ? () => go(-1) : null),
            Pressable(
              onTap: speak,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(color: cPanel, borderRadius: BorderRadius.circular(26), border: Border.all(color: cBlue, width: 2), boxShadow: [BoxShadow(color: cBlue.withValues(alpha: 0.5), blurRadius: 12)]),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.volume_up_rounded, size: 28),
                  SizedBox(width: 8),
                  Text('Read Aloud', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
            GlowButton(key: const ValueKey('revised_card_next'), label: 'Next', icon: Icons.arrow_forward_rounded, color: cBlue, width: 190, onTap: idx < items.length - 1 ? () => go(1) : null),
          ]),
        ),
        const SizedBox(height: 8),
        GlowButton(
          key: const ValueKey('revised_learn_continue'),
          label: 'Continue to Explore',
          icon: Icons.play_arrow_rounded,
          color: cGreen,
          width: 320,
          locked: !allFlipped,
          onTap: () {
            Voice.stop();
            Store.mark('learn');
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GenExploreScreen(session: widget.session)));
          },
        ),
        const SizedBox(height: 12),
      ]),
    );
  }
}

// =====================================================================
// STEP 2: EXPLORE  (2 minute animated video with narration and captions)
// The animation is scripted from the data in gdata_*.dart.
// =====================================================================
class GenExploreScreen extends StatefulWidget {
  final int session;
  const GenExploreScreen({super.key, required this.session});
  @override
  State<GenExploreScreen> createState() => _GenExploreState();
}

class _GenExploreState extends State<GenExploreScreen> with SingleTickerProviderStateMixin {
  static const total = 120.0;
  late final SessionSpec spec = specFor(widget.session)!;
  late final AnimationController ctl = AnimationController(vsync: this, duration: const Duration(seconds: 120));
  bool playing = false, ended = false, cc = true, revealed = false;
  double volume = 0.9;
  final music = LessonMusic();
  int spoken = -1;
  int? quickChoice;

  @override
  void initState() {
    super.initState();
    ctl.addListener(_tick);
    ctl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        Voice.stop();
        music.stop();
        Store.mark('explore');
        if (mounted) {
          setState(() {
            playing = false;
            ended = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    ctl.dispose();
    music.dispose();
    Voice.stop();
    super.dispose();
  }

  double get t => ctl.value * total;

  int get capIdx {
    var k = 0;
    for (var i = 0; i < spec.caps.length; i++) {
      if (t >= spec.caps[i].t) k = i;
    }
    return k;
  }

  void _tick() {
    if (!playing) return;
    final k = capIdx;
    if (k != spoken) {
      spoken = k;
      Voice.say(spec.caps[k].text);
    }
  }

  void play() {
    Voice.volume = volume;
    music.play(volume);
    setState(() => playing = true);
    spoken = -1;
    ctl.forward();
  }

  void pause() {
    ctl.stop();
    music.pause();
    Voice.stop();
    setState(() => playing = false);
  }

  void replay() {
    Voice.stop();
    music.stop().then((_) {if (mounted) music.play(volume);});
    spoken = -1;
    setState(() {
      ended = false;
      revealed = false;
      quickChoice = null;
      playing = true;
    });
    ctl.forward(from: 0);
  }

  String fmt(double s) => '${s ~/ 60}:${(s % 60).floor().toString().padLeft(2, '0')}';

  Widget tag(String s, {bool big = false}) => Container(
        padding: EdgeInsets.symmetric(horizontal: big ? 16 : 10, vertical: big ? 7 : 4),
        decoration: BoxDecoration(color: cPanel.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(14), border: Border.all(color: big ? cGreen : Colors.white54, width: big ? 2 : 1)),
        child: Text(s, style: TextStyle(fontSize: big ? 17 : 14, fontWeight: FontWeight.w900)),
      );

  List<Widget> background(String kind, double tt) {
    switch (kind) {
      case 'mito':
        return [Positioned(left: 100, top: 50, child: MitoArt(width: 440, glow: true))];
      case 'krebs':
        return [
          Positioned(left: 100, top: 50, child: MitoArt(width: 440, glow: true)),
          Positioned(left: 255, top: 88, child: Transform.rotate(angle: tt * 0.5, child: const Text('🎡', style: TextStyle(fontSize: 120)))),
        ];
      case 'chain':
        return [
          Positioned(left: 0, right: 0, top: 128, height: 44, child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFB74D), Color(0xFFF57C00)])))),
          for (final e in const [[95.0, 'I'], [205.0, 'II'], [325.0, 'III'], [445.0, 'IV']])
            Positioned(
              left: (e[0] as double) - 35,
              top: 116,
              child: Container(
                width: 70,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFF8E44AD), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white70, width: 2)),
                child: Text(e[1] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ),
            ),
          Positioned(
            left: 515,
            top: 100,
            child: Container(
              width: 90,
              height: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white70, width: 2)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Transform.rotate(angle: tt * 2, child: const Text('🌀', style: TextStyle(fontSize: 40))),
                const Text('ATP synthase', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
          const Positioned(left: 10, top: 74, child: Text('H⁺ side', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w700))),
          const Positioned(left: 10, bottom: 70, child: Text('Matrix', style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w700))),
        ];
      default:
        return [const Positioned(left: 85, top: 22, child: CellArt(width: 470, height: 296))];
    }
  }

  Widget scene(double tt) {
    var bg = spec.bgs.first.kind;
    for (final b in spec.bgs) {
      if (tt >= b.t) bg = b.kind;
    }
    final kids = <Widget>[...background(bg, tt)];
    for (final a in spec.actors) {
      if (tt < a.t0 || tt > a.end) continue;
      final o = _lerp(Offset(a.x0, a.y0), Offset(a.x1, a.y1), _seg(tt, a.t0, a.t1));
      final fadeIn = ((tt - a.t0) / 0.8).clamp(0.0, 1.0).toDouble();
      final fadeOut = ((a.end - tt) / 0.8).clamp(0.0, 1.0).toDouble();
      kids.add(Positioned(left: o.dx, top: o.dy, child: Opacity(opacity: math.min(fadeIn, fadeOut), child: bioIcon(a.icon, size: a.size))));
    }
    final labels = spec.caps[capIdx].labels;
    final showFormula = tt >= spec.formulaAt;
    kids.add(Positioned(
      top: 8,
      left: 10,
      right: 10,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: showFormula ? [tag(spec.formula, big: true)] : [for (final l in labels) tag(l)],
      ),
    ));
    return SizedBox(width: 640, height: 340, child: Stack(children: kids));
  }

  Widget roundBtn(IconData i, VoidCallback onTap, String label) => Pressable(
        onTap: onTap,
        child: Container(
          width: 74,
          height: 46,
          decoration: BoxDecoration(shape: BoxShape.circle, color: cPanel, border: Border.all(color: cBlue, width: 2), boxShadow: [BoxShadow(color: cBlue.withValues(alpha: 0.4), blurRadius: 8)]),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 24), Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stage(
      child: Stack(children: [
        Positioned(left: 0, right: 0, top: 0, child: TopBar(title: spec.exploreTitle)),
        Positioned(
          left: 20,
          top: 70,
          width: 640,
          height: 340,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0A2A5E), Color(0xFF071A3D)]),
                border: Border.all(color: cBlue, width: 3),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(children: [
                AnimatedBuilder(animation: ctl, builder: (_, __) => scene(t)),
                if (cc)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 10,
                    child: AnimatedBuilder(
                      animation: ctl,
                      builder: (_, __) => Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
                        child: Text(spec.caps[capIdx].text, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.25)),
                      ),
                    ),
                  ),
                if (!playing && !ended && ctl.value == 0)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: GlowButton(label: 'Play video', icon: Icons.play_arrow_rounded, width: 240, height: 64, font: 24, onTap: play),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        Positioned(
          left: 20,
          top: 420,
          width: 640,
          height: 50,
          child: Row(children: [
            roundBtn(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, playing ? pause : (ended ? replay : play), playing ? 'Pause' : 'Play'),
            const SizedBox(width: 8),
            roundBtn(Icons.replay_rounded, replay, 'Replay'),
            const SizedBox(width: 8),
            Container(
              width: 170,
              height: 46,
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(color: cPanel, borderRadius: BorderRadius.circular(23), border: Border.all(color: cBlue, width: 2)),
              child: Row(children: [
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded, size: 22), const Text('Volume', style: TextStyle(fontSize: 10))]),
                Expanded(
                  child: Slider(
                    value: volume,
                    activeColor: cGreen,
                    onChanged: (v) {
                      setState(() => volume = v);
                      Voice.volume = v;
                      music.setVolume(v);
                      if (v == 0) Voice.stop();
                    },
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Pressable(
              onTap: () => setState(() => cc = !cc),
              child: Container(
                width: 84,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: cc ? cBlue : cPanel, borderRadius: BorderRadius.circular(14), border: Border.all(color: cBlue, width: 2)),
                child: Text(cc ? 'Captions on' : 'Captions off', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedBuilder(
                animation: ctl,
                builder: (_, __) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: ctl.value, minHeight: 10, color: cGreen, backgroundColor: Colors.white24)),
                  const SizedBox(height: 2),
                  Text('${fmt(t)} / 2:00  (${fmt(total - t)} left)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ]),
        ),
        // check-for-understanding prompt (appears after the video)
        Positioned(
          left: 680,
          top: 70,
          width: 260,
          height: 340,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: panelDeco(border: ended ? cGreen : cBlue),
            child: !ended
                ? const Center(child: Text('A quick question will appear after the video.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.white70)))
                : Column(children: [
                    Row(children: [
                      const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFD54F), size: 34),
                      const SizedBox(width: 8),
                      Expanded(child: Text(spec.quiz, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, height: 1.2))),
                    ]),
                    const SizedBox(height: 12),
                    if (widget.session == 4) ...[
                      for (var i = 0; i < 4; i++) Padding(padding: const EdgeInsets.only(bottom: 5), child: GlowButton(
                        label: const ['ATP and water', 'CO₂ and NADH', 'Glucose and oxygen', 'Pyruvate and ATP'][i], width: 228, height: 34, font: 14,
                        color: quickChoice == i ? (i == 1 ? cGreen : Colors.redAccent) : cBlue,
                        onTap: () => setState(() {quickChoice = i; revealed = i == 1;}),
                      )),
                      if (quickChoice != null) Text(quickChoice == 1 ? 'Correct! CO₂ and NADH.' : 'Look at what leaves the matrix and what is passed to NAD⁺.', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ] else Pressable(
                      onTap: () => setState(() => revealed = true),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: cBlue.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(16), border: Border.all(color: cBlue, width: 2)),
                        child: const Column(children: [
                          Icon(Icons.touch_app, size: 30),
                          SizedBox(height: 4),
                          Text('Tap to reveal answer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (revealed && widget.session != 4)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: cGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: cGreen, width: 2)),
                        child: Column(children: [
                          SizedBox(height: 40, child: FittedBox(child: Row(mainAxisSize: MainAxisSize.min, children: [for (final k in spec.quizIcons) Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: bioIcon(k, size: 38))]))),
                          const SizedBox(height: 6),
                          Text(spec.quizAnswer, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                        ]),
                      ),
                  ]),
          ),
        ),
        if (ended)
          Positioned(
            left: 0,
            right: 0,
            top: 478,
            child: Center(
              child: GlowButton(
                label: 'Continue to Simulate',
                icon: Icons.play_arrow_rounded,
                width: 340,
                onTap: () {
                  Voice.stop();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GenSimScreen(session: widget.session)));
                },
              ),
            ),
          ),
        if (kTestMode && !ended)
          Positioned(
            right: 20,
            bottom: 14,
            child: TextButton(
              onPressed: () {
                ctl.value = 1;
              },
              child: const Text('Skip video (test)'),
            ),
          ),
      ]),
    );
  }
}
