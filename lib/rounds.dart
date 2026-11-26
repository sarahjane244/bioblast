import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'common.dart';
import 'ui_kit.dart';
import 'gmodels.dart';
import 'gsessions.dart';
import 'revised_map.dart';
import 'gen_ui.dart' show bioIcon;
import 'play.dart';
import 'shop.dart';

// =====================================================================
// PLAY rounds for Sessions 3 to 8. Every round has a 45-second timer,
// the hero skill button, and 50 coins per correct item (from play.dart).
// =====================================================================
abstract class GRoundWidget extends StatefulWidget {
  final int session, round;
  final MatchState match;
  const GRoundWidget({super.key, required this.session, required this.round, required this.match});
  RoundSpec get spec => specFor(session)!.rounds[round - 1];
}

Widget gRoundScreen(int s, int round, MatchState m) {
  final r = specFor(s)!.rounds[round - 1];
  switch (r.kind) {
    case 'scramble':
      return Round1Screen(match: m, items: r.words, onNext: (c) => gNextRound(c, s, round, m));
    case 'pairs':
      return PairsRound(session: s, round: round, match: m);
    case 'slots':
      return SlotsRound(session: s, round: round, match: m);
    case 'swap':
      return SwapRound(session: s, round: round, match: m);
    case 'picture':
    case 'mc':
      return QuizRound(session: s, round: round, match: m);
    case 'catch':
      return CatchRound(session: s, round: round, match: m);
    case 'sort':
      return SortRound(session: s, round: round, match: m);
    case 'vault':
      return VaultRound(session: s, round: round, match: m);
    default:
      return PinRound(session: s, round: round, match: m);
  }
}

void gNextRound(BuildContext context, int s, int round, MatchState m) {
  if (round < 3) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => gRoundScreen(s, round + 1, m)));
    return;
  }
  final spec = specFor(s)!;
  final totals = [for (final r in spec.rounds) r.count];
  final max = totals.fold<int>(0, (a, b) => a + b) * 50;
  final pct = m.coins / max;
  final text = pct >= 0.85 ? 'Excellent work! You really know this lesson!' : (pct >= 0.5 ? 'Great work! Review the cards you missed and try again.' : 'Good try! Review the term cards and play again.');
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => ResultsScreen(match: m, totals: totals, message: text, shopLabel: 'Enter ${spec.shopName}', toShop: () => ShopScreen(session: s))),
  );
}


Widget _iconBox(String icon, double size) => icon.isEmpty ? const SizedBox() : SizedBox(width: size + 6, height: size, child: FittedBox(child: bioIcon(icon, size: size)));

Widget _counterChip(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: panelDeco(r: 14),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
    );

Widget _rulePanel(String title, String rule, int n, String unit) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: panelDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        Text('$n $unit • 45 seconds', style: const TextStyle(fontSize: 12, color: cGreen, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(rule, style: const TextStyle(fontSize: 11.5, height: 1.25, color: Colors.white70)),
      ]),
    );

// =====================================================================
// PAIRS: tap a term then its meaning, or drag a meaning onto a term
// =====================================================================
class PairsRound extends GRoundWidget {
  const PairsRound({super.key, required super.session, required super.round, required super.match});
  @override
  State<PairsRound> createState() => _PairsState();
}

class _PairsState extends State<PairsRound> with RoundBase<PairsRound> {
  @override
  MatchState get match => widget.match;
  @override
  int get roundNo => widget.round;
  @override
  int get totalQs => pairs.length;
  @override
  String get roundTitle => widget.spec.title;
  @override
  int get correctNow => matched.length;
  @override
  bool get fiftyOk => widget.round == specFor(widget.session)!.fiftyRound;
  @override
  void goNextRound() => gNextRound(context, widget.session, widget.round, match);

  List<Pair> get pairs => widget.spec.pairs;
  final matched = <int>{};
  int? selL, selR;
  int combo = 0;
  bool msgOk = false;
  String? msg, hintText;
  late final List<int> order = List<int>.generate(pairs.length, (i) => i)..shuffle();
  bool get locked => !started || over || paused;

  @override
  void applyHint() {
    final l = List<int>.generate(pairs.length, (i) => i).firstWhere((i) => !matched.contains(i), orElse: () => -1);
    if (l < 0) return;
    setState(() {
      selL = l;
      selR = order.indexOf(l);
      hintText = 'Hint: ${pairs[l].term} goes with the glowing meaning.';
    });
  }

