import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'art.dart';
import 'common.dart';
import 's2.dart';
import 'shop.dart';
import 'ui_kit.dart';
import 'gsessions.dart';
import 'rounds.dart' show gRoundScreen;
import 'gen_ui.dart' show loadArt;
import 'visuals.dart' show BioWordmark;

// =====================================================================
// DATA (all taken from the client's spec)
// =====================================================================
class HeroData {
  final String name, skill, desc;
  final Color color;
  const HeroData(this.name, this.skill, this.desc, this.color);
}

const _heroes1 = [
  HeroData('Mito the Mighty', 'Time Boost', '+10 seconds added to one round.', Color(0xFFFF9800)),
  HeroData('Gluco the Genius', 'Hint Power', 'Reveals one hint in a round.', Color(0xFFFFC107)),
  HeroData('Oxy the Observer', '50/50 Power', 'Removes 2 wrong choices in Round 2.', Color(0xFF2D9CFF)),
  HeroData('Atty the Lucky', 'Second Chance', 'Gives a second try on one wrong answer.', Color(0xFF39E36B)),
];

const _heroes2 = [
  HeroData('Mito the Mighty', 'Time Boost', 'Adds 10 seconds to one round.', Color(0xFFFF9800)),
  HeroData('Gluco the Genius', 'Hint Power', 'Reveals one hint during a round.', Color(0xFFFFC107)),
  HeroData('Oxy the Observer', '50/50 Power', 'Removes two wrong options from one multiple-choice question.', Color(0xFF2D9CFF)),
  HeroData('Atty the Lucky', 'Second Chance', 'Allows one second try after a wrong answer.', Color(0xFF39E36B)),
];

const _heroesN = [
  HeroData('Mito the Mighty', 'Time Boost', '+10 seconds added to one round.', Color(0xFFFF9800)),
  HeroData('Gluco the Genius', 'Hint Power', 'Reveals one hint in a round.', Color(0xFFFFC107)),
  HeroData('Oxy the Observer', '50/50 Power', 'Removes 2 wrong choices in Round 3.', Color(0xFF2D9CFF)),
  HeroData('Atty the Lucky', 'Second Chance', 'Gives a second try on one wrong answer.', Color(0xFF39E36B)),
];

const _heroes8 = [
  HeroData('Mito the Mighty', 'Time Boost', '+10 seconds added to one round.', Color(0xFFFF9800)),
  HeroData('Gluco the Genius', 'Hint Power', 'Reveals one hint in a round.', Color(0xFFFFC107)),
  HeroData('Oxy the Observer', '50/50 Power', 'Removes 2 wrong choices in Round 3.', Color(0xFF2D9CFF)),
  HeroData('Atty the Lucky', 'Second Chance', 'Gives a second try on one wrong answer.', Color(0xFF39E36B)),
];

/// The 4 heroes of the session the student is playing.
List<HeroData> get heroes {
  final s = Store.cur;
  if (s == 2) return _heroes2;
  if (s == 8) return _heroes8;
  if (s >= 3) return _heroesN;
  return _heroes1;
}


class Scr {
  final String scrambled, def, answer;
  const Scr(this.scrambled, this.def, this.answer);
}

const scrambles = [
  Scr('SOGLCUE', 'A simple sugar from food that is the main fuel of cells.', 'GLUCOSE'),
  Scr('GENOXY', 'The gas that cells use to help release energy from food.', 'OXYGEN'),
  Scr('IROCHMANTIDO', 'The powerhouse of the cell where most energy is made.', 'MITOCHONDRIA'),
  Scr('BOARICE', 'Respiration that needs oxygen.', 'AEROBIC'),
  Scr('TIRAPSONIER', 'The process where cells break down food to release energy.', 'RESPIRATION'),
  Scr('CABIRNAOE', 'Respiration that does not need oxygen.', 'ANAEROBIC'),
];

class PicQ {
  final String q, hint, right;
  final List<String> choices;
  final int answer;
  const PicQ(this.q, this.choices, this.answer, this.hint, this.right);
}

const picQs = [
  PicQ('What organelle is shown in the picture?', ['Nucleus', 'Mitochondria', 'Chloroplast', 'Ribosome'], 1, 'It has folded inner membranes and makes energy.', "Correct! That's a mitochondrion!"),
  PicQ('Which sugar from these foods is the main fuel for cellular respiration?', ['Glucose', 'Oxygen', 'Carbon dioxide', 'Sunlight'], 0, 'It is a simple sugar that comes from food.', 'Correct! Glucose is the main fuel for cells.'),
  PicQ('Why do cells need the oxygen we breathe in?', ['To cool the body', 'To help release energy from food', 'To make glucose', 'To grow taller'], 1, 'Oxygen helps with releasing energy.', 'Correct! Oxygen helps cells release energy from food.'),
  PicQ('Which one is the energy product of cellular respiration?', ['Glucose', 'Oxygen', 'ATP', 'Sunlight'], 2, 'Look for the lightning bolt: it is the energy currency.', 'Correct! ATP is the energy product!'),
  PicQ('What type of respiration is this?', ['Aerobic respiration', 'Anaerobic respiration', 'Photosynthesis', 'Digestion'], 1, 'Look closely: there is no air inside the jar.', 'Correct! This is anaerobic respiration.'),
];

