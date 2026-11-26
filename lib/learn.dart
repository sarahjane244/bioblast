import 'package:flutter/material.dart';
import 'gen_ui.dart';

/// Compatibility route to the revised session content.
class LearnScreen extends StatelessWidget {
  final int session;
  const LearnScreen({super.key, this.session = 1});
  @override
  Widget build(BuildContext context) => GenLearnScreen(session: session);
}