  void tryMatch(int l, int r) {
    if (locked || matched.contains(l) || matched.contains(order[r])) return;
    if (order[r] == l) {
      setState(() {
        matched.add(l);
        combo++;
        selL = null;
        selR = null;
        hintText = null;
        msgOk = true;
        msg = combo >= 2 ? 'Correct! Combo x$combo! +50 coins.' : 'Correct! +50 coins.';
      });
      if (matched.length == pairs.length) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted && !over) finishRound();
        });
      }
    } else {
      setState(() {
        combo = 0;
        selL = null;
        selR = null;
        msgOk = false;
        msg = 'Not a match. Try again!';
      });
    }
  }

  void tapL(int l) {
    if (locked || matched.contains(l)) return;
    setState(() => selL = l);
    if (selR != null) tryMatch(l, selR!);
  }

  void tapR(int r) {
    if (locked || matched.contains(order[r])) return;
    setState(() => selR = r);
    if (selL != null) tryMatch(selL!, r);
  }

  Widget leftCard(int l) {
    final p = pairs[l];
    final done = matched.contains(l), on = selL == l;
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => !locked && !done,
      onAcceptWithDetails: (d) => tryMatch(l, d.data),
      builder: (_, cand, __) => GestureDetector(
        onTap: () => tapL(l),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: done ? const Color(0xFF14532D) : cPanel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: done ? cGreen : (cand.isNotEmpty || on ? Colors.yellowAccent : cBlue), width: on || cand.isNotEmpty ? 4 : 2),
          ),
          child: Row(children: [
            _iconBox(p.icon, 34),
            const SizedBox(width: 8),
            Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(p.term, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))),
            if (done) const Icon(Icons.check_circle_rounded, color: cGreen),
          ]),
        ),
      ),
    );
  }

  Widget rightCard(int r) {
    final p = pairs[order[r]];
    final done = matched.contains(order[r]), on = selR == r;
    Widget body(double op) => Opacity(
          opacity: op,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: done ? const Color(0xFF14532D) : const Color(0xFF1E6FD9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: done ? cGreen : (on ? Colors.yellowAccent : Colors.white70), width: on ? 4 : 2),
            ),
            alignment: Alignment.centerLeft,
            child: Row(children: [
              Expanded(child: Text(p.meaning, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.15))),
              if (done) const Icon(Icons.check_circle_rounded, color: cGreen),
            ]),
          ),
        );
    return Draggable<int>(
      data: r,
      maxSimultaneousDrags: (locked || done) ? 0 : 1,
      feedback: Material(color: Colors.transparent, child: SizedBox(width: 380, height: 56, child: body(1))),
      childWhenDragging: body(0.3),
      child: GestureDetector(onTap: () => tapR(r), child: body(1)),
    );
  }

  @override
  Widget build(BuildContext context) => shell(Column(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(children: [
              SizedBox(width: 280, child: Column(children: [for (var l = 0; l < pairs.length; l++) Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 6), child: leftCard(l)))])),
              const SizedBox(width: 12),
              Expanded(child: Column(children: [for (var r = 0; r < pairs.length; r++) Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 6), child: rightCard(r)))])),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: Column(children: [
                  _rulePanel(widget.spec.title, widget.spec.rule, pairs.length, 'pairs'),
                  const SizedBox(height: 8),
                  _counterChip('Pairs: ${matched.length} of ${pairs.length}'),
                  if (combo >= 2) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Combo x$combo!', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFFFD54F)))),
                  if (hintText != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(hintText!, style: const TextStyle(fontSize: 11, color: Color(0xFFFFD54F), fontWeight: FontWeight.w700))),
                  const Spacer(),
                  GlowButton(label: 'Next', icon: Icons.arrow_forward_rounded, width: 160, height: 50, font: 22, onTap: (started && !over) ? finishRound : null),
                ]),
              ),
            ]),
          ),
        ),
        feedbackBar(msg, msgOk),
      ]));
}

// =====================================================================
// SLOTS: drag step cards into numbered slots (a pathway, blanks or a wheel)
// =====================================================================
class SlotsRound extends GRoundWidget {
  const SlotsRound({super.key, required super.session, required super.round, required super.match});
  @override
  State<SlotsRound> createState() => _SlotsState();
}

class _SlotsState extends State<SlotsRound> with RoundBase<SlotsRound> {
  @override
  MatchState get match => widget.match;
  @override
  int get roundNo => widget.round;
  @override
  int get totalQs => cards.length;
  @override
  String get roundTitle => widget.spec.title;
  @override
  int get correctNow => placed.where((e) => e != null).length;
  @override
  bool get fiftyOk => widget.round == specFor(widget.session)!.fiftyRound;
  @override
  void goNextRound() => gNextRound(context, widget.session, widget.round, match);

  List<StepCard> get cards => widget.spec.steps;
  bool get wheel => widget.spec.wheel;
  late final List<int> pool = List<int>.generate(cards.length, (i) => i)..shuffle();
  late final List<int?> placed = List<int?>.filled(cards.length, null);
  int? selCard;
  bool msgOk = false;
  String? msg, hintText;
  bool get locked => !started || over || paused;

  @override
  void applyHint() {
    final c = pool.firstWhere((i) => !placed.contains(i), orElse: () => -1);
    if (c < 0) return;
    setState(() => hintText = 'Hint: "${cards[c].text}" goes in slot ${c + 1}.');
  }