class TfQ {
  final String text, why, hint;
  final bool answer;
  const TfQ(this.text, this.answer, this.why, this.hint);
}

const tfQs = [
  TfQ('Cellular respiration releases energy from food inside cells.', true, 'Cells release energy from food during respiration.', 'Think about what cells do with food.'),
  TfQ('Plants are the only living things that carry out cellular respiration.', false, 'All living things do respiration, not only plants.', 'Do animals need energy too?'),
  TfQ('ATP is the energy currency used by cells.', true, 'ATP is the energy currency of cells.', 'ATP is called the energy currency.'),
  TfQ('Carbon dioxide is one of the things a cell needs to start aerobic respiration.', false, 'Oxygen is needed; carbon dioxide is a product.', 'Which one do cells need, and which one do they release?'),
  TfQ('Most cellular respiration happens in the mitochondria.', true, 'The mitochondria are the powerhouse of the cell.', 'Which organelle is the powerhouse?'),
  TfQ('Anaerobic respiration needs oxygen.', false, 'Anaerobic respiration does not need oxygen.', '"Anaerobic" means without oxygen.'),
];

class MatchState {
  final int hero;
  final List<int> correct = [0, 0, 0];
  bool skillUsed = false;
  MatchState(this.hero);
  int coinsBefore(int round) {
    var n = 0;
    for (var i = 0; i < round - 1; i++) {
      n += correct[i] * 50;
    }
    return n;
  }

  int get coins => correct.fold<int>(0, (a, b) => a + b * 50);
}

// =====================================================================
// Hero picture (drawn with code)
// =====================================================================
/// BioBlast science hero art assets. The same hero index is used by the
/// selection screen, gameplay HUD, results, the student profile and the shop.
const _heroAssetNames = ['mito', 'gluco', 'oxy', 'atp'];

class HeroAvatar extends StatelessWidget {
  final int hero;
  final double size;
  final bool fullBody;
  const HeroAvatar({super.key, required this.hero, this.size = 100, this.fullBody = false});

  @override
  Widget build(BuildContext context) {
    final index = hero.clamp(0, _heroAssetNames.length - 1);
    final name = _heroAssetNames[index];
    final asset = 'assets/images/heroes/$name${fullBody ? '' : '_avatar'}.png';
    final art = Image.asset(
      asset,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: heroes[index].name,
      errorBuilder: (_, __, ___) => Icon(Icons.science_rounded, color: heroes[index].color, size: size * .6),
    );
    if (fullBody) {
      return SizedBox(width: size, height: size * 1.18, child: art);
    }
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFF08224C),
        child: art,
      ),
    );
  }
}

// =====================================================================
// PLAY START  (big glowing Play button)
// =====================================================================
class PlayStartScreen extends StatefulWidget {
  const PlayStartScreen({super.key});
  @override
  State<PlayStartScreen> createState() => _PlayStartScreenState();
}

class _PlayStartScreenState extends State<PlayStartScreen> with SingleTickerProviderStateMixin {
  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stage(
        child: Stack(children: [
          const Positioned(top: 12, right: 16, child: HomeButton()),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const BioWordmark(size: 74),
              const SizedBox(height: 10),
              const Text('3 rounds. Earn coins. Spend them at My Cafe!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFB3E5FC))),
              const SizedBox(height: 30),
              AnimatedBuilder(
                animation: pulse,
                builder: (_, child) => Transform.scale(scale: 1 + pulse.value * 0.06, child: child),
                child: Pressable(
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PlayLoadingScreen())),
                  child: Container(
                    width: 300,
                    height: 100,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFB74D), Color(0xFFFF6D00)]),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(color: cOrange.withValues(alpha: 0.8), blurRadius: 30, spreadRadius: 2)],
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.play_arrow_rounded, size: 60),
                      Text('PLAY', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: 3)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      );
}

// =====================================================================
// LOADING (a cell filling with energy, 4 seconds, with a tip)
// =====================================================================
class PlayLoadingScreen extends StatefulWidget {
  const PlayLoadingScreen({super.key});
  @override
  State<PlayLoadingScreen> createState() => _PlayLoadingScreenState();
}

