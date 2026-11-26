import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'common.dart';

// Biology visual language from the client's spec:
// Glucose = orange hexagon, Oxygen = blue O2 bubble, CO2 = gray bubble,
// ATP = green battery/lightning, Mitochondria = bean with folded membrane.

class Bubble extends StatelessWidget {
  final String text;
  final Color color;
  final double size;
  const Bubble({super.key, required this.text, required this.color, this.size = 40});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(center: const Alignment(-0.3, -0.4), colors: [Color.lerp(color, Colors.white, 0.55)!, color]),
          border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: size * 0.04),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: size * 0.25)],
        ),
        child: Text(text, style: TextStyle(fontSize: size * 0.34, fontWeight: FontWeight.w900, color: Colors.white)),
      );
}

class HexIcon extends StatelessWidget {
  final double size;
  const HexIcon({super.key, this.size = 40});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: _HexPainter()));
}

class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    final r = s.shortestSide / 2 * 0.92;
    Path hex(double rad) {
      final p = Path();
      for (var i = 0; i < 6; i++) {
        final a = -math.pi / 2 + i * math.pi / 3;
        final pt = Offset(o.dx + rad * math.cos(a), o.dy + rad * math.sin(a));
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      return p..close();
    }

    c.drawPath(hex(r), Paint()..color = const Color(0xFFFF9800).withValues(alpha: 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    c.drawPath(hex(r), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFCC80), Color(0xFFF57C00)]).createShader(Offset.zero & s));
    for (final i in [1, 3, 5]) {
      final a = -math.pi / 2 + i * math.pi / 3;
      c.drawLine(o, Offset(o.dx + r * math.cos(a), o.dy + r * math.sin(a)), Paint()..color = const Color(0xFFBF6A00).withValues(alpha: 0.5)..strokeWidth = s.width * 0.03);
    }
    c.drawPath(hex(r), Paint()..style = PaintingStyle.stroke..strokeWidth = s.width * 0.05..strokeJoin = StrokeJoin.round..color = const Color(0xFFFFE0B2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class BatteryIcon extends StatelessWidget {
  final double width, height, level;
  final bool bolt;
  const BatteryIcon({super.key, this.width = 40, this.height = 64, this.level = 1, this.bolt = true});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(size: Size(width, height), painter: _BatteryPainter(level)),
          if (bolt) Icon(Icons.bolt, size: width * 0.55, color: Colors.white, shadows: const [Shadow(color: Colors.black45, blurRadius: 4)]),
        ]),
      );
}

class _BatteryPainter extends CustomPainter {
  final double level;
  _BatteryPainter(this.level);
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.3, 0, w * 0.4, h * 0.08), const Radius.circular(4)), Paint()..color = const Color(0xFF7CF59B));
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.05, h * 0.07, w * 0.9, h * 0.92), Radius.circular(w * 0.16));
    c.drawRRect(body, Paint()..color = const Color(0xFF0B2E1B));
    final inner = body.deflate(w * 0.1).outerRect;
    final fillH = inner.height * level.clamp(0.0, 1.0);
    if (fillH > 0) {
      final fill = Rect.fromLTWH(inner.left, inner.bottom - fillH, inner.width, fillH);
      c.drawRRect(RRect.fromRectAndRadius(fill, Radius.circular(w * 0.08)),
          Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB2FF59), Color(0xFF2ECC71)]).createShader(fill));
    }
    for (var i = 1; i < 5; i++) {
      final y = inner.top + inner.height * i / 5;
      c.drawLine(Offset(inner.left, y), Offset(inner.right, y), Paint()..color = const Color(0xFF0B2E1B)..strokeWidth = 2.5);
    }
    c.drawRRect(body, Paint()..style = PaintingStyle.stroke..strokeWidth = 3.5..color = const Color(0xFF7CF59B));
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter old) => old.level != level;
}

class MitoArt extends StatelessWidget {
  final double width;
  final bool glow, face;
  const MitoArt({super.key, this.width = 120, this.glow = false, this.face = false});
  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: width * 0.55, child: CustomPaint(painter: _MitoPainter(glow, face)));
}

