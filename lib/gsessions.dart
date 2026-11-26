import 'gdata_a.dart';
import 'gdata_b.dart';
import 'gdata_c.dart';
import 'revised_intro.dart';
import 'revised_prep.dart';
import 'gmodels.dart';

/// Revised Session 1–8 documents, in the client's requested order.
SessionSpec? specFor(int s) => switch (s) {
  1 => session1, 2 => session2, 3 => session3, 4 => session4,
  5 => session5, 6 => session6, 7 => session7, 8 => session8,
  _ => null,
};
bool isGeneric(int s) => s >= 1 && s <= 8;