class _PlayLoadingScreenState extends State<PlayLoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  @override
  void initState() {
    super.initState();
    c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HeroSelectScreen()));
      }
    });
    c.forward();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stage(
        child: Center(
          child: AnimatedBuilder(
            animation: c,
            builder: (_, __) => Column(mainAxisSize: MainAxisSize.min, children: [
              if (isGeneric(Store.cur))
                loadArt(specFor(Store.cur)!.loadKind, c.value)
              else if (Store.cur == 2)
                SizedBox(width: 340, height: 206, child: FittedBox(child: MitoArt(width: 340, glow: true)))
              else
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.cyanAccent, width: 5), boxShadow: [BoxShadow(color: cGreen.withValues(alpha: 0.5), blurRadius: 24)]),
                child: ClipOval(
                  child: Stack(fit: StackFit.expand, children: [
                    Container(color: const Color(0xFF0B2E5E)),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: c.value,
                        widthFactor: 1,
                        child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB2FF59), Color(0xFF2ECC71)]))),
                      ),
                    ),
                    const Center(child: Icon(Icons.bolt, size: 100, color: Colors.white)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Text('Loading... ${(c.value * 100).round()}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: panelDeco(border: cGreen, r: 20),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFD54F)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(isGeneric(Store.cur) ? specFor(Store.cur)!.loadTip : (Store.cur == 2 ? 'Tip: Cristae are folds of the inner membrane.' : 'Tip: Cells make ATP using glucose and oxygen!'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                ]),
              ),
            ]),
          ),
        ),
      );
}

// =====================================================================
// HERO SELECTION
// =====================================================================
class HeroSelectScreen extends StatefulWidget {
  const HeroSelectScreen({super.key});
  @override
  State<HeroSelectScreen> createState() => _HeroSelectScreenState();
}

class _HeroSelectScreenState extends State<HeroSelectScreen> {
  int? pick;

  Widget card(int i) {
    final h = heroes[i];
    final on = pick == i;
    return Pressable(
      onTap: () => setState(() => pick = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 212,
        height: 330,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cPanel.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: on ? Colors.white : h.color, width: on ? 5 : 2),
          boxShadow: [BoxShadow(color: h.color.withValues(alpha: on ? 0.9 : 0.35), blurRadius: on ? 26 : 10)],
        ),
        child: Column(children: [
          HeroAvatar(hero: i, size: 137, fullBody: true),
          const SizedBox(height: 8),
          FittedBox(fit: BoxFit.scaleDown, child: Text(h.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(color: h.color, borderRadius: BorderRadius.circular(14)),
            child: Text(h.skill, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF10213A))),
          ),
          const SizedBox(height: 8),
          Text(h.desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, height: 1.3)),
          const Spacer(),
          Icon(on ? Icons.check_circle_rounded : Icons.radio_button_unchecked, color: on ? cGreen : Colors.white54, size: 28),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Stage(
        child: Column(children: [
          const TopBar(title: 'Choose Your Hero'),
          const SizedBox(height: 14),
          const Text('Each hero has one special skill for the game.', style: TextStyle(fontSize: 17, color: Colors.white70)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < heroes.length; i++) ...[card(i), if (i < heroes.length - 1) const SizedBox(width: 14)],
          ]),
          const Spacer(),
          GlowButton(
            label: 'Start',
            icon: Icons.play_arrow_rounded,
            width: 280,
            height: 58,
            font: 24,
            color: cOrange,
            onTap: pick == null
                ? null
                : () {
                    Store.setHero(pick!);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => isGeneric(Store.cur) ? gRoundScreen(Store.cur, 1, MatchState(pick!)) : (Store.cur == 2 ? MatchRoundScreen(match: MatchState(pick!)) : Round1Screen(match: MatchState(pick!)))));
                  },
          ),
          const SizedBox(height: 18),
        ]),
      );
}

