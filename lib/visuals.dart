import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---------- Dark lab background with floating glowing organelles ----------
class LabBackground extends StatefulWidget {
  final Widget child;
  final bool blobs;
  const LabBackground({super.key, required this.child, this.blobs = false});
  @override
  State<LabBackground> createState() => _LabBackgroundState();
}

class _LabBackgroundState extends State<LabBackground> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Widget blob(Alignment a, double w, double h, Color color, double angle, double phase) => AnimatedBuilder(
        animation: c,
        builder: (_, child) => Align(
          alignment: a,
          child: Transform.translate(offset: Offset(0, math.sin((c.value + phase) * 2 * math.pi) * 8), child: child),
        ),
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(h),
              gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.5)]),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 26, spreadRadius: 2)],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF071A3A), Color(0xFF0B2A5B), Color(0xFF061B38)]),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment(0, -0.1), radius: 0.8, colors: [Color(0x4429B6F6), Color(0x0029B6F6)]),
          ),
        ),
        if (widget.blobs) ...[
          blob(const Alignment(-0.9, -0.8), 96, 52, const Color(0xFF2196F3), 0.7, 0.0),
          blob(const Alignment(-1.1, -0.45), 52, 84, const Color(0xFF7E57C2), -0.3, 0.3),
          blob(const Alignment(1.05, -0.7), 124, 70, const Color(0xFF43D854), -0.6, 0.6),
          blob(const Alignment(-1.1, 0.55), 112, 60, const Color(0xFF43D854), 0.9, 0.15),
          blob(const Alignment(1.05, 0.5), 124, 70, const Color(0xFF29B6F6), 0.0, 0.8),
        ],
        widget.child,
      ]);
}

// ---------- BIOBLAST wordmark (green "Bio" + orange "BLAST" + leaf) ----------
class BioWordmark extends StatelessWidget {
  final double size;
  const BioWordmark({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.2
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF0B4F6C);
    TextStyle base({Paint? fg, Color? color}) => TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          height: 1,
          letterSpacing: -1,
          foreground: fg,
          color: fg == null ? color : null,
          shadows: fg == null ? null : [Shadow(color: Colors.black54, offset: Offset(0, size * 0.1), blurRadius: 6)],
        );
    return Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
      Padding(
        padding: EdgeInsets.only(top: size * 0.45),
        child: Stack(alignment: Alignment.center, children: [
          Text.rich(TextSpan(children: [TextSpan(text: 'Bio', style: base(fg: outline)), TextSpan(text: 'BLAST', style: base(fg: outline))])),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'Bio', style: base(color: const Color(0xFF6BE03A))),
            TextSpan(text: 'BLAST', style: base(color: const Color(0xFFFF9A1F))),
          ])),
        ]),
      ),
      Align(
        alignment: const Alignment(-0.28, -1),
        child: Transform.rotate(
          angle: 0.35,
          child: Icon(Icons.eco, size: size * 0.85, color: const Color(0xFF7CE04A), shadows: const [Shadow(color: Colors.lightGreenAccent, blurRadius: 14)]),
        ),
      ),
    ]);
  }
}

class Tagline extends StatelessWidget {
  const Tagline({super.key});
  @override
  Widget build(BuildContext context) => const Text('Explore  •  Learn  •  Play',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFB3E5FC), shadows: [Shadow(color: Colors.black87, blurRadius: 6)]));
}

// ---------- Splash / loading screen (mockup screen 1) ----------
class LoadingView extends StatelessWidget {
  final int pct;
  const LoadingView({super.key, required this.pct});

  @override
  Widget build(BuildContext context) => LabBackground(
        blobs: true,
        child: SafeArea(
          child: Column(children: [
            const Spacer(flex: 5),
            const BioWordmark(size: 62),
            const SizedBox(height: 8),
            const Tagline(),
            const Spacer(flex: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                height: 28,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A2147),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF8FD3FF), width: 2),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (pct.clamp(0, 100)) / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(colors: [Color(0xFF8BE04A), Color(0xFF43D854)]),
                        boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.6), blurRadius: 10)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('LOADING...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFF4DD0E1))),
            const SizedBox(height: 56),
          ]),
        ),
      );
}

// ---------- Glowing plant on a platform (mockup screen 2) ----------
class GlowPlant extends StatelessWidget {
  const GlowPlant({super.key});
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(300, 280), painter: _PlantPainter());
}

