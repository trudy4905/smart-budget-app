import 'package:flutter/material.dart';

// Extension helper
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}

// Number formatting helpers
String formatNumber(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  if (n < 0) buf.write('-');
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String formatCompactNumber(int n) {
  if (n >= 10000) {
    final man = n ~/ 10000;
    final rem = (n % 10000) ~/ 1000;
    return rem > 0 ? '${man}만${rem}천' : '${man}만';
  } else if (n >= 1000) {
    return '${n ~/ 1000}천';
  }
  return n.toString();
}

Color hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
