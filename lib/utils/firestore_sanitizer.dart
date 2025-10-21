import 'package:cloud_firestore/cloud_firestore.dart';

// Utility methods to safely parse numeric values from dynamic Firestore data
// and sanitize maps before writing back to Firestore. Prevents NaN/Infinity
// values from reaching .toInt() conversions or being written to the DB.

int safeParseInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.isFinite ? value.toInt() : fallback;
  if (value is num) return value.isFinite ? value.toInt() : fallback;
  if (value is String) {
    final intVal = int.tryParse(value);
    if (intVal != null) return intVal;
    final dbl = double.tryParse(value);
    if (dbl != null && dbl.isFinite) return dbl.toInt();
  }
  return fallback;
}

double safeParseDouble(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is double) return value.isFinite ? value : fallback;
  if (value is int) return value.toDouble();
  if (value is num) return value.isFinite ? value.toDouble() : fallback;
  if (value is String) {
    final dbl = double.tryParse(value);
    if (dbl != null && dbl.isFinite) return dbl;
  }
  return fallback;
}

Map<String, int> safeParseIntMap(Map? raw, {int fallback = 0}) {
  if (raw == null) return {};
  final out = <String, int>{};
  raw.forEach((k, v) {
    out[k.toString()] = safeParseInt(v, fallback: fallback);
  });
  return out;
}

/// Recursively sanitize a map to ensure numeric values are finite and safe
/// to write to Firestore. Non-finite numbers are replaced with sensible
/// fallback values (0). Lists and nested maps are sanitized recursively.
Map<String, dynamic> sanitizeForFirestore(Map<String, dynamic> input) {
  final Map<String, dynamic> out = {};

  dynamic sanitize(dynamic v) {
    if (v == null) return null;
    if (v is num) {
      if (v.isFinite) return v;
      return 0; // Replace NaN/Infinity with 0
    }
    if (v is String) return v;
    if (v is bool) return v;
    if (v is Timestamp) return v;
    if (v is DateTime) return v;
    if (v is Map) {
      return sanitizeForFirestore(Map<String, dynamic>.from(v));
    }
    if (v is List) {
      return v.map((e) => sanitize(e)).toList();
    }
    return v;
  }

  input.forEach((key, val) {
    out[key] = sanitize(val);
  });

  return out;
}
