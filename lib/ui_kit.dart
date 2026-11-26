import 'package:flutter/material.dart';
import 'common.dart';

// =====================================================================
// Shared look for the quiz screens (mockup 8 "Mini Challenge" and
// mockup 9 "Immediate Feedback"). Used by every round in the PLAY step.
// =====================================================================

/// One answer row: A / B / C / D badge + text. Turns green with a check when
/// right, red with a cross when wrong (mockup screen 8).
class ChoiceTile extends StatelessWidget {
  final String letter, text;
  final bool right, wrong, hidden;
  final double height, font;
  final VoidCallback? onTap;
  const ChoiceTile({super.key, required this.letter, required this.text, this.right = false, this.wrong = false, this.hidden = false, this.height = 50, this.font = 17, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color accent = right ? cGreen : (wrong ? Colors.redAccent : cBlue);
    final Color fill = right ? const Color(0xFF14602F) : (wrong ? const Color(0xFF6E1B1B) : const Color(0xFF0A2147));
    return Opacity(
      opacity: hidden ? 0.15 : 1,
      child: Pressable(
        onTap: hidden ? null : onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent, width: 2.5),
            boxShadow: [BoxShadow(color: accent.withValues(alpha: right || wrong ? 0.55 : 0.25), blurRadius: 10)],
          ),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(9), color: accent),
              child: Text(letter, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: font, fontWeight: FontWeight.w800, height: 1.1))),
            if (right) const Icon(Icons.check_circle_rounded, color: cGreen, size: 26),
            if (wrong) const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 26),
          ]),
        ),
      ),
    );
  }
}

/// The "Correct!" / "Not quite" panel under a question (mockup screen 8).
class FeedbackPanel extends StatelessWidget {
  final String? msg;
  final bool ok;
  const FeedbackPanel({super.key, required this.msg, required this.ok});

  @override
  Widget build(BuildContext context) {
    if (msg == null) return const SizedBox(height: 60);
    final Color c = ok ? cGreen : Colors.redAccent;
    return Container(
      height: 60,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: (ok ? const Color(0xFF0F4A28) : const Color(0xFF5C1717)).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c, width: 2.5),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 12)],
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: ok ? const [Color(0xFFFFE082), Color(0xFFFFA000)] : const [Color(0xFFFF8A80), Color(0xFFD32F2F)])),
          child: Icon(ok ? Icons.star_rounded : Icons.close_rounded, size: 24, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ok ? 'Correct!' : 'Not quite!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: c, height: 1.1)),
            Text(msg!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.15)),
          ]),
        ),
      ]),
    );
  }
}

/// "Great Job!" card shown when a round ends (mockup screen 9).
Widget roundFeedbackOverlay({required bool timedOut, required int correct, required int total, required int points, required String buttonLabel, required VoidCallback onContinue}) {
  final perfect = !timedOut && correct == total;
  final good = !timedOut && correct * 2 >= total;
  final title = timedOut ? "Time's up!" : (perfect ? 'Great Job!' : (good ? 'Good Work!' : 'Keep Trying!'));
  final line = perfect ? 'You got them all right!' : '$correct of $total correct';
  final tone = perfect || good ? cGreen : cOrange;
  return Positioned.fill(
    child: Container(
      color: Colors.black.withValues(alpha: 0.7),
      alignment: Alignment.center,
      child: Container(
        width: 600,
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0E3566), Color(0xFF061B3C)]),
          border: Border.all(color: tone, width: 3),
          boxShadow: [BoxShadow(color: tone.withValues(alpha: 0.6), blurRadius: 30)],
        ),
        child: Row(children: [
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [tone.withValues(alpha: 0.55), tone.withValues(alpha: 0.0)])),
            child: Icon(perfect || good ? Icons.eco_rounded : Icons.hourglass_bottom_rounded, size: 110, color: perfect || good ? const Color(0xFF8BE04A) : const Color(0xFFFFC107), shadows: [Shadow(color: tone, blurRadius: 24)]),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
              FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: tone, shadows: const [Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 3))]))),
              const SizedBox(height: 4),
              Text(line, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white70)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF0A2147), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFFFC107), width: 2)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 28),
                  const SizedBox(width: 8),
                  Text('+$points points', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFFFD54F))),
                ]),
              ),
              const SizedBox(height: 16),
              GlowButton(label: buttonLabel, icon: Icons.arrow_forward_rounded, color: cOrange, width: 240, onTap: onContinue),
            ]),
          ),
        ]),
      ),
    ),
  );
}
