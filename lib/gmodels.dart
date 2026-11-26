import 'package:flutter/material.dart';
import 'play.dart' show Scr;
import 'shop.dart' show Product;

// =====================================================================
// Data models for Sessions 3 to 8.
// All the words, numbers, questions and answers live in gdata_*.dart and
// come straight from the client's session documents.
// =====================================================================

/// One flip card in the LEARN step. `icon` is a key for bioIcon().
class GTerm {
  final String name, def, icon, image, group;
  final bool pictureOnly;
  final Color color;
  const GTerm(this.name, this.def, this.icon, this.color, {this.image = '', this.group = '', this.pictureOnly = false});
  String get plain => def.replaceAll('**', '');
}

// ---------------------------------------------------------------------
// EXPLORE (2 minute animated video, narrated with captions)
// ---------------------------------------------------------------------
class GCap {
  final double t;
  final String text;
  final List<String> labels;
  const GCap(this.t, this.text, this.labels);
}

/// A little picture that moves across the video scene.
/// It flies from (x0,y0) to (x1,y1) between t0 and t1, then stays until `until`.
class GActor {
  final String icon;
  final double x0, y0, x1, y1, t0, t1;
  final double until, size;
  const GActor(this.icon, this.x0, this.y0, this.x1, this.y1, this.t0, this.t1, {this.until = 0, this.size = 40});
  double get end => until > t1 ? until : t1;
}

class GBg {
  final double t;
  final String kind; // cell, mito, krebs, chain
  const GBg(this.t, this.kind);
}

// ---------------------------------------------------------------------
// SIMULATE (drag or tap items into the cell)
// ---------------------------------------------------------------------
class SimItem {
  final String id, label, icon;
  final bool distractor, reusable;
  final int showAfter; // appears in the tray after this many steps are done
  const SimItem(this.id, this.label, this.icon, {this.distractor = false, this.reusable = false, this.showAfter = 0});
}

class SimZone {
  final String id, label;
  final double x, y, w, h; // fractions of the stage panel
  const SimZone(this.id, this.label, this.x, this.y, this.w, this.h);
}

/// kind: 'num' (icon + number), 'bar' (fills up to max), 'flag' (lights up when above 0)
class SimCounter {
  final String id, label, icon, kind, doneText;
  final int max;
  const SimCounter(this.id, this.label, this.icon, {this.kind = 'num', this.max = 1, this.doneText = ''});
}

class SimStep {
  final String item, zone, msg, pop;
  final Map<String, int> fx;
  const SimStep(this.item, this.zone, this.msg, {this.fx = const {}, this.pop = ''});
}

class SimPay {
  final String msg, pop;
  final Map<String, int> fx;
  const SimPay(this.msg, {this.fx = const {}, this.pop = ''});
}

class SimVariant {
  final String name, icon, success;
  final List<SimCounter> counters;
  final List<SimStep> steps;
  final List<SimPay> pay;
  const SimVariant(this.name, this.icon, this.success, this.counters, this.steps, this.pay);
}

class SimDef {
  final String title, instruction, bg, wrong, start;
  final String challengeLabel, challengeMsg;
  final int challengeStep;
  final String chooser; // text shown when there is more than one variant
  final List<SimItem> tray;
  final List<SimZone> zones;
  final List<SimVariant> variants;
  final List<List<int>> requiredVariantGroups;
  const SimDef({
    required this.title,
    required this.instruction,
    required this.bg,
    required this.wrong,
    required this.start,
    required this.tray,
    required this.zones,
    required this.variants,
    this.challengeLabel = '',
    this.challengeMsg = '',
    this.challengeStep = 0,
    this.chooser = '',
    this.requiredVariantGroups = const [],
  });
  bool completedBy(Set<int> completed) => requiredVariantGroups.isEmpty
      ? List<int>.generate(variants.length, (i) => i).every(completed.contains)
      : requiredVariantGroups.every((group) => group.any(completed.contains));
}

