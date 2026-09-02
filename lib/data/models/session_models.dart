import 'dart:ui' show Color;

import '../../core/util/json.dart';

enum UserRole {
  student,
  teacher;

  static UserRole parse(dynamic v) =>
      asString(v) == 'teacher' ? UserRole.teacher : UserRole.student;

  bool get isTeacher => this == UserRole.teacher;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    required this.fullName,
    required this.phone,
    required this.language,
    this.avatarUrl,
    this.mustChangePassword = false,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: asString(j['id']),
        role: UserRole.parse(j['role']),
        fullName: asString(j['full_name']),
        phone: asString(j['phone']),
        language: asString(j['language'], 'uz'),
        avatarUrl: asStringOrNull(j['avatar_url']),
        mustChangePassword: asBool(j['must_change_password']),
      );

  final String id;
  final UserRole role;
  final String fullName;
  final String phone;
  final String language;
  final String? avatarUrl;

  /// While true the client blocks every screen but "change password".
  final bool mustChangePassword;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  String get initials => initialsOf(fullName);

  AppUser copyWith({String? fullName, String? language, String? avatarUrl, bool? mustChangePassword}) =>
      AppUser(
        id: id,
        role: role,
        fullName: fullName ?? this.fullName,
        phone: phone,
        language: language ?? this.language,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      );
}

/// The center the user belongs to — and the source of the app's colours.
class CenterBrand {
  const CenterBrand({
    required this.id,
    required this.name,
    this.logoUrl,
    this.brandPrimary,
    this.brandDark,
  });

  factory CenterBrand.fromJson(Map<String, dynamic> j) => CenterBrand(
        id: asString(j['id']),
        name: asString(j['name']),
        logoUrl: asStringOrNull(j['logo_url']),
        brandPrimary: parseHexColor(j['brand_primary']),
        brandDark: parseHexColor(j['brand_dark']),
      );

  final String id;
  final String name;
  final String? logoUrl;
  final Color? brandPrimary;
  final Color? brandDark;
}

/// `/auth/login` and `/auth/me` return the same `user` + `center` pair.
class Identity {
  const Identity({required this.user, this.center});

  factory Identity.fromJson(Map<String, dynamic> j) => Identity(
        user: AppUser.fromJson(asMap(j['user'])),
        center: j['center'] == null ? null : CenterBrand.fromJson(asMap(j['center'])),
      );

  final AppUser user;
  final CenterBrand? center;

  Identity copyWith({AppUser? user, CenterBrand? center}) =>
      Identity(user: user ?? this.user, center: center ?? this.center);
}

/// `#1f63d6` → [Color]. Returns null for anything that is not a hex triple or
/// quad, so a center with a typo'd brand colour falls back to Stepix blue
/// instead of painting the app transparent.
Color? parseHexColor(dynamic value) {
  final raw = asStringOrNull(value);
  if (raw == null) return null;
  var hex = raw.trim().replaceFirst('#', '');
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length == 6) hex = 'ff$hex';
  if (hex.length != 8) return null;
  final v = int.tryParse(hex, radix: 16);
  return v == null ? null : Color(v);
}

/// "Ali Valiyev" → "AV". One letter for a single-word name, empty for none.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first.characters1();
  return '${parts.first.characters1()}${parts[1].characters1()}';
}

extension on String {
  String characters1() => isEmpty ? '' : substring(0, 1).toUpperCase();
}