class _PlantPainter extends CustomPainter {
  void _leaf(Canvas c, Offset base, double angle, double len, double w) {
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(angle);
    final p = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * 0.45, -w, len, 0)
      ..quadraticBezierTo(len * 0.45, w, 0, 0);
    c.drawPath(p, Paint()..color = const Color(0xFF69F0AE).withValues(alpha: 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    c.drawPath(p, Paint()..shader = const LinearGradient(colors: [Color(0xFF1B8E3A), Color(0xFF8BE04A)]).createShader(Rect.fromLTWH(0, -w, len, 2 * w)));
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFD9FFB0);
    c.drawPath(p, line);
    c.drawLine(Offset.zero, Offset(len * 0.88, 0), line);
    c.restore();
  }

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final py = s.height * 0.84;
    final halo = Offset(cx, s.height * 0.42);
    c.drawCircle(
        halo,
        s.width * 0.4,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0x6600E676), Color(0x0000E676)]).createShader(Rect.fromCircle(center: halo, radius: s.width * 0.4)));
    void ell(double w, double h, double dy, Paint p) => c.drawOval(Rect.fromCenter(center: Offset(cx, py + dy), width: w, height: h), p);
    ell(s.width * 0.95, 52, 10, Paint()..color = const Color(0xFF00B0FF).withValues(alpha: 0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    ell(s.width * 0.84, 44, 12, Paint()..color = const Color(0xFF16417A));
    ell(s.width * 0.84, 44, 4, Paint()..color = const Color(0xFF2A6CB8));
    ell(s.width * 0.7, 32, 0, Paint()..color = const Color(0xFF4FC3F7));
    ell(s.width * 0.58, 22, -1, Paint()..color = const Color(0xFFB9F3FF));
    ell(s.width * 0.4, 12, -2, Paint()..color = Colors.white.withValues(alpha: 0.9));

    final top = Offset(cx, s.height * 0.2);
    final stem = Path()
      ..moveTo(cx, py - 6)
      ..cubicTo(cx - 12, py - 55, cx + 12, py - 100, top.dx, top.dy);
    c.drawPath(stem, Paint()..style = PaintingStyle.stroke..strokeWidth = 13..color = const Color(0xFF69F0AE).withValues(alpha: 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    c.drawPath(stem, Paint()..style = PaintingStyle.stroke..strokeWidth = 7..strokeCap = StrokeCap.round..color = const Color(0xFF3DBE4F));

    _leaf(c, top, -math.pi / 2, 62, 24);
    _leaf(c, Offset(cx - 2, s.height * 0.36), -math.pi + 0.55, 74, 24);
    _leaf(c, Offset(cx + 2, s.height * 0.34), -0.55, 74, 24);
    _leaf(c, Offset(cx - 1, s.height * 0.54), -math.pi + 0.15, 70, 22);
    _leaf(c, Offset(cx + 1, s.height * 0.52), -0.15, 70, 22);

    final sp = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (final o in [Offset(cx - 58, s.height * 0.3), Offset(cx + 62, s.height * 0.42), Offset(cx - 40, s.height * 0.62), Offset(cx + 34, s.height * 0.16)]) {
      c.drawCircle(o, 2.4, sp);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ---------- Illustrated thumbnail for each session (mockup screen 4) ----------
class SessionThumb extends StatelessWidget {
  final int no;
  final bool locked;
  const SessionThumb({super.key, required this.no, this.locked = false});

  // (background top, background bottom, glow color, icon, oval shape?)
  (Color, Color, Color, IconData?, bool) get spec => switch (no) {
        1 => (const Color(0xFF5BD14B), const Color(0xFF1E8E3E), const Color(0xFFB9F6CA), Icons.eco, true),
        2 => (const Color(0xFF2E7D32), const Color(0xFF9E9D24), const Color(0xFF69F0AE), Icons.grain, true),
        3 => (const Color(0xFF1A3C8F), const Color(0xFF5E35B1), const Color(0xFFFF7043), Icons.graphic_eq, true),
        4 => (const Color(0xFF4A2C8F), const Color(0xFF1A237E), const Color(0xFFFFB74D), Icons.bolt, false),
        5 => (const Color(0xFF0D2A66), const Color(0xFF123E8C), const Color(0xFF4FC3F7), Icons.hub, false),
        6 => (const Color(0xFF0D3C8C), const Color(0xFF1565C0), const Color(0xFF81D4FA), Icons.water_drop, false),
        7 => (const Color(0xFF2A2F8F), const Color(0xFF3949AB), const Color(0xFFB39DDB), null, false),
        _ => (const Color(0xFF5BD14B), const Color(0xFF1E8E3E), const Color(0xFFB9F6CA), Icons.eco, true),
      };

  @override
  Widget build(BuildContext context) {
    final (top, bottom, glow, icon, oval) = spec;
    final inner = icon == null
        ? const Text('O₂', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white))
        : Icon(icon, size: oval ? 18 : 24, color: Colors.white);
    final shape = Container(
      width: oval ? 48 : 40,
      height: oval ? 30 : 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: oval ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: oval ? BorderRadius.circular(20) : null,
        gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: [glow, glow.withValues(alpha: 0.55)]),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
        boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.7), blurRadius: 14)],
      ),
      child: inner,
    );
    Widget box = Container(
      width: 76,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [top, bottom]),
        border: Border.all(color: Colors.white54, width: 1.5),
      ),
      child: oval ? Transform.rotate(angle: -0.45, child: shape) : shape,
    );
    if (locked) box = ColorFiltered(colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation), child: box);
    return box;
  }
}