// =====================================================================
// Shared round logic: 45-second timer, hero skill, pause, overlays
// =====================================================================
mixin RoundBase<T extends StatefulWidget> on State<T> {
  MatchState get match;
  int get roundNo;
  int get totalQs;
  int get correctNow;
  String get roundTitle;
  void applyHint();
  void apply5050() {}
  bool get fiftyOk => roundNo == 2;
  void goNextRound();

  int seconds = 45, maxSeconds = 45;
  bool started = false, paused = false, over = false, timedOut = false, secondChance = false;
  String? toast;
  Timer? _timer;

  void beginRound() {
    setState(() => started = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || paused || over) return;
      setState(() => seconds--);
      if (seconds <= 0) {
        timedOut = true;
        finishRound();
      }
    });
  }

  void finishRound() {
    _timer?.cancel();
    match.correct[roundNo - 1] = correctNow;
    if (mounted) setState(() => over = true);
  }

  void showToast(String m) {
    setState(() => toast = m);
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted && toast == m) setState(() => toast = null);
    });
  }

  bool get skillEnabled => started && !over && !paused && !match.skillUsed && !(match.hero == 2 && !fiftyOk);

  void useSkill() {
    if (!skillEnabled) return;
    switch (match.hero) {
      case 0:
        setState(() {
          seconds += 10;
          maxSeconds = math.max(maxSeconds, seconds);
        });
        showToast('Time Boost! +10 seconds');
        break;
      case 1:
        applyHint();
        showToast('Hint Power!');
        break;
      case 2:
        apply5050();
        showToast('50/50 Power! Two wrong choices removed.');
        break;
      default:
        secondChance = true;
        showToast('Second Chance ready! Your next wrong answer gets another try.');
    }
    setState(() => match.skillUsed = true);
  }

  bool consumeSecondChance() {
    if (secondChance) {
      secondChance = false;
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget hud() {
    final h = heroes[match.hero];
    final coins = match.coinsBefore(roundNo) + correctNow * 50;
    final enabled = skillEnabled;
    final note = match.skillUsed ? 'Used' : (match.hero == 2 && !fiftyOk ? 'Not this round' : 'Tap to use');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: SizedBox(
        height: 50,
        child: Row(children: [
          const SizedBox(width: 110, height: 46, child: FittedBox(child: BioWordmark(size: 26))),
          const Spacer(),
          CoinPill(coins: coins),
          const SizedBox(width: 10),
          Container(
            width: 170,
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: cPanel, borderRadius: BorderRadius.circular(23), border: Border.all(color: seconds <= 10 ? Colors.redAccent : cGreen, width: 2)),
            child: Row(children: [
              const Icon(Icons.timer_rounded, size: 24, color: cGreen),
              const SizedBox(width: 6),
              Text('${seconds}s', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: (seconds / maxSeconds).clamp(0.0, 1.0).toDouble(), minHeight: 8, color: seconds <= 10 ? Colors.redAccent : cGreen, backgroundColor: Colors.white24))),
            ]),
          ),
          const SizedBox(width: 10),
          Pressable(
            onTap: enabled ? useSkill : null,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: cPanel,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: enabled ? h.color : Colors.white24, width: 2),
                boxShadow: enabled ? [BoxShadow(color: h.color.withValues(alpha: 0.6), blurRadius: 12)] : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                HeroAvatar(hero: match.hero, size: 32),
                const SizedBox(width: 8),
                Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h.skill, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: enabled ? Colors.white : Colors.white54)),
                  Text(note, style: const TextStyle(fontSize: 10, color: Colors.white60)),
                ]),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          Pressable(
            onTap: (started && !over) ? () => setState(() => paused = true) : null,
            child: Container(width: 46, height: 46, decoration: BoxDecoration(shape: BoxShape.circle, color: cBlue, border: Border.all(color: Colors.white70, width: 2)), child: const Icon(Icons.pause_rounded, size: 26)),
          ),
        ]),
      ),
    );
  }

  Widget _overlay(Widget content) => Positioned.fill(
        child: Container(
          color: Colors.black54,
          alignment: Alignment.center,
          child: Container(width: 520, padding: const EdgeInsets.all(24), decoration: panelDeco(border: cGreen), child: content),
        ),
      );

  Widget shell(Widget body) {
    final h = heroes[match.hero];
    return Stage(
      child: Stack(children: [
        Column(children: [hud(), Expanded(child: body)]),
        if (toast != null)
          Positioned(
            top: 64,
            left: 0,
            right: 0,
            child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), decoration: BoxDecoration(color: h.color, borderRadius: BorderRadius.circular(20)), child: Text(toast!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF10213A))))),
          ),
        if (!started)
          _overlay(Column(mainAxisSize: MainAxisSize.min, children: [
            Text('ROUND $roundNo of 3', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cGreen)),
            Text(roundTitle, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('$totalQs questions  •  45 seconds', style: const TextStyle(fontSize: 17, color: Colors.white70)),
            const SizedBox(height: 4),
            Text('Hero: ${h.name} (${h.skill})', style: const TextStyle(fontSize: 15, color: Colors.white70)),
            const SizedBox(height: 18),
            GlowButton(label: 'Start', icon: Icons.play_arrow_rounded, color: cOrange, width: 220, onTap: beginRound),
          ])),
        if (paused)
          _overlay(Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Paused', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            const SizedBox(height: 18),
            GlowButton(label: 'Resume', icon: Icons.play_arrow_rounded, width: 220, onTap: () => setState(() => paused = false)),
          ])),
        if (over)
          roundFeedbackOverlay(
            timedOut: timedOut,
            correct: correctNow,
            total: totalQs,
            points: correctNow * 50,
            buttonLabel: roundNo == 3 ? 'See Rewards' : 'Continue',
            onContinue: goNextRound,
          ),
      ]),
    );
  }

  Widget feedbackBar(String? msg, bool ok) => FeedbackPanel(msg: msg, ok: ok);
}

// =====================================================================
// ROUND 1: SCRAMBLED WORDS  (6 words, 45 seconds, 50 coins each)
// =====================================================================
class Round1Screen extends StatefulWidget {
  final MatchState match;
  final List<Scr>? items;
  final void Function(BuildContext)? onNext;
  const Round1Screen({super.key, required this.match, this.items, this.onNext});
  @override
  State<Round1Screen> createState() => _Round1State();
}

