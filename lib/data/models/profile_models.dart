import '../../core/util/json.dart';
import 'session_models.dart';

/// `GET /profile`. Editable: name, language, avatar. Not editable: phone, role,
/// center, group membership — those belong to the center.
class UserProfile {
  const UserProfile({
    required this.user,
    this.centerName,
    this.groupsCount = 0,
    this.testsTaken = 0,
    this.avgScore,
    this.streakDays = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    final userJson = j['user'] is Map<String, dynamic> ? asMap(j['user']) : j;
    return UserProfile(
      user: AppUser.fromJson(userJson),
      centerName: asStringOrNull(j['center_name'] ?? asMap(j['center'])['name']),
      groupsCount: asInt(j['groups_count']),
      testsTaken: asInt(j['tests_taken']),
      avgScore: asIntOrNull(j['avg_score']),
      streakDays: asInt(j['streak_days']),
    );
  }

  final AppUser user;
  final String? centerName;
  final int groupsCount;
  final int testsTaken;
  final int? avgScore;
  final int streakDays;
}

class NotificationFeed {
  const NotificationFeed({required this.total, required this.unread, required this.items});

  factory NotificationFeed.fromJson(Map<String, dynamic> j) => NotificationFeed(
        total: asInt(j['total']),
        unread: asInt(j['unread']),
        items: mapList(j['data'], AppNotification.fromJson),
      );

  const NotificationFeed.empty() : total = 0, unread = 0, items = const [];

  final int total;
  final int unread;
  final List<AppNotification> items;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.refId,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: asString(j['id']),
        type: asString(j['type']),
        title: asString(j['title']),
        body: asString(j['body']),
        isRead: asBool(j['is_read']),
        refId: asStringOrNull(j['ref_id']),
        createdAt: asDate(j['created_at']),
      );

  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String? refId;
  final DateTime? createdAt;
}

/// `GET /settings`.
///
/// `force_update` is decided server-side from `X-App-Version`; letting the
/// client compare version strings means shipping the fix in a build that is
/// already too old to install.
class AppSettings {
  const AppSettings({
    required this.minSupportedVersion,
    required this.latestVersion,
    required this.forceUpdate,
    this.supportTelegram,
    this.offerPdfUrl,
    this.privacyPdfUrl,
  });

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        minSupportedVersion: asString(j['min_supported_version']),
        latestVersion: asString(j['latest_version']),
        forceUpdate: asBool(j['force_update']),
        supportTelegram: asStringOrNull(j['support_telegram']),
        offerPdfUrl: asStringOrNull(j['offer_pdf_url']),
        privacyPdfUrl: asStringOrNull(j['privacy_pdf_url']),
      );

  final String minSupportedVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String? supportTelegram;
  final String? offerPdfUrl;
  final String? privacyPdfUrl;
}

/// `GET /subscription` — Model B centers only.
///
/// `required: false` for every student in a deposit-model center, and the
/// client hides the whole section: their center already paid.
class Subscription {
  const Subscription({
    required this.required_,
    required this.status,
    this.planName,
    this.price,
    this.expiresAt,
    this.graceUntil,
  });

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        required_: asBool(j['required']),
        status: asString(j['status'], 'none'),
        planName: asStringOrNull(j['plan_name']),
        price: asIntOrNull(j['price']),
        expiresAt: asDate(j['expires_at']),
        graceUntil: asDate(j['grace_until']),
      );

  final bool required_;
  final String status;
  final String? planName;
  final int? price;
  final DateTime? expiresAt;
  final DateTime? graceUntil;

  /// A `past_due` subscription blocks nothing for seven days — the client shows
  /// a banner, not a wall.
  bool get inGrace =>
      status == 'past_due' && graceUntil != null && DateTime.now().isBefore(graceUntil!);

  bool get isActive => status == 'active';
}

class CheckoutSession {
  const CheckoutSession({required this.paymentUrl, required this.transactionId});

  factory CheckoutSession.fromJson(Map<String, dynamic> j) => CheckoutSession(
        paymentUrl: asString(j['payment_url']),
        transactionId: asString(j['transaction_id']),
      );

  final String paymentUrl;
  final String transactionId;
}
