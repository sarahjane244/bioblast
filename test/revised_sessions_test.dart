import 'package:flutter_test/flutter_test.dart';
import 'package:bioblast/gsessions.dart';
import 'package:bioblast/gmodels.dart';

Map<String, int> outputs(SimVariant variant) {
  final values = <String, int>{};
  void apply(Map<String, int> changes) {
    changes.forEach((key, delta) => values[key] = (values[key] ?? 0) + delta);
  }
  for (final step in variant.steps) {apply(step.fx);}
  for (final pay in variant.pay) {apply(pay.fx);}
  return values;
}
void main() {
  test('Revised session order, card counts, and score limits match the documents', () {
    const cards = [22, 8, 8, 10, 8, 8, 3, 8];
    for (var s = 1; s <= 8; s++) {
      final spec = specFor(s)!;
      expect(spec.no, s);
      expect(spec.terms.length, cards[s - 1]);
      expect(spec.rounds.length, 3);
      expect(spec.rounds.fold<int>(0, (sum, round) => sum + round.count) * 50, s == 2 ? 1000 : 850);
      expect(spec.caps.first.t, 0);
      expect(spec.caps.last.t, lessThan(120));
    }
    expect(specFor(3)!.hubTitle, contains('Glycolysis'));
    expect(specFor(4)!.hubTitle, 'Preparing for the Krebs Cycle');
    expect(specFor(7)!.hubTitle, contains('ATP Formation'));
    expect(specFor(8)!.hubTitle, contains('Connecting the Stages'));
  });
  test('Every question has a valid answer and every scramble has the right letter tiles', () {
    for (var s = 1; s <= 8; s++) {
      for (final round in specFor(s)!.rounds) {
        for (final q in round.qs) {
          expect(q.answer, inInclusiveRange(0, q.choices.length - 1));
        }
        for (final word in round.words) {
          final tiles = word.scrambled.split('')..sort();
          final answer = word.answer.split('')..sort();
          expect(tiles, answer);
        }
      }
    }
  });
  test('Glycolysis and pyruvate preparation have the specified outputs', () {
    final glycolysis = outputs(specFor(3)!.sim.variants.single);
    expect(glycolysis['spent'], 2);
    expect(glycolysis['made'], 4);
    expect(glycolysis['net'], 2);
    expect(glycolysis['nadh'], 2);
    expect(glycolysis['pyruvate'], 2);
    final prep = outputs(specFor(4)!.sim.variants.single);
    expect(prep, {'acetyl': 2, 'co2': 2, 'nadh': 2});
    expect(prep['atp'] ?? 0, 0);
  });
  test('Sessions 7–8 require both oxygen modes, with either no-oxygen cell allowed', () {
    for (final s in [7, 8]) {
      final sim = specFor(s)!.sim;
      expect(sim.completedBy({}), isFalse);
      expect(sim.completedBy({0}), isFalse);
      expect(sim.completedBy({1, 2}), isFalse);
      expect(sim.completedBy({0, 1}), isTrue);
      expect(sim.completedBy({0, 2}), isTrue);
      expect(sim.completedBy({0, 1, 2}), isTrue);
    }
  });
  test('Carbon and ATP totals distinguish aerobic respiration from fermentation', () {
    for (final s in [7, 8]) {
      final variants = specFor(s)!.sim.variants;
      final aerobic = outputs(variants[0]);
      expect(aerobic['co2'], 6);
      expect(aerobic['net'], inInclusiveRange(30, 32));
      expect(aerobic['nadh'], 0);
      expect(aerobic['fadh2'], 0);
      for (final variant in variants.skip(1)) {
        final anaerobic = outputs(variant);
        expect(anaerobic['net'], 2);
        expect(anaerobic['made'], 4); // Made by glycolysis, before subtracting its 2 ATP cost.
        expect(anaerobic['nad'], 2);
        expect(variant.steps.last.fx.containsKey('net'), isFalse); // Fermentation adds no ATP.
      }
    }
  });
}
