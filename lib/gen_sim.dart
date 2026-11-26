import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'art.dart';
import 'common.dart';
import 'gmodels.dart';
import 'gsessions.dart';
import 'gen_ui.dart';
import 'play.dart';
import 'revised_map.dart';

// =====================================================================
// STEP 3: SIMULATE (generic engine, one SimDef per session)
// Drag an item onto its place, or tap the item and then tap the place.
// No score and no timer. Reset / Try again any time.
// =====================================================================
class GenSimScreen extends StatefulWidget {
  final int session;
  const GenSimScreen({super.key, required this.session});
  @override
  State<GenSimScreen> createState() => _GenSimState();
}

class _GenSimState extends State<GenSimScreen> with TickerProviderStateMixin {
  late final SessionSpec spec = specFor(widget.session)!;
  SimDef get def => spec.sim;

  int? vi;
  int step = 0;
  Map<String, int> counts = {};
  final List<Map<String, int>> snaps = [];
  final List<List<String>> placedBy = [];
  late String msg = def.start;
  int msgKind = 0; // 0 info, 1 success, 2 error
  bool busy = false;
  String? sel;
  List<String> pops = [];
  int runId = 0, fxKind = 0;
  final Set<int> doneVariants = {};

  late final AnimationController fx = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final AnimationController popC = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  late final AnimationController spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    if (def.variants.length == 1) vi = 0;
  }

  @override
  void dispose() {
    fx.dispose();
    popC.dispose();
    spin.dispose();
    super.dispose();
  }

  SimVariant get variant => def.variants[vi!];
  bool get finished => vi != null && step >= variant.steps.length && !busy;

  SimItem itemById(String id) => def.tray.firstWhere((i) => i.id == id);
  String zoneLabel(String id) => def.zones.firstWhere((z) => z.id == id).label;

  String nextHint() {
    final s = variant.steps[step];
    return 'Next, drag ${itemById(s.item).label} to the ${zoneLabel(s.zone)}.';
  }

  String get startMsg {
    if (vi == null) return def.start;
    if (def.variants.length == 1) return def.start;
    final s = variant.steps[0];
    return 'Drag ${itemById(s.item).label} to the ${zoneLabel(s.zone)}.';
  }

  void play(int kind) {
    fxKind = kind;
    fx.forward(from: 0);
  }

  void say(String m, int kind) {
    msg = m;
    msgKind = kind;
  }

  void apply(Map<String, int> d) {
    d.forEach((k, v) {
      var n = (counts[k] ?? 0) + v;
      if (k != 'net' && n < 0) n = 0;
      counts[k] = n;
    });
  }

  void pop(String list) {
    if (list.isEmpty) return;
    pops = list.split(',');
    popC.forward(from: 0);
  }

  void place(String id, String zone) {
    if (busy) return;
    if (vi == null) {
      setState(() => say(def.chooser.isEmpty ? def.start : def.chooser, 2));
      return;
    }
    final it = itemById(id);
    if (it.distractor || (spec.no >= 7 && vi! > 0 && id == 'oxygen')) {
      play(2);
      setState(() {
        say(spec.no == 4 && id == 'atp' ? 'This step makes no ATP. Try again!' : (spec.no == 4 && id == 'oxygen' ? 'Oxygen is not an input to this step. Try again!' : def.wrong), 2);
        sel = null;
      });
      return;
    }
    final v = variant;
    if (step >= v.steps.length) return;
    final s = v.steps[step];
    final used = placedBy.any((p) => p[0] == id);
    if (!it.reusable && used) {
      play(2);
      setState(() {
        say('${it.label} is already in. ${nextHint()}', 2);
        sel = null;
      });
      return;
    }
    if (id != s.item) {
      play(2);
      setState(() {
        say('Not yet! ${nextHint()}', 2);
        sel = null;
      });
      return;
    }
    if (zone != s.zone) {
      play(2);
      setState(() {
        say('Try placing ${it.label} on the ${zoneLabel(s.zone)}.', 2);
        sel = null;
      });
      return;
    }
    snaps.add(Map<String, int>.from(counts));
    placedBy.add([id, zone]);
    play(1);
    setState(() {
      apply(s.fx);
      step++;
      sel = null;
      say(s.msg, 0);
    });
    pop(s.pop);
    if (step >= v.steps.length) startPay();
  }

  void startPay() {
    final v = variant;
    final run = ++runId;
    busy = true;
    spin.repeat();
    var delay = 1000;
    for (final p in v.pay) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (!mounted || run != runId) return;
        setState(() {
          apply(p.fx);
          say(p.msg, 0);
        });
        pop(p.pop);
      });
      delay += 1800;
    }
    Future.delayed(Duration(milliseconds: delay), () {
      if (!mounted || run != runId) return;
      spin.stop();
      doneVariants.add(vi!);
      if (allRequiredDone) Store.mark('sim');
      setState(() {
        busy = false;
        say(v.success, 1);
      });
      pop('atp,atp');
    });
  }

  bool get allRequiredDone => def.completedBy(doneVariants);

  bool get canChallenge => def.challengeLabel.isNotEmpty && vi != null && (spec.no < 7 || vi! > 0) && step > def.challengeStep;

  void challenge() {
    runId++;
    spin.stop();
    final k = def.challengeStep;
    setState(() {
      counts = Map<String, int>.from(snaps[k]);
      snaps.removeRange(k, snaps.length);
      placedBy.removeRange(k, placedBy.length);
      step = k;
      busy = false;
      pops = [];
      say(def.challengeMsg, 2);
    });
  }

  void restart() {
    runId++;
    spin.stop();
    setState(() {
      counts = {};
      snaps.clear();
      placedBy.clear();
      step = 0;
      busy = false;
      sel = null;
      pops = [];
      say(startMsg, 0);
    });
  }

  void choose(int i) {
    vi = i;
    doneVariants.remove(-1);
    restart();
  }

  // ---------------------------------------------------------------- UI
  Widget trayTile(SimItem it) {
    final used = !it.reusable && placedBy.any((p) => p[0] == it.id);
    final chosen = sel == it.id;
    Widget tile(double op) => Opacity(
          opacity: op,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: chosen ? cBlue.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: chosen ? Colors.yellowAccent : (used ? Colors.white24 : cBlue), width: chosen ? 3 : 2),
              boxShadow: used || chosen ? null : [BoxShadow(color: cBlue.withValues(alpha: 0.4), blurRadius: 8)],
            ),
            child: Row(children: [
              SizedBox(width: 38, height: 34, child: FittedBox(child: bioIcon(it.icon, size: 40))),
              const SizedBox(width: 6),
              Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(it.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)))),
              if (used) const Icon(Icons.check_circle_rounded, size: 18, color: cGreen),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Draggable<String>(
        data: it.id,
        maxSimultaneousDrags: (busy || used) ? 0 : 1,
        feedback: Material(color: Colors.transparent, child: bioIcon(it.icon, size: 54)),
        childWhenDragging: tile(0.3),
        child: GestureDetector(onTap: used || busy ? null : () => setState(() => sel = chosen ? null : it.id), child: tile(used ? 0.45 : 1)),
      ),
    );
  }

  Widget zoneBox(SimZone z, double w, double h) {
    final here = placedBy.where((p) => p[1] == z.id).map((p) => p[0]).toList();
    final isWheel = z.id == 'wheel';
    return Positioned(
      left: z.x * w,
      top: z.y * h,
      width: z.w * w,
      height: z.h * h,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (_) => !busy,
        onAcceptWithDetails: (d) => place(d.data, z.id),
        builder: (_, cand, __) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: sel == null ? null : () => place(sel!, z.id),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: cand.isNotEmpty ? 0.22 : 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cand.isNotEmpty || sel != null ? Colors.yellowAccent : Colors.white54, width: 2),
            ),
            child: Stack(children: [
              if (isWheel) Center(child: Opacity(opacity: 0.55, child: AnimatedBuilder(animation: spin, builder: (_, __) => Transform.rotate(angle: spin.value * 2 * math.pi, child: Text('🎡', style: TextStyle(fontSize: math.min(z.w * w, z.h * h) * 0.7)))))),
              Column(children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(z.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white70))),
                Expanded(child: Center(child: Wrap(spacing: 2, runSpacing: 2, alignment: WrapAlignment.center, children: [for (final id in here) bioIcon(itemById(id).icon, size: here.length > 3 ? 24 : 32)]))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget stageBackdrop(double w, double h) {
    final glow = busy || finished;
    switch (def.bg) {
      case 'mito':
        return Positioned.fill(child: Center(child: MitoArt(width: 480, glow: glow)));
      case 'chain':
        final n = ((counts['hplus'] ?? 0) / 100 * 8).round();
        return Positioned.fill(
          child: Stack(children: [
            Positioned(left: 0, right: 0, top: h * 0.42, height: h * 0.2, child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFB74D), Color(0xFFF57C00)])))),
            const Positioned(left: 10, top: 6, child: Text('H⁺ space (above the membrane)', style: TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w700))),
            const Positioned(left: 10, bottom: 8, child: Text('Matrix (below the membrane)', style: TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w700))),
            Positioned(left: 20, right: 20, top: 26, child: Wrap(spacing: 6, runSpacing: 4, children: [for (var i = 0; i < n; i++) bioIcon('proton', size: 26)])),
          ]),
        );
      default:
        return Positioned.fill(
          child: Stack(alignment: Alignment.center, children: [
            Center(child: CellArt(width: w - 30, height: h - 24)),
            Positioned(right: 16, bottom: 14, child: spec.no >= 7 && vi != null && vi! > 0 ? bioIcon('mitoclosed', size: 56) : MitoArt(width: 100, glow: glow)),
          ]),
        );
    }
  }

  Widget stagePanel() {
    const w = 500.0, h = 350.0;
    return Container(
      width: w,
      height: h,
      decoration: panelDeco(border: finished ? cGreen : cBlue),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedBuilder(
          animation: fx,
          builder: (_, child) {
            final k = 1 - fx.value;
            final dx = fxKind == 2 ? math.sin(fx.value * math.pi * 6) * 8 * k : 0.0;
            final rot = fxKind == 1 ? math.sin(fx.value * math.pi * 4) * 0.03 * k : 0.0;
            return Transform.translate(offset: Offset(dx, 0), child: Transform.rotate(angle: rot, child: child));
          },
          child: Stack(children: [
            stageBackdrop(w, h),
            for (final z in def.zones) zoneBox(z, w, h),
            if (def.variants.length > 1)
              Positioned(
                top: 6,
                left: 0,
                right: 0,
                child: Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 4, children: [
                  for (var i = 0; i < def.variants.length; i++) ...[
                    Pressable(
                      onTap: busy ? null : () => choose(i),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: vi == i ? cBlue : cPanel,
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(color: vi == null ? Colors.yellowAccent : Colors.white70, width: 2),
                        ),
                        child: Row(children: [
                          SizedBox(width: 26, height: 26, child: FittedBox(child: bioIcon(def.variants[i].icon, size: 30))),
                          const SizedBox(width: 6),
                          Text(spec.no >= 7 ? (i == 0 ? 'With O₂' : (i == 1 ? 'No O₂: Muscle' : 'No O₂: Yeast')) : def.variants[i].name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                          if (doneVariants.contains(i)) const Icon(Icons.check_circle_rounded, size: 18, color: cGreen),
                        ]),
                      ),
                    ),
                    if (i < def.variants.length - 1) const SizedBox(width: 0),
                  ],
                ]),
              ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: popC,
                builder: (_, __) {
                  if (pops.isEmpty || popC.value == 0) return const SizedBox();
                  final v = popC.value;
                  return Stack(children: [
                    for (var i = 0; i < pops.length; i++)
                      Positioned(
                        left: w * 0.12 + (i % 7) * (w * 0.76 / 7),
                        top: h * 0.6 - v * h * 0.4 - (i ~/ 7) * 34,
                        child: Opacity(opacity: (1 - v).clamp(0.0, 1.0).toDouble(), child: bioIcon(pops[i], size: 34)),
                      ),
                  ]);
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget counterRow(SimCounter c) {
    final v = counts[c.id] ?? 0;
    final icon = SizedBox(width: 36, height: 36, child: FittedBox(child: c.kind == 'bar' && c.icon == 'atp' ? BatteryIcon(width: 26, height: 40, level: (v / c.max).clamp(0.0, 1.0).toDouble()) : bioIcon(c.icon, size: 40)));
    Widget body;
    if (c.kind == 'bar') {
      final frac = (v / c.max).clamp(0.0, 1.0).toDouble();
      final full = frac >= 1 && c.doneText.isNotEmpty;
      body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(full ? c.doneText : c.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: full ? cGreen : Colors.white)),
        const SizedBox(height: 3),
        ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: frac, minHeight: 9, color: cGreen, backgroundColor: Colors.white24)),
      ]);
    } else if (c.kind == 'flag') {
      body = Row(children: [
        Expanded(child: Text(c.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
        Icon(v > 0 ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 22, color: v > 0 ? cGreen : Colors.white38),
      ]);
    } else {
      final txt = c.id == 'net' && v > 0 ? '+$v' : '$v';
      body = Row(children: [
        Expanded(child: Text(c.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
        Text(txt, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFFFD54F))),
      ]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(opacity: c.kind == 'flag' && v == 0 ? 0.6 : 1, child: Row(children: [icon, const SizedBox(width: 8), Expanded(child: body)])),
    );
  }

  Widget messageBar() {
    final ok = msgKind == 1, bad = msgKind == 2;
    final col = ok ? cGreen : (bad ? Colors.redAccent : cBlue);
    return Container(
      width: 726,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: (ok ? const Color(0xFF14532D) : (bad ? const Color(0xFF7F1D1D) : cPanel)).withValues(alpha: 0.95), borderRadius: BorderRadius.circular(14), border: Border.all(color: col, width: 2)),
      child: Row(children: [
        Icon(ok ? Icons.check_circle_rounded : (bad ? Icons.cancel_rounded : Icons.lightbulb_rounded), color: col, size: 24),
        const SizedBox(width: 8),
        Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: SizedBox(width: 660, child: Text(msg, maxLines: 2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.15))))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session == 2) return const RevisedMapScreen();
    final tray = def.tray.where((i) => step >= i.showAfter).toList();
    return Stage(
      child: Stack(children: [
        Positioned(left: 0, right: 0, top: 0, child: TopBar(title: 'SIMULATE: ${def.title}')),
        Positioned(left: 0, right: 0, top: 62, child: Center(child: Text(def.instruction, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFFB3E5FC))))),
        // item tray
        Positioned(
          left: 16,
          top: 96,
          width: 190,
          height: 350,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: panelDeco(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Item tray', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: cGreen)),
              const Text('Drag, or tap then tap the place', style: TextStyle(fontSize: 10, color: Colors.white60)),
              const SizedBox(height: 4),
              Expanded(child: SingleChildScrollView(child: Column(children: [for (final it in tray) trayTile(it)]))),
            ]),
          ),
        ),
        Positioned(left: 214, top: 96, child: stagePanel()),
        // output panel
        Positioned(
          left: 722,
          top: 96,
          width: 222,
          height: 350,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: panelDeco(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('What your cell makes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: cGreen)),
              const SizedBox(height: 8),
              if (spec.no >= 7 && vi != null) Padding(padding: const EdgeInsets.only(bottom: 5), child: Text(vi == 0 && step >= 5 ? 'Oxidative • about 30–32 ATP in all' : 'Substrate-level phosphorylation', style: const TextStyle(color: cGreen, fontSize: 12, fontWeight: FontWeight.bold))),
              if (vi == null)
                const Text('Choose a cell to begin.', style: TextStyle(fontSize: 14, color: Colors.white70))
              else
                Expanded(child: SingleChildScrollView(child: Column(children: [for (final c in variant.counters) counterRow(c)]))),
            ]),
          ),
        ),
        Positioned(left: 214, top: 452, child: messageBar()),
        Positioned(
          left: 16,
          right: 16,
          top: 496,
          height: 40,
          child: Row(children: [
            GlowButton(label: 'Reset', icon: Icons.restart_alt_rounded, color: cBlue, width: 130, height: 40, font: 16, onTap: restart),
            const SizedBox(width: 8),
            GlowButton(label: 'Try again', icon: Icons.refresh_rounded, color: cBlue, width: 140, height: 40, font: 16, onTap: restart),
            const SizedBox(width: 8),
            if (def.challengeLabel.isNotEmpty) GlowButton(label: 'Challenge: ${def.challengeLabel}', icon: Icons.flag_rounded, color: const Color(0xFF9B59B6), width: 290, height: 40, font: 15, onTap: canChallenge ? challenge : null),
            const Spacer(),
            GlowButton(
              label: 'Continue to Play',
              icon: Icons.play_arrow_rounded,
              color: cOrange,
              width: 250,
              height: 40,
              font: 17,
              locked: !Store.isDone('sim'),
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PlayStartScreen())),
            ),
          ]),
        ),
        if (kTestMode)
          Positioned(right: 20, top: 66, child: TextButton(onPressed: () => setState(() => Store.mark('sim')), child: const Text('Skip (test)'))),
      ]),
    );
  }
}
