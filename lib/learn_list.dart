import 'dart:async';
import 'package:flutter/material.dart';
import 'common.dart';
import 'gsessions.dart';
import 'home.dart';
import 'hub.dart';
import 'visuals.dart';

// =====================================================================
// LEARN (mockup screen 4): "Sessions" list with Session 1 - 8, and a
// "Learning Library" tab with every term. Tapping a session opens its
// LEARN -> EXPLORE -> SIMULATE -> PLAY steps (HubScreen).
// =====================================================================
class LearnListScreen extends StatefulWidget {
  const LearnListScreen({super.key});
  @override
  State<LearnListScreen> createState() => _LearnListScreenState();
}

class _LearnListScreenState extends State<LearnListScreen> {
  bool library = false;
  String? toast;
  Timer? toastTimer;

  @override
  void dispose() {
    toastTimer?.cancel();
    super.dispose();
  }

  bool open(int s) => s == 1 || kTestMode || Store.isDone('play', s - 1);

  void say(String msg) {
    toastTimer?.cancel();
    setState(() => toast = msg);
    toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => toast = null);
    });
  }

  Widget tab(String label, bool on, VoidCallback onTap) => Expanded(
        child: Pressable(
          onTap: onTap,
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: on ? const LinearGradient(colors: [Color(0xFFFFB74D), Color(0xFFFF8A1F)]) : null,
              boxShadow: on ? [BoxShadow(color: cOrange.withValues(alpha: 0.5), blurRadius: 10)] : null,
            ),
            child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: on ? Colors.white : const Color(0xFF8FB4D9))),
          ),
        ),
      );

  Widget sessionRow(int s) {
    final isOpen = open(s);
    final done = Store.isDone('finish', s);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: () {
          if (!isOpen) {
            say('Finish the PLAY step of Session ${s - 1} to unlock Session $s.');
            return;
          }
          Go.sessions(context, s);
        },
        child: Opacity(
          opacity: isOpen ? 1 : 0.55,
          child: Container(
            height: 66,
            padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0A2147),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: done ? cGreen : cBlue.withValues(alpha: 0.75), width: 2),
              boxShadow: [BoxShadow(color: (done ? cGreen : cBlue).withValues(alpha: isOpen ? 0.35 : 0.1), blurRadius: 8)],
            ),
            child: Row(children: [
              SessionThumb(no: s, locked: !isOpen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Session $s', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  Text(sessionTitle(s), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                ]),
              ),
              if (done) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.check_circle_rounded, color: cGreen, size: 22)),
              Icon(isOpen ? Icons.chevron_right_rounded : Icons.lock_rounded, color: Colors.white54, size: isOpen ? 28 : 22),
            ]),
          ),
        ),
      ),
    );
  }

  Widget sessionsList() => ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        children: [for (var s = 1; s <= 8; s++) sessionRow(s)],
      );

  // ---- Learning Library: every term of every session ----
  List<(String, String, Color)> termsOf(int s) {
    final spec = specFor(s);
    return spec == null ? [] : [for (final t in spec.terms) (t.name, t.plain, t.color)];
  }

  Widget libraryList() => ListView(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        children: [
          for (var s = 1; s <= 8; s++)
            if (open(s)) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                child: Text('Session $s  •  ${sessionTitle(s)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFFFB74D))),
              ),
              for (final t in termsOf(s))
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0A2147), borderRadius: BorderRadius.circular(14), border: Border(left: BorderSide(color: t.$3, width: 5))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.$1, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(t.$2, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  ]),
                ),
            ],
        ],
      );

  @override
  Widget build(BuildContext context) => PortraitStage(
        child: AnimatedBuilder(
          animation: Listenable.merge([...Store.flags.values]),
          builder: (context, _) => Stack(children: [
            Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 8),
                child: Row(children: [
                  const Expanded(child: Text('LEARN', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1))),
                  Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: cPanel, border: Border.all(color: Colors.white70, width: 2)), child: const Icon(Icons.close_rounded, size: 24)),
                  ),
                ]),
              ),
              Container(
                height: 48,
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: cPanel.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(24), border: Border.all(color: cBlue.withValues(alpha: 0.6), width: 2)),
                child: Row(children: [
                  tab('Sessions', !library, () => setState(() => library = false)),
                  tab('Learning Library', library, () => setState(() => library = true)),
                ]),
              ),
              Expanded(child: library ? libraryList() : sessionsList()),
            ]),
            if (toast != null)
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
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