  void put(int card, int slot) {
    if (locked || placed.contains(card) || placed[slot] != null) return;
    if (card == slot) {
      setState(() {
        placed[slot] = card;
        selCard = null;
        hintText = null;
        msgOk = true;
        msg = cards[card].tip;
      });
      if (!placed.contains(null)) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && !over) finishRound();
        });
      }
    } else {
      setState(() {
        selCard = null;
        msgOk = false;
        msg = 'Try another slot!';
      });
    }
  }

  Widget cardBody(int c, {double w = 250, double op = 1, bool on = false}) => Opacity(
        opacity: op,
        child: Container(
          width: w,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(color: const Color(0xFF1E6FD9), borderRadius: BorderRadius.circular(14), border: Border.all(color: on ? Colors.yellowAccent : Colors.white70, width: on ? 4 : 2)),
          child: Row(children: [
            _iconBox(cards[c].icon, 30),
            const SizedBox(width: 6),
            Expanded(child: Text(cards[c].text, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.15))),
          ]),
        ),
      );

  Widget poolCard(int c) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Draggable<int>(
          data: c,
          maxSimultaneousDrags: locked ? 0 : 1,
          feedback: Material(color: Colors.transparent, child: cardBody(c)),
          childWhenDragging: cardBody(c, op: 0.3),
          child: GestureDetector(onTap: () => setState(() => selCard = selCard == c ? null : c), child: cardBody(c, on: selCard == c)),
        ),
      );

  String slotName(int s) => widget.spec.slotLabels.isNotEmpty ? widget.spec.slotLabels[s] : 'Slot ${s + 1}';

  Widget slotBox(int s, {double? w, double? h}) {
    final c = placed[s];
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => !locked && placed[s] == null,
      onAcceptWithDetails: (d) => put(d.data, s),
      builder: (_, cand, __) => GestureDetector(
        onTap: () {
          if (selCard != null) put(selCard!, s);
        },
        child: Container(
          width: w,
          height: h,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: c != null ? const Color(0xFF14532D) : Colors.white.withValues(alpha: cand.isNotEmpty ? 0.25 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c != null ? cGreen : (cand.isNotEmpty || selCard != null ? Colors.yellowAccent : Colors.white54), width: 2),
          ),
          child: Row(children: [
            Container(width: 26, height: 26, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: c != null ? cGreen : cBlue), child: c != null ? const Icon(Icons.check, size: 18) : Text('${s + 1}', style: const TextStyle(fontWeight: FontWeight.w900))),
            const SizedBox(width: 6),
            Expanded(
              child: c == null
                  ? Text(wheel ? 'Drop here' : '${slotName(s)}: drop here', maxLines: 2, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w700))
                  : Text(cards[c].text, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, height: 1.1)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget slotsArea() {
    if (widget.session == 7) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('SUBSTRATE-LEVEL PATH', style: TextStyle(color: cGreen, fontSize: 13, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Expanded(flex: 2, child: Row(children: [Expanded(child: slotBox(0)), const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward, size: 18)), Expanded(child: slotBox(1))])),
        const SizedBox(height: 12),
        const Text('OXIDATIVE PATH', style: TextStyle(color: cBlue, fontSize: 13, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Expanded(flex: 3, child: Column(children: [for (var i = 2; i < 5; i++) Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 4), child: slotBox(i)))])),
      ]);
    }
    if (!wheel) {
      return Column(children: [for (var s = 0; s < cards.length; s++) Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 6), child: slotBox(s)))]);
    }
    return LayoutBuilder(builder: (_, bc) {
      final cx = bc.maxWidth / 2, cy = bc.maxHeight / 2;
      final rx = bc.maxWidth / 2 - 100, ry = bc.maxHeight / 2 - 42;
      return Stack(children: [
        Center(child: Text('🎡', style: TextStyle(fontSize: math.min(bc.maxHeight * 0.5, 110)))),
        for (var s = 0; s < cards.length; s++)
          Positioned(
            left: cx + rx * math.cos(-math.pi / 2 + s * 2 * math.pi / cards.length) - 90,
            top: cy + ry * math.sin(-math.pi / 2 + s * 2 * math.pi / cards.length) - 36,
            child: SizedBox(width: 180, height: 72, child: slotBox(s)),
          ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) => shell(Column(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(children: [
              SizedBox(
                width: 262,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Step cards', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cGreen)),
                  const SizedBox(height: 4),
                  for (final c in pool) if (!placed.contains(c)) poolCard(c),
                ]),
              ),
              const SizedBox(width: 10),
              Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: panelDeco(), child: slotsArea())),
              const SizedBox(width: 10),
              SizedBox(
                width: 150,
                child: Column(children: [
                  _rulePanel(widget.spec.title, widget.spec.rule, cards.length, 'steps'),
                  const SizedBox(height: 8),
                  _counterChip('Placed: $correctNow of ${cards.length}'),
                  if (hintText != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(hintText!, style: const TextStyle(fontSize: 11, color: Color(0xFFFFD54F), fontWeight: FontWeight.w700))),
                  const Spacer(),
                  GlowButton(label: 'Next', icon: Icons.arrow_forward_rounded, width: 150, height: 50, font: 22, onTap: (started && !over) ? finishRound : null),
                ]),
              ),
            ]),
          ),
        ),
        feedbackBar(msg, msgOk),
      ]));
}

// =====================================================================
// SWAP: tap one card, then another, to swap them into the right order
// =====================================================================
class SwapRound extends GRoundWidget {
  const SwapRound({super.key, required super.session, required super.round, required super.match});
  @override
  State<SwapRound> createState() => _SwapState();
}

class _SwapState extends State<SwapRound> with RoundBase<SwapRound> {
  @override
  MatchState get match => widget.match;
  @override
  int get roundNo => widget.round;
  @override
  int get totalQs => cards.length;
  @override
  String get roundTitle => widget.spec.title;
  @override
  int get correctNow => locks.length;
  @override
  bool get fiftyOk => widget.round == specFor(widget.session)!.fiftyRound;
  @override
  void goNextRound() => gNextRound(context, widget.session, widget.round, match);

  List<StepCard> get cards => widget.spec.steps;
  late final List<int> arr = _shuffle();
  final locks = <int>{};
  int? sel;
  String? tip, hintText;

  List<int> _shuffle() {
    final a = List<int>.generate(cards.length, (i) => i);
    var ok = false;
    while (!ok) {
      a.shuffle();
      ok = true;
      for (var i = 0; i < a.length; i++) {
        if (a[i] == i) ok = false;
      }
    }
    return a;
  }

  bool get locked => !started || over || paused;

  @override
  void applyHint() {
    final p = List<int>.generate(cards.length, (i) => i).firstWhere((i) => !locks.contains(i), orElse: () => -1);
    if (p < 0) return;
    setState(() => hintText = 'Hint: "${cards[p].text}" belongs in position ${p + 1}.');
  }