class _Round1State extends State<Round1Screen> with RoundBase<Round1Screen> {
  @override
  MatchState get match => widget.match;
  @override
  int get roundNo => 1;
  @override
  int get totalQs => words.length;
  @override
  String get roundTitle => 'Scrambled Words';
  @override
  int get correctNow => solved.where((s) => s).length;

  List<Scr> get words => widget.items ?? scrambles;
  late final List<List<int?>> placed = [for (final s in words) List<int?>.filled(s.answer.length, null)];
  late final List<bool> solved = List<bool>.filled(words.length, false);
  int current = 0;

  @override
  void goNextRound() => widget.onNext != null ? widget.onNext!(context) : Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Round2Screen(match: match)));

  bool get locked => !started || over || paused;

  void tapTile(int w, int t) {
    if (locked || solved[w] || placed[w].contains(t)) return;
    final p = placed[w].indexOf(null);
    if (p < 0) return;
    putTile(w, p, t);
  }

  void putTile(int w, int p, int t) {
    if (locked || solved[w]) return;
    setState(() => placed[w][p] = t);
    if (!placed[w].contains(null)) _check(w);
  }

  void _check(int w) {
    final guess = placed[w].map((i) => words[w].scrambled[i!]).join();
    if (guess == words[w].answer) {
      setState(() => solved[w] = true);
      if (solved.every((s) => s)) finishRound();
    } else {
      showToast(consumeSecondChance() ? 'Second Chance! Rebuild the word and try again.' : 'Not quite. Try again!');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            for (var i = 0; i < placed[w].length; i++) {
              placed[w][i] = null;
            }
          });
        }
      });
    }
  }

  void clearBox(int w, int p) {
    if (locked || solved[w]) return;
    setState(() => placed[w][p] = null);
  }

  @override
  void applyHint() {
    final w = solved.indexOf(false);
    if (w < 0) return;
    final ti = words[w].scrambled.indexOf(words[w].answer[0]);
    setState(() {
      for (var i = 0; i < placed[w].length; i++) {
        placed[w][i] = null;
      }
      placed[w][0] = ti;
    });
  }

  Widget letter(String ch, {double opacity = 1}) => Opacity(
        opacity: opacity,
        child: Container(
          width: 34,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFB74D), Color(0xFFF57C00)]), border: Border.all(color: Colors.white70)),
          child: Text(ch, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
        ),
      );

  Widget tile(int w, int t) {
    final used = solved[w] || placed[w].contains(t);
    final ch = words[w].scrambled[t];
    return Draggable<int>(
      data: w * 100 + t,
      maxSimultaneousDrags: (used || locked) ? 0 : 1,
      feedback: Material(color: Colors.transparent, child: letter(ch)),
      childWhenDragging: letter(ch, opacity: 0.3),
      child: GestureDetector(onTap: () => tapTile(w, t), child: letter(ch, opacity: used ? 0.25 : 1)),
    );
  }

  Widget box(int w, int p) => DragTarget<int>(
        onWillAcceptWithDetails: (d) => !locked && !solved[w] && d.data ~/ 100 == w && placed[w][p] == null && !placed[w].contains(d.data % 100),
        onAcceptWithDetails: (d) => putTile(w, p, d.data % 100),
        builder: (_, cand, __) {
          final ti = placed[w][p];
          return GestureDetector(
            onTap: ti == null ? null : () => clearBox(w, p),
            child: Container(
              width: 34,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: solved[w] ? cGreen.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: cand.isNotEmpty ? Colors.yellowAccent : (solved[w] ? cGreen : Colors.white54), width: 2),
              ),
              child: ti == null ? null : Text(words[w].scrambled[ti], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ),
          );
        },
      );

  Widget wordCard(int w) {
    final s = words[w];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: panelDeco(border: solved[w] ? cGreen : cBlue, r: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 22, height: 22, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: solved[w] ? cGreen : cBlue), child: solved[w] ? const Icon(Icons.check, size: 16) : Text('${w + 1}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900))),
          const SizedBox(width: 6),
          Expanded(child: Wrap(spacing: 2, runSpacing: 2, children: [for (var t = 0; t < s.scrambled.length; t++) tile(w, t)])),
        ]),
        const SizedBox(height: 5),
        Wrap(spacing: 2, runSpacing: 2, children: [for (var p = 0; p < s.answer.length; p++) box(w, p)]),
        const Spacer(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: cBlue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFFFFD54F)),
            const SizedBox(width: 6),
            Expanded(child: Text(s.def, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, height: 1.2))),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => shell(Padding(
    padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
    child: Column(children: [
      Text('Word ${current + 1} of ${words.length} • Scrambled Words', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cGreen)),
      const SizedBox(height: 12),
      Expanded(child: wordCard(current)),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        GlowButton(label: 'Check Answer', width: 220, height: 48,
          onTap: !locked && !solved[current] && !placed[current].contains(null) ? () => _check(current) : null),
        const SizedBox(width: 16),
        GlowButton(label: current == words.length - 1 ? 'Finish Round' : 'Next', width: 220, height: 48,
          onTap: !locked && solved[current] ? () {if (current == words.length - 1) {finishRound();} else {setState(() => current++);}} : null),
      ]),
      const SizedBox(height: 8),
      const Text('Tap letters in order or drag them into the boxes. Tap a filled box to remove its letter.', style: TextStyle(fontSize: 14, color: Colors.white70)),
    ]),
  ));
}

