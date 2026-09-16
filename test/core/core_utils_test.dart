import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stepix/core/api/api_exception.dart';
import 'package:stepix/core/api/envelope.dart';
import 'package:stepix/core/session/settings_controller.dart';
import 'package:stepix/core/storage/token_store.dart';
import 'package:stepix/core/util/json.dart';
import 'package:stepix/data/repositories/profile_repository.dart';
import 'package:stepix/features/profile/notification_target.dart';
import 'package:stepix/l10n/strings.dart';

import '../fake_api_client.dart';

void main() {
  group('json readers', () {
    test('numbers, strings and bools are read leniently', () {
      expect(asInt('12'), 12);
      expect(asInt(3.6), 4);
      expect(asInt('x', 7), 7);
      expect(asIntOrNull(null), isNull);
      expect(asIntOrNull('nope'), isNull);
      expect(asDouble('0.25'), 0.25);
      expect(asBool(1), isTrue);
      expect(asBool('1'), isTrue);
      expect(asBool('yes'), isFalse);
      expect(asBool(null, true), isTrue);
      expect(asString(null, 'd'), 'd');
      expect(asStringOrNull(''), isNull);
    });

    test('collections drop what is not the right shape', () {
      expect(asMap([1]), isEmpty);
      expect(asMapList([{'a': 1}, 'x', 2]), hasLength(1));
      expect(mapList(null, (m) => m), isEmpty);
      expect(asStringList([1, 'a']), ['1', 'a']);
      expect(asIntList(['2', 'x']), [2, -1]);
      expect(asIntList('x'), isEmpty);
    });

    test('dates parse to local time and junk is null', () {
      final d = asDate('2026-09-15T10:00:00Z')!;
      expect(d.isUtc, isFalse);
      expect(d.toUtc().hour, 10);
      expect(asDate('not a date'), isNull);
    });
  });

  group('envelope', () {
    test('success needs code 0 and a 2xx status', () {
      expect(Envelope.fromJson({'statusCode': 200, 'code': 0, 'data': 1}).isSuccess, isTrue);
      expect(Envelope.fromJson({'statusCode': 200, 'code': 20105}).isSuccess, isFalse);
      expect(Envelope.fromJson({'statusCode': '404', 'code': 0}).isSuccess, isFalse);
    });

    test('an error envelope becomes an exception with the HTTP status', () {
      final e = Envelope.fromJson({'statusCode': 400, 'code': 20802, 'message': 'm', 'path': '/p'})
          .toException(httpStatus: 409);
      expect(e.statusCode, 409);
      expect(e.code, 20802);
      expect(e.path, '/p');
      expect(e.block, 20800);
    });

    test('a page reads a paged map, a bare list and anything else as empty', () {
      final paged = Page.fromJson({'total': '9', 'data': [{'id': 1}]}, (m) => m['id']);
      expect(paged.total, 9);
      expect(paged.items, [1]);
      expect(Page.fromJson({'data': 'x'}, (m) => m).items, isEmpty);
      expect(Page.fromJson(42, (m) => m).isEmpty, isTrue);
    });
  });

  group('api exception', () {
    test('only a refreshable 401 counts as unauthenticated', () {
      expect(ApiException(message: '', statusCode: 401, code: 20104).isUnauthenticated, isTrue);
      expect(ApiException(message: '', statusCode: 401, code: 20105).isUnauthenticated, isFalse);
      expect(ApiException(message: '', statusCode: 401, code: 20110).isUnauthenticated, isFalse);
      expect(ApiException(message: '', statusCode: 403, code: 20106).isLockedOut, isTrue);
      expect(ApiException(message: '', code: 20103).isRefreshRejected, isTrue);
      expect(ApiException.network('x').isNetwork, isTrue);
      expect(ApiException.network('x').block, 0);
    });
  });

  group('token store', () {
    test('the in-memory store writes, reads and clears', () async {
      final store = InMemoryTokenStore();
      expect(await store.read(), isNull);
      await store.write(const AuthTokens(access: 'a', refresh: 'r'));
      expect((await store.read())!.refresh, 'r');
      await store.clear();
      expect(await store.read(), isNull);
    });

    test('a token with a past expiry is expired, one without never is', () {
      expect(
        AuthTokens(access: 'a', refresh: 'r', expiresAt: DateTime.now().subtract(const Duration(seconds: 1)))
            .isExpired,
        isTrue,
      );
      expect(const AuthTokens(access: 'a', refresh: 'r').isExpired, isFalse);
    });
  });

  group('settings controller', () {
    test('force update is false until the answer is in, then obeys it', () async {
      final api = FakeApiClient({'GET /settings': {...settingsJson, 'force_update': true}});
      final c = SettingsController(ProfileRepository(api));
      expect(c.forceUpdate, isFalse);
      await c.ensureLoaded();
      expect(c.forceUpdate, isTrue);
      await c.ensureLoaded();
      expect(api.calls.where((x) => x == 'GET /settings'), hasLength(1));
      c.clear();
      expect(c.settings, isNull);
    });

    test('an unreachable settings endpoint never walls the app', () async {
      final api = FakeApiClient({'GET /settings': ApiException.network('offline')});
      final c = SettingsController(ProfileRepository(api));
      await c.reload();
      expect(c.forceUpdate, isFalse);
      expect(c.settings, isNull);
    });
  });

  group('notification target', () {
    test('students go to the test or its result, teachers to the test detail', () {
      expect(notificationTarget('test_assigned', 't1', teacher: false), '/student/test/t1');
      expect(notificationTarget('test_due_soon', 't1', teacher: false), '/student/test/t1');
      expect(notificationTarget('test_graded', 't1', teacher: false), '/student/test/t1/result');
      expect(notificationTarget('test_failed', 't1', teacher: false), '/student/test/t1/result');
      expect(notificationTarget('test_assigned', 't1', teacher: true), '/teacher/test/t1');
      expect(notificationTarget('test_graded', 't1', teacher: true), '/teacher/test/t1');
    });

    test('informational notifications and missing refs lead nowhere', () {
      expect(notificationTarget('test_due_soon', 't1', teacher: true), isNull);
      expect(notificationTarget('invoice_paid', 'i1', teacher: false), isNull);
      expect(notificationTarget('test_assigned', null, teacher: false), isNull);
      expect(notificationTarget('test_assigned', '', teacher: false), isNull);
    });
  });

  group('strings', () {
    final source = File('lib/l10n/strings.dart').readAsStringSync();

    Map<String, Set<String>> tables() {
      final out = <String, Set<String>>{};
      final starts = {
        for (final lang in S.supported) lang: source.indexOf("    '$lang': {"),
      };
      final ordered = starts.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
      for (var i = 0; i < ordered.length; i++) {
        final end = i + 1 < ordered.length ? ordered[i + 1].value : source.indexOf('class StringsDelegate');
        final body = source.substring(ordered[i].value, end);
        // The body starts at the table's own `'uz': {` line, which is not a key.
        out[ordered[i].key] = RegExp(r"^\s*'([a-z0-9_]+)':", multiLine: true)
            .allMatches(body.substring(body.indexOf('{') + 1))
            .map((m) => m.group(1)!)
            .toSet();
      }
      return out;
    }

    test('every language carries exactly the same keys', () {
      final t = tables();
      expect(t['uz'], isNotEmpty);
      for (final lang in ['ru', 'en']) {
        expect(t['uz']!.difference(t[lang]!), isEmpty, reason: 'missing in $lang');
        expect(t[lang]!.difference(t['uz']!), isEmpty, reason: 'extra in $lang');
      }
    });

    test('every getter reads a key the tables define', () {
      final keys = tables()['uz']!;
      final used = RegExp(r"_t\('([a-z0-9_]+)'\)").allMatches(source).map((m) => m.group(1)!).toSet();
      expect(used.difference(keys), isEmpty);
    });

    test('dynamic keys resolve for every badge, weekday, state and error type', () {
      for (final lang in S.supported) {
        final s = S(lang);
        for (final code in ['first_test', 'tests_5', 'tests_20', 'score_90', 'flawless', 'top3']) {
          expect(s.badge(code), isNot('badge_$code'));
        }
        for (var d = 1; d <= 7; d++) {
          expect(s.weekdayShort(d), isNot(startsWith('wd_')));
        }
        for (final st in ['waiting', 'analyzing', 'done', 'failed', null]) {
          expect(s.solutionStateLabel(st), isNot(startsWith('solution_state_')));
        }
        for (final e in ['none', 'calculation', 'formula', 'concept', 'units', 'misread', 'incomplete', 'no_work']) {
          expect(s.solutionErrorType(e), isNot(startsWith('solution_error_')));
        }
        for (final w in ['full', 'partial', 'none']) {
          expect(s.solutionWork(w), isNot(startsWith('solution_work_')));
        }
      }
    });

    test('an unsupported language and an unknown key fall back', () {
      expect(S('de').tabHome, S('uz').tabHome);
      expect(S('ru').unansweredBody(3), contains('3'));
      expect(S('uz').weekdayShort(8), S('uz').weekdayShort(1));
    });
  });
}