  void tapPos(int p) {
    if (locked || locks.contains(p)) return;
    if (sel == null) {
      setState(() => sel = p);
      return;
    }
    if (sel == p) {
      setState(() => sel = null);
      return;
    }
    final q = sel!;
    setState(() {
      final t = arr[p];
      arr[p] = arr[q];
      arr[q] = t;
      sel = null;
      for (var i = 0; i < arr.length; i++) {
        if (arr[i] == i && !locks.contains(i)) {
          locks.add(i);
          tip = cards[i].tip;
          hintText = null;
        }
      }
    });
    if (locks.length == cards.length) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !over) finishRound();
      });
    }
  }

  Widget cardAt(int p) {
    final c = arr[p];
    final lock = locks.contains(p), on = sel == p;
    return Expanded(
      child: GestureDetector(
        onTap: () => tapPos(p),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: lock ? const Color(0xFF14532D) : const Color(0xFF1E6FD9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lock ? cGreen : (on ? Colors.yellowAccent : Colors.white70), width: on ? 5 : 2),
            boxShadow: on ? [const BoxShadow(color: Colors.yellowAccent, blurRadius: 14)] : null,
          ),
          child: Column(children: [
            Container(width: 28, height: 28, alignment: Alignment.center, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24), child: Text('${p + 1}', style: const TextStyle(fontWeight: FontWeight.w900))),
            Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: bioIcon(cards[c].icon, size: 54)))),
            Text(cards[c].text, textAlign: TextAlign.center, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, height: 1.15)),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(lock ? Icons.lock_rounded : (on ? Icons.swap_horiz_rounded : Icons.touch_app), size: 16),
              const SizedBox(width: 4),
              Text(lock ? 'Locked in!' : (on ? 'Tap to swap' : 'Tap me'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => shell(Column(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text(widget.spec.rule, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                const SizedBox(width: 10),
                _counterChip('Locked: ${locks.length} of ${cards.length}'),
              ]),
              const SizedBox(height: 6),
              Expanded(
                child: Row(children: [
                  for (var p = 0; p < cards.length; p++) ...[
                    cardAt(p),
                    if (p < cards.length - 1) const Padding(padding: EdgeInsets.symmetric(horizontal: 3), child: Icon(Icons.arrow_forward_rounded, size: 22, color: Colors.white70)),
                  ],
                ]),
              ),
              if (hintText != null) Text(hintText!, style: const TextStyle(fontSize: 13, color: Color(0xFFFFD54F), fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: panelDeco(r: 12), child: Text(tip == null ? 'Tip: tap a card, then tap another to swap.' : 'Tip: $tip', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)))),
                const SizedBox(width: 10),
                GlowButton(label: 'Next', icon: Icons.arrow_forward_rounded, width: 150, height: 44, font: 20, onTap: (started && !over) ? finishRound : null),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 10),
      ]));
}

// =====================================================================
// QUIZ: 6 multiple-choice questions with a side card that reacts
// =====================================================================
class QuizRound extends GRoundWidget {
  const QuizRound({super.key, required super.session, required super.round, required super.match});
  @override
  State<QuizRound> createState() => _QuizState();
}

class _QuizState extends State<QuizRound> with RoundBase<QuizRound> {
  @override
  MatchState get match => widget.match;
  @override
  int get roundNo => widget.round;
  @override
  int get totalQs => qs.length;
  @override
  String get roundTitle => widget.spec.title;
  @override
  int get correctNow => right;
  @override
  bool get fiftyOk => widget.round == specFor(widget.session)!.fiftyRound;
  @override
  void goNextRound() => gNextRound(context, widget.session, widget.round, match);

  List<GQ> get qs => widget.spec.qs;
  GQ get q => qs[qi];
  int qi = 0, right = 0;
  bool locked = false, msgOk = false, dim = false;
  final wrongPicks = <int>{};
  final hidden = <int>{};
  final revealed = <int>{};
  String? msg, hintText;

  @override
  void applyHint() => setState(() => hintText = 'Hint: ${q.hint}');

  @override
  void apply5050() {
    final wrong = List<int>.generate(q.choices.length, (i) => i).where((i) => i != q.answer && !wrongPicks.contains(i)).toList()..shuffle();
    setState(() => hidden.addAll(wrong.take(2)));
  }

