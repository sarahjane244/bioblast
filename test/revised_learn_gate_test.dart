import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bioblast/common.dart';
import 'package:bioblast/gen_ui.dart';

void main() {
  testWidgets('Visiting the last card does not bypass the flip-every-card rule', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: GenLearnScreen(session: 1)));
    final next = find.byKey(const ValueKey('revised_card_next'));
    final card = find.byKey(const ValueKey('revised_flip_card'));
    final continueButton = find.byKey(const ValueKey('revised_learn_continue'));
    for (var i = 0; i < 21; i++) {
      await tester.tap(next);
      await tester.pump();
    }
    await tester.tap(card);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<GlowButton>(continueButton).locked, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('All 22 flipped cards unlock Explore', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: GenLearnScreen(session: 1)));
    final next = find.byKey(const ValueKey('revised_card_next'));
    final card = find.byKey(const ValueKey('revised_flip_card'));
    final continueButton = find.byKey(const ValueKey('revised_learn_continue'));
    for (var i = 0; i < 22; i++) {
      expect(tester.widget<GlowButton>(continueButton).locked, isTrue);
      await tester.tap(card);
      await tester.pump(const Duration(milliseconds: 500));
      if (i < 21) {
        await tester.tap(next);
        await tester.pump();
      }
    }
    expect(tester.widget<GlowButton>(continueButton).locked, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