// =====================================================================
// ROUND 2: PICTURE ANALYSIS  (5 pictures, 45 seconds, 50 coins each)
// =====================================================================
class Round2Screen extends StatefulWidget {
  final MatchState match;
  const Round2Screen({super.key, required this.match});
  @override
  State<Round2Screen> createState() => _Round2State();
}

class _Round2State extends State<Round2Screen> with RoundBase<Round2Screen> {
  @override
  MatchState get match => widget.match;
  @override
  int get roundNo => 2;
  @override
  int get totalQs => 5;
  @override
  String get roundTitle => 'Picture Analysis';
  @override
  int get correctNow => right;

  int qi = 0, right = 0;
  bool locked = false;
  final wrongPicks = <int>{};
  final hidden = <int>{};
  String? msg, hintText;
  bool msgOk = false;

  @override
  void goNextRound() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Round3Screen(match: match)));

  @override
  void applyHint() => setState(() => hintText = 'Hint: ${picQs[qi].hint}');

  @override
  void apply5050() {
    final q = picQs[qi];
    final wrong = [0, 1, 2, 3].where((i) => i != q.answer && !wrongPicks.contains(i)).toList()..shuffle();
    setState(() => hidden.addAll(wrong.take(2)));
  }

  void choose(int c) {
    if (!started || over || paused || locked || wrongPicks.contains(c) || hidden.contains(c)) return;
    final q = picQs[qi];
    if (c == q.answer) {
      setState(() {
        locked = true;
        right++;
        msg = q.right;
        msgOk = true;
      });
      _advance();
    } else if (consumeSecondChance()) {
      setState(() {
        wrongPicks.add(c);
        msg = 'Second Chance! That was not it. Try again.';
        msgOk = false;
      });
    } else {
      setState(() {
        locked = true;
        wrongPicks.add(c);
        msg = 'Not quite. The answer is ${'ABCD'[q.answer]}. ${q.choices[q.answer]}.';
        msgOk = false;
      });
      _advance();
    }
  }

  void _advance() {
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted || over) return;
      if (qi == picQs.length - 1) {
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

  Widget choiceBtn(int c) {
    final q = picQs[qi];
    return ChoiceTile(letter: 'ABCD'[c], text: q.choices[c], right: locked && c == q.answer, wrong: wrongPicks.contains(c), hidden: hidden.contains(c), onTap: () => choose(c));
  }

  @override
  Widget build(BuildContext context) {
    final q = picQs[qi];
    return shell(Column(children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: panelDeco(),
                child: Stack(children: [
                  Positioned.fill(child: Padding(padding: const EdgeInsets.all(14), child: FittedBox(fit: BoxFit.contain, child: PicArt(i: qi)))),
                  Positioned(top: 10, left: 14, child: Text('${qi + 1}/${picQs.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white70))),
                ]),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 5,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Round 2: Picture Analysis', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(q.q, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, height: 1.25)),
                const SizedBox(height: 10),
                for (var c = 0; c < 4; c++) ...[choiceBtn(c), const SizedBox(height: 8)],
                if (hintText != null) Text(hintText!, style: const TextStyle(fontSize: 14, color: Color(0xFFFFD54F), fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
      ),
      feedbackBar(msg, msgOk),
    ]));
  }
}

class PicArt extends StatelessWidget {
  final int i;
  const PicArt({super.key, required this.i});

  Widget lab(Widget w, String t) => Column(mainAxisSize: MainAxisSize.min, children: [w, const SizedBox(height: 3), Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800))]);
  Widget arrow() => const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_forward_rounded, size: 34, color: Colors.white));

  @override
  Widget build(BuildContext context) {
    switch (i) {
      case 0:
        return SizedBox(
          width: 340,
          height: 220,
          child: Stack(alignment: Alignment.center, children: const [
            MitoArt(width: 300, glow: true),
            Positioned(top: 8, left: 30, child: Icon(Icons.bolt, size: 44, color: Color(0xFFFFEB3B))),
            Positioned(top: 4, right: 40, child: Icon(Icons.bolt, size: 36, color: Color(0xFFFFEB3B))),
            Positioned(bottom: 8, right: 60, child: Icon(Icons.bolt, size: 40, color: Color(0xFFFFEB3B))),
          ]),
        );
      case 1:
        return const SizedBox(
          width: 340,
          height: 200,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [Text('🍚', style: TextStyle(fontSize: 80)), Text('🍞', style: TextStyle(fontSize: 80)), Text('🍎', style: TextStyle(fontSize: 80))]),
        );
      case 2:
        return SizedBox(
          width: 400,
          height: 200,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🧒', style: TextStyle(fontSize: 76)),
            const Icon(Icons.air_rounded, size: 40, color: Color(0xFF81D4FA)),
            const Bubble(text: 'O₂', color: cBlue, size: 50),
            arrow(),
            const CellArt(width: 130, height: 100),
          ]),
        );
      case 3:
        return SizedBox(
          width: 440,
          height: 230,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [lab(const HexIcon(size: 44), 'Glucose'), const SizedBox(height: 14), lab(const Bubble(text: 'O₂', color: cBlue, size: 44), 'Oxygen')]),
            arrow(),
            CellArt(width: 150, height: 120, inside: const MitoArt(width: 80, glow: true)),
            arrow(),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              lab(const Bubble(text: 'CO₂', color: cGray, size: 40), 'Carbon dioxide'),
              const SizedBox(height: 6),
              lab(const Bubble(text: 'H₂O', color: Color(0xFF29B6F6), size: 40), 'Water'),
              const SizedBox(height: 6),
              lab(const BatteryIcon(width: 26, height: 40), 'Energy'),
            ]),
          ]),
        );
      default:
        return SizedBox(
          width: 420,
          height: 230,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Yeast + Sugar Water', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const Icon(Icons.south_rounded, size: 34),
              const SizedBox(height: 10),
              Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.block, color: Color(0xFFE53935), size: 34), const SizedBox(width: 6), const Text('No air (sealed)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800))]),
            ]),
            const SizedBox(width: 16),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 90, height: 14, decoration: BoxDecoration(color: const Color(0xFF90A4AE), borderRadius: BorderRadius.circular(6))),
              Container(
                width: 120,
                height: 170,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30), top: Radius.circular(10)), border: Border.all(color: Colors.white70, width: 3)),
                child: Stack(children: [
                  for (final b in const [(20.0, 110.0, 14.0), (60.0, 80.0, 18.0), (85.0, 120.0, 12.0), (40.0, 50.0, 10.0), (70.0, 30.0, 14.0), (25.0, 140.0, 10.0)])
                    Positioned(left: b.$1, top: b.$2, child: Container(width: b.$3, height: b.$3, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), color: Colors.white24))),
                ]),
              ),
            ]),
          ]),
        );
    }
  }
}

