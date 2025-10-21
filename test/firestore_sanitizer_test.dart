import 'package:flutter_test/flutter_test.dart';
import 'package:nextwave/utils/firestore_sanitizer.dart';

void main() {
  test('safeParseInt returns fallback for Infinity/NaN', () {
    expect(safeParseInt(double.infinity, fallback: 7), equals(7));
    expect(safeParseInt(double.nan, fallback: 3), equals(3));
    expect(safeParseInt(null, fallback: 5), equals(5));
    expect(safeParseInt(42, fallback: 0), equals(42));
    expect(safeParseInt(42.9, fallback: 0), equals(42));
    expect(safeParseInt('123', fallback: 0), equals(123));
    expect(safeParseInt('12.9', fallback: 0), equals(12));
  });

  test('safeParseDouble handles NaN/Infinity', () {
    expect(safeParseDouble(double.infinity, fallback: 2.5), equals(2.5));
    expect(safeParseDouble('3.14', fallback: 0.0), closeTo(3.14, 1e-9));
  });

  test('sanitizeForFirestore replaces non-finite numbers', () {
    final raw = {
      'streams': double.infinity,
      'nested': {'x': double.nan, 'y': 5},
      'list': [1, double.infinity, {'v': double.nan}],
      'ok': 'value'
    };

    final sanitized = sanitizeForFirestore(Map<String, dynamic>.from(raw));

    expect(sanitized['streams'], equals(0));
    expect((sanitized['nested'] as Map)['x'], equals(0));
    expect((sanitized['nested'] as Map)['y'], equals(5));
    expect((sanitized['list'] as List)[1], equals(0));
    expect(((sanitized['list'] as List)[2] as Map)['v'], equals(0));
    expect(sanitized['ok'], equals('value'));
  });
}
