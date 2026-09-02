/// Lenient readers for the API's JSON.
///
/// Every field the server marks nullable really can be null, and a few — score
/// on an unfinished test, every analytic on a `state: "new"` student — are null
/// by design. Parsing defensively here keeps that out of every model.
Map<String, dynamic> asMap(dynamic v) => v is Map<String, dynamic> ? v : const {};

List<Map<String, dynamic>> asMapList(dynamic v) =>
    v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];

List<T> mapList<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
    asMapList(v).map(f).toList();

String asString(dynamic v, [String fallback = '']) => v == null ? fallback : v.toString();

String? asStringOrNull(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

int asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse('$v') ?? fallback;
}

int? asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse('$v');
}

double asDouble(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? fallback;
}

bool asBool(dynamic v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v == 'true' || v == '1';
  return fallback;
}

DateTime? asDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString())?.toLocal();
}

List<String> asStringList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];