  void choose(int c) {
    if (!started || over || paused || locked || wrongPicks.contains(c) || hidden.contains(c)) return;
    if (c == q.answer) {
      setState(() {
        locked = true;
        right++;
        msgOk = true;
        msg = 'Correct! +50 coins.';
        if (q.row >= 0) revealed.add(q.row);
      });
      advance();
    } else if (consumeSecondChance()) {
      setState(() {
        wrongPicks.add(c);
        msgOk = false;
        msg = 'Second Chance! That was not it. Try again.';
      });
    } else {
      setState(() {
        locked = true;
        wrongPicks.add(c);
        msgOk = false;
        dim = true;
        msg = 'Not quite. The answer is ${'ABCD'[q.answer]}. ${q.choices[q.answer]}';
        if (q.row >= 0) revealed.add(q.row);
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => dim = false);
      });
      advance();
    }
  }

  void advance() {
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted || over) return;
      if (paused) {advance(); return;}
      if (qi == qs.length - 1) {
        finishRound();
      } else {
        setState(() {
          qi++;
          locked = false;
          wrongPicks.clear();
          hidden.clear();
          msg = null;
          hintText = null;
        });
      }
    });
  }

  Widget choiceBtn(int c) => ChoiceTile(letter: 'ABCDEFGH'[c], text: q.choices[c], right: locked && c == q.answer, wrong: wrongPicks.contains(c), hidden: hidden.contains(c), height: widget.spec.kind == 'picture' ? 38 : 56, font: 15, onTap: () => choose(c));

  Widget sideCard() {
    final s = widget.spec;
    if (s.side == 'none') return const SizedBox();
    final rows = s.sideRows;
    return Container(
      width: 210,
      padding: const EdgeInsets.all(10),
      decoration: panelDeco(border: cGreen),
      child: s.side == 'case'
          ? Column(children: [
              Text('${s.sideTitle} #${qi + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cGreen)),
              Expanded(child: Center(child: FittedBox(child: bioIcon(q.icon, size: 90)))),
              const Text('Solve the case!', style: TextStyle(fontSize: 13, color: Colors.white70)),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.sideTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cGreen)),
              const SizedBox(height: 6),
              for (var i = 0; i < rows.length; i++)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: (s.side == 'bank' ? q.row == i : (i < right && !dim)) ? cGreen.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: (s.side == 'bank' ? q.row == i : (i < right && !dim)) ? cGreen : Colors.white24, width: 2),
                    ),
                    child: Row(children: [
                      Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(rows[i], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)))),
                      if (s.side == 'bank') Text(revealed.contains(i) && i < s.sideVals.length ? s.sideVals[i] : '?', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFFFD54F))),
                      if (s.side == 'chain' && i < right) const Icon(Icons.bolt, color: Color(0xFFFFEB3B), size: 18),
                    ]),
                  ),
                ),
            ]),
    );
  }

  @override
  Widget build(BuildContext context) => shell(Column(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(children: [
              if (widget.spec.side != 'none') ...[sideCard(), const SizedBox(width: 12)],
              Expanded(
                child: Column(children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: panelDeco(),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(widget.spec.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cGreen)),
                          const Spacer(),
                          Text('${qi + 1} of ${qs.length}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                        ]),
                        Expanded(child: widget.spec.kind == 'picture'
                          ? DragTarget<int>(onAcceptWithDetails: (d) => choose(d.data), builder: (_, __, ___) => Row(children: [
                              Expanded(flex: 3, child: FittedBox(child: RespirationMapDiagram(highlight: qi))),
                              Expanded(flex: 2, child: Text(q.q, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                            ]))
                          : Center(child: Text(q.q, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.25)))),
                        SizedBox(height: 20, child: hintText == null ? null : Text(hintText!, style: const TextStyle(fontSize: 13, color: Color(0xFFFFD54F), fontWeight: FontWeight.w700))),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var row = 0; row < (q.choices.length + 1) ~/ 2; row++) ...[
                    Row(children: [
                      Expanded(child: Draggable<int>(data: row * 2, maxSimultaneousDrags: widget.spec.kind == 'picture' && !locked ? 1 : 0,
                        feedback: Material(color: cPanel, child: Padding(padding: const EdgeInsets.all(10), child: Text(q.choices[row * 2]))), child: choiceBtn(row * 2))),
                      const SizedBox(width: 10),
                      if (row * 2 + 1 < q.choices.length) Expanded(child: Draggable<int>(data: row * 2 + 1, maxSimultaneousDrags: widget.spec.kind == 'picture' && !locked ? 1 : 0,
                        feedback: Material(color: cPanel, child: Padding(padding: const EdgeInsets.all(10), child: Text(q.choices[row * 2 + 1]))), child: choiceBtn(row * 2 + 1))),
                    ]),
                    const SizedBox(height: 6),
                  ],
                ]),
              ),
            ]),
          ),
        ),
        feedbackBar(msg, msgOk),
      ]));
}

// =====================================================================
// CATCH (arcade): slide the basket to catch the correct items
// =====================================================================
class _Fall {
  final int idx;
  final bool good;
  final CatchItem item;
  double x, y;
  _Fall(this.idx, this.good, this.item, this.x, this.y);
}

class CatchRound extends GRoundWidget {
  const CatchRound({super.key, required super.session, required super.round, required super.match});
  @override
  State<CatchRound> createState() => _CatchState();
}

class _CatchState extends State<CatchRound> with RoundBase<CatchRound> {
  @override
  MatchState get match => widget.match;
  @override
  int get roundNo => widget.round;
  @override
  int get totalQs => widget.spec.good.length;
  @override
  String get roundTitle => widget.spec.title;
  @override
  int get correctNow => caught.length;
  @override
  bool get fiftyOk => false;
  @override
  void goNextRound() => gNextRound(context, widget.session, widget.round, match);

  final caught = <int>{};
  final falling = <_Fall>[];
  final rnd = math.Random();
  double w = 900, h = 320, basketX = 450, sinceSpawn = 99;
  bool msgOk = false;
  String? msg, hintText;
  Timer? loop;

  @override
  void beginRound() {
    super.beginRound();
    loop = Timer.periodic(const Duration(milliseconds: 33), (_) => tick(0.033));
  }

  @override
  void dispose() {
    loop?.cancel();
    super.dispose();
  }

  @override
  void applyHint() {
    final i = List<int>.generate(totalQs, (k) => k).firstWhere((k) => !caught.contains(k), orElse: () => -1);
    if (i < 0) return;
    setState(() => hintText = 'Hint: catch ${widget.spec.good[i].name}!');
  }

  void spawn() {
    final goods = [for (var i = 0; i < totalQs; i++) if (!caught.contains(i) && !falling.any((f) => f.good && f.idx == i)) i];
    final bads = widget.spec.bad;
    final useBad = bads.isNotEmpty && (goods.isEmpty || rnd.nextDouble() < 0.35);
    final x = 50 + rnd.nextDouble() * (w - 100);
    if (useBad) {
      final b = rnd.nextInt(bads.length);
      if (goods.isEmpty && falling.any((f) => !f.good)) return;
      falling.add(_Fall(b, false, bads[b], x, -50));
    } else if (goods.isNotEmpty) {
      final g = goods[rnd.nextInt(goods.length)];
      falling.add(_Fall(g, true, widget.spec.good[g], x, -50));
    }
  }