// =====================================================================
// ROUND 3: TRUE OR FALSE  (6 statements, 45 seconds, 50 coins each)
// =====================================================================
class Round3Screen extends StatefulWidget {
  final MatchState match;
  const Round3Screen({super.key, required this.match});
  @override
  State<Round3Screen> createState() => _Round3State();
}

class _Round3State extends State<Round3Screen> with RoundBase<Round3Screen> {
  @override
  MatchState get match => widget.match;
  @override
  int get roundNo => 3;
  @override
  int get totalQs => 6;
  @override
  String get roundTitle => 'True or False';
  @override
  int get correctNow => right;

  int qi = 0, right = 0;
  bool locked = false;
  String? msg, hintText;
  bool msgOk = false;

  @override
  void goNextRound() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ResultsScreen(match: match)));

  @override
  void applyHint() => setState(() => hintText = 'Hint: ${tfQs[qi].hint}');

  void answer(bool v) {
    if (!started || over || paused || locked) return;
    final q = tfQs[qi];
    if (v == q.answer) {
      setState(() {
        locked = true;
        right++;
        msg = 'Correct! ${q.why}';
        msgOk = true;
      });
      _advance();
    } else if (consumeSecondChance()) {
      setState(() {
        msg = 'Second Chance! Try the other button.';
        msgOk = false;
      });
    } else {
      setState(() {
        locked = true;
        msg = 'Not quite. The answer is ${q.answer ? 'TRUE' : 'FALSE'}. ${q.why}';
        msgOk = false;
      });
      _advance();
    }
  }

  void _advance() {
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted || over) return;
      if (qi == tfQs.length - 1) {
        finishRound();
      } else {
        setState(() {
          qi++;
          locked = false;
          msg = null;
          hintText = null;
        });
      }
    });
  }

  Widget tfBtn(bool v) {
    final col = v ? const Color(0xFF1FA64A) : const Color(0xFFD32F2F);
    return Pressable(
      onTap: () => answer(v),
      child: Container(
        width: 280,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(45),
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(col, Colors.white, 0.3)!, col]),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [BoxShadow(color: col.withValues(alpha: 0.7), blurRadius: 20)],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(v ? Icons.check_rounded : Icons.close_rounded, size: 56),
          const SizedBox(width: 8),
          Text(v ? 'TRUE' : 'FALSE', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = tfQs[qi];
    return shell(Column(children: [
      Expanded(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: panelDeco(r: 20),
            child: Text('${qi + 1} of ${tfQs.length}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 12),
          Container(
            width: 760,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
            decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(26), border: Border.all(color: cBlue, width: 4), boxShadow: [BoxShadow(color: cBlue.withValues(alpha: 0.5), blurRadius: 20)]),
            child: Text(q.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0D2B52), height: 1.25)),
          ),
          const SizedBox(height: 8),
          SizedBox(height: 22, child: hintText == null ? null : Text(hintText!, style: const TextStyle(fontSize: 15, color: Color(0xFFFFD54F), fontWeight: FontWeight.w700))),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [tfBtn(true), const SizedBox(width: 30), tfBtn(false)]),
        ]),
      ),
      feedbackBar(msg, msgOk),
    ]));
  }
}