// ---------------------------------------------------------------------
// PLAY (three rounds)
// ---------------------------------------------------------------------
class Pair {
  final String term, meaning, icon;
  const Pair(this.term, this.meaning, [this.icon = '']);
}

class StepCard {
  final String text, icon, tip;
  const StepCard(this.text, this.icon, this.tip);
}

class SortCard {
  final String text, icon, tip;
  final int bin;
  const SortCard(this.text, this.icon, this.bin, this.tip);
}

/// Multiple-choice question. `row` lights a row of the side card (-1 = none).
class GQ {
  final String q, hint;
  final List<String> choices;
  final int answer, row;
  final String icon;
  const GQ(this.q, this.choices, this.answer, this.hint, {this.row = -1, this.icon = ''});
}

class CatchItem {
  final String name, icon, tip;
  const CatchItem(this.name, this.icon, this.tip);
}

class VaultLock {
  final String label, clue;
  final int answer;
  const VaultLock(this.label, this.clue, this.answer);
}

class PinItem {
  final String term, clue, icon;
  const PinItem(this.term, this.clue, this.icon);
}

/// kind: scramble, pairs, slots, swap, mc, catch, sort, vault, pin
class RoundSpec {
  final String kind, title, rule;
  final List<Scr> words;
  final List<Pair> pairs;
  final List<StepCard> steps;
  final List<String> slotLabels;
  final bool wheel;
  final List<GQ> qs;
  final String side; // none, bank, chain, case
  final List<String> sideRows, sideVals;
  final String sideTitle;
  final List<CatchItem> good, bad;
  final List<SortCard> cards;
  final List<String> bins;
  final List<VaultLock> locks;
  final List<PinItem> pins;
  const RoundSpec(
    this.kind,
    this.title, {
    this.rule = '',
    this.words = const [],
    this.pairs = const [],
    this.steps = const [],
    this.slotLabels = const [],
    this.wheel = false,
    this.qs = const [],
    this.side = 'none',
    this.sideRows = const [],
    this.sideVals = const [],
    this.sideTitle = '',
    this.good = const [],
    this.bad = const [],
    this.cards = const [],
    this.bins = const [],
    this.locks = const [],
    this.pins = const [],
  });

  /// How many scored items the round has (each is worth 50 coins).
  int get count {
    switch (kind) {
      case 'scramble':
        return words.length;
      case 'pairs':
        return pairs.length;
      case 'slots':
      case 'swap':
        return steps.length;
      case 'picture':
      case 'mc':
        return qs.length;
      case 'catch':
        return good.length;
      case 'sort':
        return cards.length;
      case 'vault':
        return locks.length;
      default:
        return pins.length;
    }
  }
}

// ---------------------------------------------------------------------
// A whole session
// ---------------------------------------------------------------------
class SessionSpec {
  final int no;
  final String hubTitle, learnTitle, exploreTitle, week, doneMsg, loadTip, loadKind, shopName, simSub;
  final bool darkLearn;
  final int fiftyRound;
  final List<GTerm> terms;
  final List<GCap> caps;
  final List<GActor> actors;
  final List<GBg> bgs;
  final String formula;
  final double formulaAt;
  final String quiz, quizAnswer;
  final List<String> quizIcons;
  final SimDef sim;
  final List<RoundSpec> rounds;
  final List<Product> products;
  final bool altHeroes;
  const SessionSpec({
    required this.no,
    required this.hubTitle,
    required this.learnTitle,
    required this.exploreTitle,
    required this.week,
    required this.doneMsg,
    required this.loadTip,
    required this.loadKind,
    required this.shopName,
    required this.simSub,
    required this.terms,
    required this.caps,
    required this.actors,
    required this.bgs,
    required this.formula,
    required this.formulaAt,
    required this.quiz,
    required this.quizAnswer,
    required this.quizIcons,
    required this.sim,
    required this.rounds,
    required this.products,
    this.darkLearn = false,
    this.fiftyRound = 3,
    this.altHeroes = false,
  });
}
