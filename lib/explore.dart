import 'package:flutter/material.dart';
import 'gen_ui.dart';

/// Compatibility route to the revised session content.
class ExploreScreen extends StatelessWidget {
  final int session;
  const ExploreScreen({super.key, this.session = 1});
  @override
  Widget build(BuildContext context) => GenExploreScreen(session: session);
}