  void tick(double dt) {
    if (!mounted || !started || over || paused) return;
    sinceSpawn += dt;
    if (sinceSpawn > 1.5) {
      sinceSpawn = 0;
      spawn();
    }
    final remove = <_Fall>[];
    String? newMsg;
    var ok = false;
    for (final f in falling) {
      f.y += 125 * dt;
      if (f.y + 54 >= h - 62 && f.y < h - 20 && (f.x - basketX).abs() < 62) {
        remove.add(f);
        if (f.good) {
          caught.add(f.idx);
          newMsg = '${f.item.name}: ${f.item.tip}';
          ok = true;
        } else {
          newMsg = 'Not part of the Krebs cycle!';
          ok = false;
        }
      } else if (f.y > h) {
        remove.add(f);
      }
    }
    falling.removeWhere(remove.contains);
    setState(() {
      if (newMsg != null) {
        msg = newMsg;
        msgOk = ok;
        hintText = null;
      }
    });
    if (caught.length == totalQs && !over) finishRound();
  }

  void moveTo(double x) => setState(() => basketX = x.clamp(50.0, w - 50.0).toDouble());

  @override
  Widget build(BuildContext context) => shell(Column(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text(widget.spec.rule, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                if (hintText != null) Text(hintText!, style: const TextStyle(fontSize: 12, color: Color(0xFFFFD54F), fontWeight: FontWeight.w800)),
                const SizedBox(width: 10),
                _counterChip('Caught: ${caught.length} of $totalQs'),
                const SizedBox(width: 10),
                GlowButton(label: 'Next', icon: Icons.arrow_forward_rounded, width: 120, height: 38, font: 16, onTap: (started && !over) ? finishRound : null),
              ]),
              const SizedBox(height: 6),
              Expanded(
                child: LayoutBuilder(builder: (_, bc) {
                  w = bc.maxWidth;
                  h = bc.maxHeight;
                  return GestureDetector(
                    onPanUpdate: (d) => moveTo(d.localPosition.dx),
                    onTapDown: (d) => moveTo(d.localPosition.dx),
                    child: Container(
                      decoration: panelDeco(border: cGreen),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(children: [
                          for (final f in falling)
                            Positioned(
                              left: f.x - 40,
                              top: f.y,
                              child: SizedBox(
                                width: 80,
                                child: Column(children: [
                                  SizedBox(height: 44, child: FittedBox(child: bioIcon(f.item.icon, size: 44))),
                                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)), child: Text(f.item.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                                ]),
                              ),
                            ),
                          Positioned(
                            left: basketX - 62,
                            bottom: 6,
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              bioIcon('mito', size: 56),
                              Container(width: 124, height: 14, decoration: BoxDecoration(color: const Color(0xFFF57C00), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white70, width: 2))),
                            ]),
                          ),
                          if (started && !over && caught.isEmpty && falling.isEmpty) const Center(child: Text('Get ready...', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
                        ]),
                      ),
                    ),
                  );
                }),
              ),
            ]),
          ),
        ),
        feedbackBar(msg, msgOk),
      ]));
}

// =====================================================================
// SORT: one card at a time into two bins
// =====================================================================
class SortRound extends GRoundWidget {
  const SortRound({super.key, required super.session, required super.round, required super.match});
  @override
  State<SortRound> createState() => _SortState();
}

class _SortState extends State<SortRound> with RoundBase<SortRound> {
  @override
  MatchState get match => widget.match;
  @override
  int get roundNo => widget.round;
  @override
  int get totalQs => cards.length;
  @override
  String get roundTitle => widget.spec.title;
  @override
  int get correctNow => right;
  @override
  bool get fiftyOk => false;
  @override
  void goNextRound() => gNextRound(context, widget.session, widget.round, match);

  List<SortCard> get cards => widget.spec.cards;
  List<String> get bins => widget.spec.bins;
  int ci = 0, right = 0;
  bool msgOk = false, busyAdv = false;
  int? hintBin;
  String? msg;

  @override
  void applyHint() => setState(() => hintBin = cards[ci].bin);

  void drop(int bin) {
    if (!started || over || paused || busyAdv) return;
    final c = cards[ci];
    if (bin == c.bin) {
      setState(() {
        right++;
        msgOk = true;
        msg = c.tip;
        busyAdv = true;
        hintBin = null;
      });
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (!mounted || over) return;
        if (ci == cards.length - 1) {
          finishRound();
        } else {
          setState(() {
            ci++;
            busyAdv = false;
            msg = null;
          });
        }
      });
    } else {
      setState(() {
        msgOk = false;
        msg = 'Try the other bin!';
      });
    }
  }

  Widget cardFace(SortCard c, {double op = 1}) => Opacity(
        opacity: op,
        child: Container(
          width: 270,
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF4FAFF), borderRadius: BorderRadius.circular(22), border: Border.all(color: cBlue, width: 5), boxShadow: [BoxShadow(color: cBlue.withValues(alpha: 0.6), blurRadius: 16)]),
          child: Column(children: [
            Expanded(child: Center(child: FittedBox(child: bioIcon(c.icon, size: 80)))),
            FittedBox(fit: BoxFit.scaleDown, child: Text(c.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF16233B)))),
          ]),
        ),
      );

  Widget bin(int b) => Expanded(
        child: DragTarget<int>(
          onWillAcceptWithDetails: (_) => !busyAdv,
          onAcceptWithDetails: (_) => drop(b),
          builder: (_, cand, __) => GestureDetector(
            onTap: () => drop(b),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (cand.isNotEmpty || hintBin == b) ? cGreen.withValues(alpha: 0.3) : cPanel,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: (cand.isNotEmpty || hintBin == b) ? Colors.yellowAccent : cBlue, width: 4),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(b == 0 ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, size: 40),
                const SizedBox(height: 6),
                Text(bins[b], textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('Drop the card here or tap this bin', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white60)),
              ]),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => shell(Column(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text(widget.spec.rule, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                _counterChip('Sorted: $right of ${cards.length}'),
                const SizedBox(width: 10),
                GlowButton(label: 'Next', icon: Icons.arrow_forward_rounded, width: 120, height: 38, font: 16, onTap: (started && !over) ? finishRound : null),
              ]),
              const SizedBox(height: 8),
              Expanded(
                child: Row(children: [
                  bin(0),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 290,
                    child: Center(
                      child: Draggable<int>(
                        data: ci,
                        maxSimultaneousDrags: busyAdv ? 0 : 1,
                        feedback: Material(color: Colors.transparent, child: cardFace(cards[ci])),
                        childWhenDragging: cardFace(cards[ci], op: 0.3),
                        child: cardFace(cards[ci]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  bin(1),
                ]),
              ),
            ]),
          ),
        ),
        feedbackBar(msg, msgOk),
      ]));
}