// =====================================================================
// REWARDS / MVP  (mockup screen 14). Shown after the 3 rounds: coins,
// score of each round, a badge when the score is 75% or more, and the hero.
// =====================================================================
class ResultsScreen extends StatefulWidget {
  final MatchState match;
  final List<int> totals;
  final String? message;
  final String shopLabel;
  final Widget Function()? toShop;
  const ResultsScreen({super.key, required this.match, this.totals = const [6, 5, 6], this.message, this.shopLabel = 'My Cafe', this.toShop});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late final int session = Store.cur;

  @override
  void initState() {
    super.initState();
    Store.addCoins(widget.match.coins);
    Store.recordScore(session,
      widget.match.correct.fold<int>(0, (a, b) => a + b),
      widget.totals.fold<int>(0, (a, b) => a + b));
    Store.mark('play');
  }

  int get got => widget.match.correct.fold<int>(0, (a, b) => a + b);
  int get of => widget.totals.fold<int>(0, (a, b) => a + b);
  bool get mvp => of > 0 && got * 4 >= of * 3;

  Widget trophy() => SizedBox(
        height: 190,
        child: Stack(alignment: Alignment.center, children: [
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFFFC107).withValues(alpha: mvp ? 0.55 : 0.25), const Color(0x00FFC107)])),
          ),
          Icon(Icons.emoji_events_rounded, size: 150, color: mvp ? const Color(0xFFFFC107) : const Color(0xFF90A4AE), shadows: [Shadow(color: mvp ? const Color(0xFFFFA000) : Colors.black54, blurRadius: 26)]),
          Positioned(
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(colors: mvp ? const [Color(0xFFD32F2F), Color(0xFF8E1F1F)] : const [Color(0xFF455A64), Color(0xFF263238)]),
                border: Border.all(color: mvp ? const Color(0xFFFFD54F) : Colors.white38, width: 2),
              ),
              child: Text(mvp ? 'MVP' : 'GOOD TRY', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ),
          ),
        ]),
      );

  Widget rewardRow(Widget lead, String text, {bool on = true, String? tail}) => Opacity(
        opacity: on ? 1 : 0.45,
        child: Container(
          height: 52,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFF0A2147), borderRadius: BorderRadius.circular(14), border: Border.all(color: cBlue.withValues(alpha: 0.6), width: 1.5)),
          child: Row(children: [
            lead,
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            if (tail != null) Text(tail, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white70)),
          ]),
        ),
      );

  Widget circleIcon(IconData ic, Color a, Color b) => Container(width: 34, height: 34, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [a, b])), child: Icon(ic, size: 20, color: Colors.white));

  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    final h = heroes[m.hero];
    return PortraitStage(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 0),
          child: Row(children: [
            const Expanded(child: Text('Rewards', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
            CoinPill(coins: Store.coins.value),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
            child: Column(children: [
              trophy(),
              Text(mvp ? 'Most Valuable Player' : 'Nice effort, Scientist!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFFFD54F))),
              const SizedBox(height: 2),
              Text(widget.message ?? (mvp ? 'You did an amazing job!' : 'Play again to earn the MVP badge.'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.white70)),
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerLeft, child: Text('Rewards Earned', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
              const SizedBox(height: 8),
              rewardRow(circleIcon(Icons.star_rounded, const Color(0xFFFFE082), const Color(0xFFFFA000)), '+${m.coins} Points', tail: '$got / $of correct'),
              rewardRow(circleIcon(Icons.military_tech_rounded, const Color(0xFF8BE04A), const Color(0xFF2EAE4F)), mvp ? 'New Badge: Session $session Master' : 'Badge: score 75% to earn', on: mvp),
              rewardRow(HeroAvatar(hero: m.hero, size: 34), h.name, tail: h.skill),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: panelDeco(border: cGreen),
                child: Column(children: [
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Text('Round ${i + 1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text('${m.correct[i]}/${widget.totals[i]}', style: const TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 14),
                        SizedBox(width: 70, child: Text('+${m.correct[i] * 50}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFFFD54F)))),
                      ]),
                    ),
                ]),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
          child: GlowButton(
            label: widget.shopLabel == 'My Cafe' ? 'Continue' : widget.shopLabel,
            icon: Icons.arrow_forward_rounded,
            color: cOrange,
            width: double.infinity,
            height: 58,
            font: 24,
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => widget.toShop != null ? widget.toShop!() : const ShopScreen())),
          ),
        ),
      ]),
    );
  }
}
