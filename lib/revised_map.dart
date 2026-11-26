import 'package:flutter/material.dart';
import 'art.dart';
import 'common.dart';
import 'gsessions.dart';
import 'play.dart';

/// Simplified learning diagram: numbered targets do not imply physical scale.
class RespirationMapDiagram extends StatelessWidget {
  final Set<int> placed;
  final int? highlight;
  final void Function(int)? onTarget;
  final void Function(int, int)? onDrop;
  const RespirationMapDiagram({super.key, this.placed = const {}, this.highlight, this.onTarget, this.onDrop});
  static const points = <Offset>[
    Offset(10, 18), Offset(330, 18), Offset(16, 108), Offset(200, 130),
    Offset(300, 202), Offset(10, 240), Offset(330, 240), Offset(196, 264),
  ];
  @override
  Widget build(BuildContext context) {
    final terms = specFor(2)!.terms;
    return SizedBox(width: 470, height: 316, child: Stack(children: [
      const Positioned(left: 68, top: 46, child: CellArt(width: 334, height: 226)),
      const Positioned(left: 198, top: 112, child: MitoArt(width: 164, glow: true)),
      const Positioned(left: 68, top: 18, child: Text('Inputs ↓', style: TextStyle(color: cBlue, fontWeight: FontWeight.bold))),
      const Positioned(left: 50, bottom: 4, child: Text('Products leave ↓', style: TextStyle(color: cGreen, fontWeight: FontWeight.bold))),
      for (var i = 0; i < 8; i++) Positioned(left: points[i].dx, top: points[i].dy, width: 132, height: 42,
        child: DragTarget<int>(
          onWillAcceptWithDetails: (_) => onDrop != null && !placed.contains(i),
          onAcceptWithDetails: (d) => onDrop?.call(d.data, i),
          builder: (_, candidates, __) => Semantics(button: onTarget != null, label: 'Target ${i + 1}', child: Pressable(
            onTap: onTarget == null ? null : () => onTarget!(i),
            child: Container(alignment: Alignment.center, padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: placed.contains(i) ? const Color(0xFF17693B) : cPanel.withValues(alpha: .94), borderRadius: BorderRadius.circular(14),
                border: Border.all(color: candidates.isNotEmpty || highlight == i ? Colors.yellowAccent : (placed.contains(i) ? cGreen : cBlue), width: highlight == i ? 4 : 2),
                boxShadow: highlight == i ? [const BoxShadow(color: cBlue, blurRadius: 14)] : null),
              child: Text(placed.contains(i) ? '✓ ${terms[i].name}' : '${i + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
            ),
          )),
        ),
      ),
    ]));
  }
}

class RevisedMapScreen extends StatefulWidget {
  const RevisedMapScreen({super.key});
  @override
  State<RevisedMapScreen> createState() => _RevisedMapState();
}
class _RevisedMapState extends State<RevisedMapScreen> {
  final placed = <int>{};
  int? selected;
  String message = 'Choose a label, then tap its numbered target, or drag it there.';
  bool completed = false;
  static const tips = [
    'Glucose comes from food and provides fuel.', 'Oxygen arrives through breathing and accepts electrons at the end of the chain.',
    'Glycolysis happens in the cytosol.', 'Pyruvate processing and the Krebs cycle happen in the mitochondrial matrix.',
    'The chain and ATP synthase are on the inner membrane.', 'CO₂ leaves during pyruvate processing and Krebs.',
    'Water forms at the end of the chain.', 'ATP powers moving, growing and thinking.',
  ];
  void place(int item, int target) {
    if (placed.contains(target) || placed.contains(item)) return;
    setState(() {
      if (item == target) {
        placed.add(item); selected = null; message = 'Correct! ${tips[item]}';
        if (placed.length == 8) {
          completed = true; Store.mark('sim');
          message = 'Great job! You built the respiration map!';
        }
      } else {
        selected = null;
        message = 'Not quite. Think about where this happens in the cell and try again.';
      }
    });
  }
  void reset() => setState(() {placed.clear(); selected = null; message = 'Choose a label and try again.';});
  Widget tile(int i) {
    final t = specFor(2)!.terms[i];
    Widget body() => Container(height: 37, margin: const EdgeInsets.only(bottom: 3), alignment: Alignment.center,
      decoration: BoxDecoration(color: placed.contains(i) ? const Color(0xFF17693B) : cPanel, borderRadius: BorderRadius.circular(12), border: Border.all(color: selected == i ? Colors.yellowAccent : cBlue, width: 2)),
      child: Text('${placed.contains(i) ? '✓ ' : ''}${t.name}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)));
    return Draggable<int>(data: i, maxSimultaneousDrags: placed.contains(i) ? 0 : 1,
      feedback: Material(color: Colors.transparent, child: SizedBox(width: 180, child: body())),
      childWhenDragging: Opacity(opacity: .3, child: body()),
      child: Pressable(onTap: placed.contains(i) ? null : () => setState(() => selected = i), child: body()));
  }
  @override
  Widget build(BuildContext context) => Stage(child: Column(children: [
    const TopBar(title: 'Build the Respiration Map'),
    const SizedBox(height: 8),
    const Text('Drag each label to the correct part of the cell!', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
    Expanded(child: Row(children: [
      SizedBox(width: 190, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [for (var i = 0; i < 8; i++) tile(i)])),
      const SizedBox(width: 12),
      RespirationMapDiagram(placed: placed, onTarget: (i) {if (selected != null) place(selected!, i);}, onDrop: place),
      const SizedBox(width: 12),
      Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: panelDeco(), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${placed.length}/8 correct', style: const TextStyle(fontSize: 20, color: cGreen, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        for (var i = 0; i < 8; i++) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('${placed.contains(i) ? '✓' : '○'} Target ${i + 1}', style: const TextStyle(fontSize: 14))),
        const Text('Simplified diagram; not to scale.', style: TextStyle(fontSize: 11, color: Colors.white70)),
      ]))),
    ])),
    Padding(padding: const EdgeInsets.all(8), child: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      GlowButton(label: 'Reset', width: 150, onTap: reset), const SizedBox(width: 12),
      GlowButton(label: 'Try Again', width: 170, onTap: reset), const SizedBox(width: 12),
      GlowButton(label: 'Continue to Play', width: 250, locked: !completed, onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PlayStartScreen()))),
    ]), const SizedBox(height: 12),
  ]));
}
