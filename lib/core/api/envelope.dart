import 'api_exception.dart';

/// The `TransformInterceptor` envelope every 2xx response is wrapped in.
///
/// ```json
/// { "statusCode": 200, "code": 0, "message": "ok", "data": { }, "time": "…" }
/// ```
class Envelope {
  const Envelope({
    required this.statusCode,
    required this.code,
    required this.message,
    required this.data,
    this.time,
    this.path,
  });

  factory Envelope.fromJson(Map<String, dynamic> json) => Envelope(
        statusCode: _int(json['statusCode']),
        code: _int(json['code']),
        message: json['message']?.toString() ?? '',
        data: json['data'],
        time: json['time']?.toString(),
        path: json['path']?.toString(),
      );

  final int statusCode;
  final int code;
  final String message;
  final dynamic data;
  final String? time;
  final String? path;

  bool get isSuccess => code == 0 && statusCode >= 200 && statusCode < 300;

  ApiException toException({int? httpStatus}) => ApiException(
        message: message,
        statusCode: httpStatus ?? statusCode,
        code: code,
        path: path,
      );

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

/// The paging shape nested inside `data`: `{ "total": 84, "data": [ … ] }`.
class Page<T> {
  const Page({required this.total, required this.items});

  const Page.empty() : total = 0, items = const [];

  factory Page.fromJson(dynamic json, T Function(Map<String, dynamic>) item) {
    if (json is List) {
      // A few endpoints return a bare array where the envelope would allow a
      // page. Treating it as a full single page keeps one call site.
      final items = json.whereType<Map<String, dynamic>>().map(item).toList();
      return Page(total: items.length, items: items);
    }
    if (json is Map<String, dynamic>) {
      final raw = json['data'];
      final items = raw is List
          ? raw.whereType<Map<String, dynamic>>().map(item).toList()
          : <T>[];
      return Page(total: Envelope._int(json['total'] ?? items.length), items: items);
    }
    return Page<T>.empty();
  }

  final int total;
  final List<T> items;

  bool get isEmpty => items.isEmpty;
}