// =====================================================================
// VAULT: set number dials, tap Lock In
// =====================================================================
class VaultRound extends GRoundWidget {
  const VaultRound({super.key, required super.session, required super.round, required super.match});
  @override
  State<VaultRound> createState() => _VaultState();
}

class _VaultState extends State<VaultRound> with RoundBase<VaultRound> {
  @override
  MatchState get match => widget.match;
  @override
  int get roundNo => widget.round;
  @override
  int get totalQs => locks.length;
  @override
  String get roundTitle => widget.spec.title;
  @override
  int get correctNow => open.length;
  @override
  bool get fiftyOk => widget.round == specFor(widget.session)!.fiftyRound;
  @override
  void goNextRound() => gNextRound(context, widget.session, widget.round, match);

  List<VaultLock> get locks => widget.spec.locks;
  final open = <int>{};
  final skipped = <int>{};
  int cur = 0, dial = 0;
  bool msgOk = false, shake = false;
  String? msg, hintText;
  static const maxN = 6;

  @override
  void applyHint() => setState(() => hintText = 'Hint: the answer is ${locks[cur].answer.isEven ? 'an even' : 'an odd'} number.');

  @override
  void apply5050() {
    final wrong = [for (var i = 0; i <= maxN; i++) if (i != locks[cur].answer) i]..shuffle();
    setState(() {
      skipped.addAll(wrong.take(2));
      if (skipped.contains(dial)) dial = _step(dial, 1);
    });
  }

  int _step(int from, int d) {
    var n = from;
    for (var i = 0; i <= maxN; i++) {
      n = (n + d + maxN + 1) % (maxN + 1);
      if (!skipped.contains(n)) return n;
    }
    return from;
  }

  bool get lockedUi => !started || over || paused;

  void lockIn() {
    if (lockedUi) return;
    if (dial == locks[cur].answer) {
      setState(() {
        open.add(cur);
        msgOk = true;
        msg = 'Unlocked!';
        hintText = null;
      });
      if (open.length == locks.length) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted && !over) finishRound();
        });
      } else {
        setState(() {
          cur++;
          dial = 0;
          skipped.clear();
        });
      }
    } else {
      setState(() {
        msgOk = false;
        msg = 'Count again!';
        shake = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => shake = false);
      });
    }
  }

  Widget arrow(IconData i, int d) => Pressable(
        onTap: lockedUi || open.length == locks.length ? null : () => setState(() => dial = _step(dial, d)),
        child: Container(width: 70, height: 44, decoration: BoxDecoration(color: cBlue, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white70, width: 2)), child: Icon(i, size: 34)),
      );

  Widget lockBox(int i) {
    final done = open.contains(i), on = i == cur && !done;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: done ? const Color(0xFF14532D) : cPanel, borderRadius: BorderRadius.circular(16), border: Border.all(color: done ? cGreen : (on ? Colors.yellowAccent : Colors.white38), width: on ? 4 : 2)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(done ? Icons.lock_open_rounded : Icons.lock_rounded, size: 28, color: done ? cGreen : Colors.white70),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(locks[i].label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
          Text(done ? '${locks[i].answer}' : '?', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFFFD54F))),
          if (done) const Text('Unlocked!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cGreen)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = locks[cur];
    return shell(Column(children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Column(children: [
            Row(children: [
              Expanded(child: Text(widget.spec.rule, style: const TextStyle(fontSize: 12, color: Colors.white70))),
              _counterChip('Lock ${math.min(cur + 1, locks.length)} of ${locks.length}'),
            ]),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: panelDeco(border: cGreen),
              child: Column(children: [
                Text('Clue: ${l.label} lock', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cGreen)),
                Text(l.clue, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                if (hintText != null) Text(hintText!, style: const TextStyle(fontSize: 13, color: Color(0xFFFFD54F), fontWeight: FontWeight.w700)),
              ]),
            ),
            const SizedBox(height: 8),
            SizedBox(height: 120, child: Row(children: [for (var i = 0; i < locks.length; i++) lockBox(i)])),
            const SizedBox(height: 8),
            Expanded(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  arrow(Icons.keyboard_arrow_up_rounded, 1),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 120,
                    height: 70,
                    alignment: Alignment.center,
                    transform: Matrix4.translationValues(shake ? 8 : 0, 0, 0),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16), border: Border.all(color: shake ? Colors.redAccent : Colors.white, width: 3)),
                    child: Text('$dial', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 4),
                  arrow(Icons.keyboard_arrow_down_rounded, -1),
                ]),
                const SizedBox(width: 30),
                GlowButton(label: 'Lock In', icon: Icons.lock_rounded, color: cOrange, width: 240, height: 70, font: 28, onTap: (started && !over && open.length < locks.length) ? lockIn : null),
              ]),
            ),
          ]),
        ),
      ),
      feedbackBar(msg, msgOk),
    ]));
  }
}