class _MitoPainter extends CustomPainter {
  final bool glow, face;
  _MitoPainter(this.glow, this.face);
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final rect = Rect.fromLTWH(w * 0.04, h * 0.08, w * 0.92, h * 0.84);
    final body = RRect.fromRectAndRadius(rect, Radius.circular(h * 0.42));
    if (glow) c.drawRRect(body.inflate(4), Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.75)..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.2));
    c.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFB74D), Color(0xFFF57C00)]).createShader(rect));
    c.drawRRect(body, Paint()..style = PaintingStyle.stroke..strokeWidth = h * 0.06..color = const Color(0xFFE65100));
    final inner = Rect.fromLTWH(w * 0.14, h * 0.24, w * 0.72, h * 0.52);
    final p = Path()..moveTo(inner.left, inner.center.dy);
    const n = 6;
    for (var i = 0; i < n; i++) {
      final x0 = inner.left + inner.width * i / n, x1 = inner.left + inner.width * (i + 1) / n;
      final y = i.isEven ? inner.top : inner.bottom;
      p.cubicTo(x0 + (x1 - x0) * 0.2, y, x0 + (x1 - x0) * 0.8, y, x1, inner.center.dy);
    }
    c.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = h * 0.08..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = const Color(0xFF2D9CFF));
    if (face) {
      for (final fx in [0.4, 0.6]) {
        c.drawCircle(Offset(w * fx, h * 0.44), h * 0.065, Paint()..color = const Color(0xFF3E2723));
        c.drawCircle(Offset(w * fx - 2, h * 0.42), h * 0.022, Paint()..color = Colors.white);
      }
      c.drawArc(Rect.fromCenter(center: Offset(w * 0.5, h * 0.56), width: w * 0.12, height: h * 0.14), 0.2, math.pi - 0.4, false,
          Paint()..style = PaintingStyle.stroke..strokeWidth = h * 0.035..strokeCap = StrokeCap.round..color = const Color(0xFF3E2723));
    }
  }

  @override
  bool shouldRepaint(covariant _MitoPainter old) => old.glow != glow || old.face != face;
}

class CellArt extends StatelessWidget {
  final double width, height;
  final bool face;
  final Widget? inside;
  const CellArt({super.key, this.width = 300, this.height = 200, this.face = false, this.inside});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: Stack(alignment: Alignment.center, children: [
          CustomPaint(size: Size(width, height), painter: _CellPainter()),
          if (face) Align(alignment: const Alignment(0, -0.72), child: _CellFace(size: width * 0.12)),
          if (inside != null) inside!,
        ]),
      );
}

class _CellFace extends StatelessWidget {
  final double size;
  const _CellFace({required this.size});
  Widget eye() => Container(
        width: size,
        height: size * 1.1,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: Container(width: size * 0.5, height: size * 0.55, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0D2B3E))),
      );
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [eye(), SizedBox(width: size * 0.5), eye()]),
        SizedBox(height: size * 0.2),
        Container(
          width: size * 0.9,
          height: size * 0.4,
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: const Color(0xFF0D2B3E), width: size * 0.12)), borderRadius: BorderRadius.vertical(bottom: Radius.circular(size))),
        ),
      ]);
}

class _CellPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromLTWH(6, 6, s.width - 12, s.height - 12);
    c.drawOval(r.inflate(6), Paint()..color = cBlue.withValues(alpha: 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    c.drawOval(r, Paint()..shader = const RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFF7FC4FF), Color(0xFF3B6FD8), Color(0xFF2A3FA0)]).createShader(r));
    c.drawOval(r, Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = Colors.white.withValues(alpha: 0.55));
    for (final o in const [(0.2, 0.3, 0.12, 0.07, 0.5), (0.8, 0.64, 0.13, 0.08, -0.4), (0.3, 0.8, 0.1, 0.06, 0.2), (0.82, 0.25, 0.09, 0.06, 0.9)]) {
      c.save();
      c.translate(s.width * o.$1, s.height * o.$2);
      c.rotate(o.$5);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: s.width * o.$3 * 2, height: s.height * o.$4 * 2), Paint()..color = const Color(0xFF9B59B6).withValues(alpha: 0.7));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Icon on the front of each term card (same order as the spec's table).
class TermIcon extends StatelessWidget {
  final int i;
  final double size;
  const TermIcon({super.key, required this.i, this.size = 110});

  Widget arrow() => const Icon(Icons.arrow_forward_rounded, size: 26, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    switch (i) {
      case 0:
        return SizedBox(
          width: size * 1.7,
          height: size * 0.7,
          child: FittedBox(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const CellArt(width: 56, height: 44),
              const SizedBox(width: 4),
              const HexIcon(size: 34),
              const SizedBox(width: 4),
              const Bubble(text: 'O₂', color: cBlue, size: 34),
              const SizedBox(width: 4),
              arrow(),
              const SizedBox(width: 4),
              const BatteryIcon(width: 30, height: 46),
            ]),
          ),
        );
      case 1:
        return BatteryIcon(width: size * 0.62, height: size);
      case 2:
        return HexIcon(size: size);
      case 3:
        return Bubble(text: 'O₂', color: cBlue, size: size);
      case 4:
        return Bubble(text: 'CO₂', color: cGray, size: size);
      case 5:
        return MitoArt(width: size * 1.5, glow: true);
      case 6:
        return SizedBox(
          width: size * 1.7,
          height: size * 0.7,
          child: FittedBox(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Bubble(text: 'O₂', color: cBlue, size: 38),
              arrow(),
              const MitoArt(width: 80, glow: true),
              arrow(),
              const BatteryIcon(width: 30, height: 46),
            ]),
          ),
        );
      default:
        return SizedBox(
          width: size * 1.7,
          height: size * 0.7,
          child: FittedBox(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const MitoArt(width: 90),
              const SizedBox(width: 8),
              Stack(alignment: Alignment.center, children: const [
                Bubble(text: 'O₂', color: cBlue, size: 44),
                Icon(Icons.block, size: 56, color: Color(0xFFE53935)),
              ]),
            ]),
          ),
        );
    }
  }
}