// ---------- Illustrated lesson scene (mockup screen 5) ----------
class _Scene {
  final List<Color> sky;
  final bool sun, oval;
  final String label;
  final Color c1, c2;
  final IconData? icon;
  final List<(String, double, double)> bubbles;
  const _Scene(this.sky, this.sun, this.label, this.c1, this.c2, this.icon, this.oval, this.bubbles);
}

const _skyDay = [Color(0xFF29B6F6), Color(0xFF81D4FA), Color(0xFFB3E5FC)];
const _skyCell = [Color(0xFF3949AB), Color(0xFF5E35B1), Color(0xFF7E57C2)];

_Scene _sceneFor(int no) => switch (no) {
      3 => const _Scene(_skyCell, false, 'Mitochondria', Color(0xFFFFA726), Color(0xFFD84315), Icons.graphic_eq, true,
          [('O₂', -0.92, -0.1), ('Glucose', 0.85, -0.7), ('ATP', 0.9, 0.2)]),
      4 => const _Scene(_skyCell, false, 'Mitochondria', Color(0xFFFFA726), Color(0xFFD84315), Icons.graphic_eq, true,
          [('ATP', -0.9, -0.2), ('ATP', 0.9, -0.65), ('Energy', 0.85, 0.2)]),
      5 => const _Scene(_skyCell, false, 'Glucose', Color(0xFF4FC3F7), Color(0xFF0277BD), Icons.hub, false,
          [('Energy', -0.85, -0.1), ('ATP', 0.9, -0.65), ('O₂', 0.9, 0.2)]),
      6 => const _Scene(_skyDay, true, 'Water & CO₂', Color(0xFF81D4FA), Color(0xFF1565C0), Icons.water_drop, false,
          [('H₂O', -0.9, 0.0), ('CO₂', 0.9, -0.65), ('Glucose', 0.85, 0.2)]),
      7 => const _Scene(_skyCell, false, 'Oxygen', Color(0xFF9FA8DA), Color(0xFF3949AB), Icons.air, false,
          [('O₂', -0.9, 0.0), ('ATP', 0.9, -0.65), ('Cell', 0.9, 0.2)]),
      8 => const _Scene(_skyDay, true, 'The Big Picture', Color(0xFF8BE04A), Color(0xFF1B8E3A), Icons.eco, false,
          [('CO₂', -0.9, 0.0), ('O₂', 0.9, -0.65), ('ATP', 0.9, 0.2)]),
      _ => const _Scene(_skyDay, true, 'Chloroplast', Color(0xFF8BE04A), Color(0xFF1B8E3A), Icons.grain, true,
          [('CO₂', -0.92, 0.0), ('CO₂', 0.9, -0.65), ('O₂', 0.9, 0.15)]),
    };

class LessonScene extends StatelessWidget {
  final int no;
  const LessonScene({super.key, required this.no});