// =====================================================================
// PIN THE PART: tap a pin, read its clue, tap or drag the matching chip
// =====================================================================
class PinRound extends GRoundWidget {
  const PinRound({super.key, required super.session, required super.round, required super.match});
  @override
  State<PinRound> createState() => _PinState();
}

class _PinState extends State<PinRound> with RoundBase<PinRound> {
  @override
  MatchState get match => widget.match;
  @override
  int get roundNo => widget.round;
  @override
  int get totalQs => pins.length;
  @override
  String get roundTitle => widget.spec.title;
  @override
  int get correctNow => solved.length;
  @override
  bool get fiftyOk => false;
  @override
  void goNextRound() => gNextRound(context, widget.session, widget.round, match);

  List<PinItem> get pins => widget.spec.pins;
  final solved = <int>{};
  late final List<int> chipOrder = List<int>.generate(pins.length, (i) => i)..shuffle();
  int sel = 0;
  int? hintChip;
  bool msgOk = false;
  String? msg;
  bool get locked => !started || over || paused;

  @override
  void applyHint() => setState(() => hintChip = sel);

  void tryChip(int pin, int chip) {
    if (locked || solved.contains(pin) || solved.contains(chip)) return;
    if (pin == chip) {
      setState(() {
        solved.add(pin);
        msgOk = true;
        msg = '${pins[pin].term}! Correct! +50 coins.';
        hintChip = null;
        final next = List<int>.generate(pins.length, (i) => i).where((i) => !solved.contains(i));
        if (next.isNotEmpty) sel = next.first;
      });
      if (solved.length == pins.length) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && !over) finishRound();
        });
      }
    } else {
      setState(() {
        msgOk = false;
        msg = 'Not this pin. Read the clue again!';
      });
    }
  }

  Widget pinWidget(int i) {
    final done = solved.contains(i), on = sel == i;
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => !locked && !done,
      onAcceptWithDetails: (d) => tryChip(i, d.data),
      builder: (_, cand, __) => GestureDetector(
        onTap: () => setState(() => sel = i),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: done ? cGreen : (on || cand.isNotEmpty ? Colors.yellowAccent : cBlue), border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: (done ? cGreen : cBlue).withValues(alpha: 0.7), blurRadius: 10)]),
            child: done ? const Icon(Icons.check, color: Colors.black87) : Text('${i + 1}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: on || cand.isNotEmpty ? Colors.black87 : Colors.white)),
          ),
          if (done) Container(margin: const EdgeInsets.only(top: 2), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)), child: Text(pins[i].term, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
        ]),
      ),
    );
  }

  Widget chip(int c) {
    final done = solved.contains(c);
    Widget body(double op) => Opacity(
          opacity: op,
          child: Container(
            width: 150,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(color: done ? const Color(0xFF14532D) : const Color(0xFF1E6FD9), borderRadius: BorderRadius.circular(14), border: Border.all(color: hintChip == c ? Colors.yellowAccent : Colors.white70, width: hintChip == c ? 4 : 2)),
            child: Row(children: [
              _iconBox(pins[c].icon, 26),
              const SizedBox(width: 4),
              Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(pins[c].term, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)))),
            ]),
          ),
        );
    return Draggable<int>(
      data: c,
      maxSimultaneousDrags: (locked || done) ? 0 : 1,
      feedback: Material(color: Colors.transparent, child: body(1)),
      childWhenDragging: body(0.3),
      child: GestureDetector(onTap: () => tryChip(sel, c), child: body(done ? 0.5 : 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = pins[sel];
    return shell(Column(children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Row(children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: panelDeco(),
                child: Stack(children: [
                  const Positioned(left: 14, top: 8, child: Text('Cutaway of the inner membrane', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w700))),
                  Positioned(left: 20, right: 20, top: 130, height: 70, child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(35), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFB74D), Color(0xFFF57C00)])))),
                  Positioned(left: 20, right: 20, top: 150, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final r in const ['I', 'II', 'III', 'IV']) Container(width: 52, height: 58, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF8E44AD), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white70, width: 2)), child: Text(r, style: const TextStyle(fontWeight: FontWeight.w900)))])),
                  for (var i = 0; i < pins.length; i++)
                    Positioned(
                      left: 30.0 + (i % 3) * 165,
                      top: i < 3 ? 40.0 : 235.0,
                      child: pinWidget(i),
                    ),
                ]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.yellowAccent, width: 3)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pin ${sel + 1} says:', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFB45309))),
                    Text('"${p.clue}"', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.25, color: Color(0xFF16233B))),
                  ]),
                ),
                const SizedBox(height: 8),
                Expanded(child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [for (final c in chipOrder) chip(c)])),
                Row(children: [
                  _counterChip('Pins: ${solved.length} of ${pins.length}'),
                  const Spacer(),
                  GlowButton(label: 'Next', icon: Icons.arrow_forward_rounded, width: 120, height: 40, font: 18, onTap: (started && !over) ? finishRound : null),
                ]),
              ]),
            ),
          ]),
        ),
      ),
      feedbackBar(msg, msgOk),
    ]));
  }
}
