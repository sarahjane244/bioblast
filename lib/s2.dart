import 'package:flutter/material.dart';
import 'play.dart';
import 'rounds.dart';
import 'revised_map.dart';
class S2SimulateScreen extends StatelessWidget {
 const S2SimulateScreen({super.key});
 @override
 Widget build(BuildContext context) => const RevisedMapScreen();
}
class MatchRoundScreen extends StatelessWidget {
 final MatchState match;
 const MatchRoundScreen({super.key, required this.match});
 @override
 Widget build(BuildContext context) => gRoundScreen(2, 1, match);
}