  Widget _organelle(_Scene sc) {
    final body = Container(
      width: sc.oval ? 190 : 120,
      height: sc.oval ? 108 : 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: sc.oval ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: sc.oval ? BorderRadius.circular(60) : null,
        gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: [sc.c1, sc.c2]),
        border: Border.all(color: const Color(0xFFFFF59D), width: 5),
        boxShadow: [BoxShadow(color: sc.c1.withValues(alpha: 0.8), blurRadius: 24)],
      ),
      child: sc.oval
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < 3; i++)
                Container(
                  width: 34,
                  height: 58,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(color: sc.c2.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(18)),
                ),
            ])
          : Icon(sc.icon, size: 60, color: Colors.white),
    );
    return sc.oval ? Transform.rotate(angle: -0.3, child: body) : body;
  }

  @override
  Widget build(BuildContext context) {
    final sc = _sceneFor(no);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sc.sky)),
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 330,
            height: 250,
            child: Stack(children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 46,
                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7CD14B), Color(0xFF2E9E1F)])),
                ),
              ),
              const Positioned(left: 8, bottom: 30, child: Icon(Icons.grass, size: 44, color: Color(0xFF2E9E1F))),
              const Positioned(right: 8, bottom: 30, child: Icon(Icons.grass, size: 44, color: Color(0xFF2E9E1F))),
              if (sc.sun) ...[
                const Positioned(left: 14, top: 8, child: Icon(Icons.wb_sunny, size: 64, color: Color(0xFFFFD54F), shadows: [Shadow(color: Colors.orangeAccent, blurRadius: 24)])),
                const Positioned(left: 84, top: 30, child: Text('Sunlight', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
              ],
              Align(alignment: const Alignment(0, -0.1), child: _organelle(sc)),
              for (final b in sc.bubbles)
                Align(
                  alignment: Alignment(b.$2, b.$3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A3A8F),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
                    ),
                    child: Text(b.$1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              Align(
                alignment: const Alignment(0, 0.88),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7BE04A), Color(0xFF2E9E1F)]),
                    border: Border.all(color: Colors.white54, width: 1.5),
                  ),
                  child: Text(sc.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ---------- Plant inside the glass tube (mockup screen 6) ----------
class SimPlant extends StatelessWidget {
  final double growth;
  final bool healthy;
  const SimPlant({super.key, required this.growth, required this.healthy});
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(200, 270), painter: _SimPlantPainter(growth, healthy));
}

class _SimPlantPainter extends CustomPainter {
  final double g;
  final bool ok;
  _SimPlantPainter(this.g, this.ok);

  void _leaf(Canvas c, Offset base, double angle, double len, double w) {
    if (len < 4) return;
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(angle);
    final p = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * 0.45, -w, len, 0)
      ..quadraticBezierTo(len * 0.45, w, 0, 0);
    final cols = ok ? const [Color(0xFF1B8E3A), Color(0xFF8BE04A)] : const [Color(0xFF827717), Color(0xFFC9B458)];
    c.drawPath(p, Paint()..shader = LinearGradient(colors: cols).createShader(Rect.fromLTWH(0, -w, len, 2 * w)));
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.6);
    c.drawPath(p, line);
    c.drawLine(Offset.zero, Offset(len * 0.85, 0), line);
    c.restore();
  }

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final baseY = s.height * 0.86;
    void ell(double w, double h, double dy, Color col, [double blur = 0]) => c.drawOval(
        Rect.fromCenter(center: Offset(cx, baseY + dy), width: w, height: h),
        Paint()
          ..color = col
          ..maskFilter = blur > 0 ? MaskFilter.blur(BlurStyle.normal, blur) : null);
    ell(196, 46, 16, const Color(0xFF00B0FF).withValues(alpha: 0.4), 10);
    ell(176, 40, 14, const Color(0xFF16417A));
    ell(150, 32, 6, const Color(0xFF2A6CB8));
    ell(124, 30, 0, const Color(0xFF8D5B2E));
    ell(104, 20, -3, const Color(0xFFB07A3F));

    final h = 30 + 150 * g;
    final top = Offset(cx, baseY - 8 - h);
    final stem = Path()
      ..moveTo(cx, baseY - 8)
      ..cubicTo(cx - 8, baseY - 8 - h * 0.35, cx + 8, baseY - 8 - h * 0.7, top.dx, top.dy);
    c.drawPath(stem, Paint()..style = PaintingStyle.stroke..strokeWidth = 6..strokeCap = StrokeCap.round..color = ok ? const Color(0xFF3DBE4F) : const Color(0xFF9E9D24));

    final droop = ok ? 0.0 : 0.9;
    const marks = [(0.25, 0.0), (0.5, 0.25), (0.72, 0.5), (0.92, 0.75)];
    for (final m in marks) {
      final sz = ((g - m.$2) / 0.25).clamp(0.0, 1.0).toDouble();
      final p = Offset(cx, baseY - 8 - h * m.$1);
      _leaf(c, p, -0.5 + droop, 54 * sz, 19 * sz);
      _leaf(c, p, -math.pi + 0.5 - droop, 54 * sz, 19 * sz);
    }
    _leaf(c, top, -math.pi / 2 + (ok ? 0 : 0.8), 42 * ((g - 0.1) / 0.3).clamp(0.0, 1.0).toDouble(), 16);
  }

  @override
  bool shouldRepaint(covariant _SimPlantPainter old) => old.g != g || old.ok != ok;
}
