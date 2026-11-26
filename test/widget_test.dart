import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bioblast/main.dart';

void main() {
  test('BioBlast root widget is available', () {
    expect(const BioBlastApp(), isA<StatelessWidget>());
  });
}
