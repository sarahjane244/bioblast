import 'package:flutter/material.dart';
import 'common.dart';
import 'explore.dart';
import 'gen_sim.dart';
import 'gen_ui.dart';
import 'gsessions.dart';
import 'learn.dart';
import 'play.dart';
import 's2.dart';
import 'shop.dart';
import 'simulate.dart';

String sessionTitle(int s) => specFor(s)?.hubTitle ?? 'Session $s';

// ---------------------------------------------------------------------
// Sessions: pick a session, then LEARN -> EXPLORE -> SIMULATE -> PLAY
// (each step unlocks the next; Session 2 opens after Session 1's PLAY)
// ---------------------------------------------------------------------
class HubScreen extends StatefulWidget {
  /// Which session tab to show first (the Home screen passes the student's current session).
  final int initial;
  const HubScreen({super.key, this.initial = 1});
  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  late int sel = widget.initial.clamp(1, 8).toInt();

  String titleOf(int s) => sessionTitle(s);

  bool sessionOpen(int s) => s == 1 || kTestMode || Store.isDone('play', s - 1);

  Widget sessionTab(int s) {
    final open = sessionOpen(s);
    final on = sel == s;
    return Pressable(
      onTap: open ? () => setState(() => sel = s) : null,
      child: Opacity(
        opacity: open ? 1 : 0.5,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            gradient: on ? const LinearGradient(colors: [Color(0xFFFFB74D), Color(0xFFFF8A1F)]) : null,
            color: on ? null : cPanel,
            border: Border.all(color: Colors.white54, width: 2),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (!open) const Icon(Icons.lock_rounded, size: 18),
            if (!open) const SizedBox(width: 6),
            Text('Session $s', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }

  Widget stepTile(BuildContext context, int n, String title, String sub, IconData icon, Color color, String key, bool unlocked, Widget Function() page) {
    final done = Store.isDone(key, sel);
    return Pressable(
      onTap: unlocked
          ? () {
              Store.cur = sel;
              Navigator.push(context, MaterialPageRoute(builder: (_) => page()));
            }
          : null,
      child: Opacity(
        opacity: unlocked ? 1 : 0.55,
        child: Container(
          width: 200,
          height: 240,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cPanel.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: done ? cGreen : (unlocked ? color : Colors.white24), width: unlocked ? 3 : 2),
            boxShadow: unlocked ? [BoxShadow(color: (done ? cGreen : color).withValues(alpha: 0.6), blurRadius: 18)] : null,
          ),
          child: Column(children: [
            Text('STEP $n', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white70)),
            const Spacer(),
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color.lerp(color, Colors.white, 0.3)!, color])),
              child: Icon(unlocked ? icon : Icons.lock_rounded, size: 46),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            const Spacer(),
            Icon(done ? Icons.check_circle_rounded : Icons.circle_outlined, color: done ? cGreen : Colors.white30, size: 26),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s2 = sel == 2;
    final gen = isGeneric(sel);
    final spec = specFor(sel);
    return Stage(
      child: AnimatedBuilder(
        animation: Listenable.merge([...Store.flags.values, Store.coins]),
        builder: (context, _) => Column(children: [
          TopBar(title: 'Session $sel: ${titleOf(sel)}', trailing: CoinPill(coins: Store.coins.value)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var i = 1; i <= 8; i++) ...[sessionTab(i), if (i < 8) const SizedBox(width: 6)]]),
          Expanded(
            child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                stepTile(context, 1, 'LEARN', sel >= 4 && sel != 5 ? 'Flip the picture cards' : 'Flip the term cards', Icons.style_rounded, const Color(0xFFFFA000), 'learn', true, () => gen ? GenLearnScreen(session: sel) : LearnScreen(session: sel)),
                const SizedBox(width: 16),
                stepTile(context, 2, 'EXPLORE', 'Watch the video', Icons.ondemand_video_rounded, cBlue, 'explore', Store.isDone('learn', sel), () => gen ? GenExploreScreen(session: sel) : ExploreScreen(session: sel)),
                const SizedBox(width: 16),
                stepTile(context, 3, 'SIMULATE', gen ? spec!.simSub : (s2 ? 'Build the Mitochondrion' : 'Feed the Cell'), Icons.science_rounded, const Color(0xFF9B59B6), 'sim', Store.isDone('explore', sel), () => gen ? GenSimScreen(session: sel) : (s2 ? const S2SimulateScreen() : const SimulateScreen())),
                const SizedBox(width: 16),
                stepTile(context, 4, 'PLAY', (s2 && !gen) ? '3 rounds + Mito Lab Shop' : '3 rounds + My Cafe', Icons.sports_esports_rounded, cOrange, 'play', Store.isDone('sim', sel), () => const PlayStartScreen()),
              ]),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            GlowButton(
              label: (s2 && !gen) ? 'Mito Lab Shop' : 'My Cafe',
              icon: (s2 && !gen) ? Icons.science_rounded : Icons.local_cafe_rounded,
              color: const Color(0xFFB36B2E),
              width: 240,
              locked: !Store.isDone('play', sel),
              onTap: () {
                Store.cur = sel;
                Navigator.push(context, MaterialPageRoute(builder: (_) => ShopScreen(session: sel)));
              },
            ),
            if (Store.isDone('finish', sel)) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFFFC107), borderRadius: BorderRadius.circular(26)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.emoji_events_rounded, color: Color(0xFF7A3E00)),
                  const SizedBox(width: 6),
                  Text(gen ? 'Week $sel complete' : (s2 ? 'Session 2 complete' : 'Week 1 complete'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF7A3E00))),
                ]),
              ),
            ],
            if (kTestMode) ...[
              const SizedBox(width: 16),
              TextButton(onPressed: () => Store.reset(), child: const Text('Reset progress (test)')),
            ],
          ]),
          const SizedBox(height: 18),
        ]),
      ),
    );
  }
}
