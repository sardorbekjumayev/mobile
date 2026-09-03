import 'package:flutter_test/flutter_test.dart';
import 'package:stepix/core/api/api_exception.dart';

/// The API answers `401` for four different situations and `403` for two more.
/// Only two of the six are fixed by a new token, and treating the others as an
/// expired session is what logged users out mid-typo.
void main() {
  ApiException at(int status, int code) =>
      ApiException(message: 'x', statusCode: status, code: code);

  test('a missing or expired token is the only refreshable 401', () {
    expect(at(401, ErrorCodes.unauthorized).isUnauthenticated, isTrue);
    expect(at(401, ErrorCodes.tokenExpired).isUnauthenticated, isTrue);
  });

  test('a wrong password is not an expired session', () {
    final e = at(401, ErrorCodes.wrongCredentials);
    expect(e.isUnauthenticated, isFalse);
    expect(e.isWrongCredentials, isTrue);
  });

  test('a center admin in the student app cannot be refreshed into one', () {
    expect(at(401, ErrorCodes.wrongRoleForApp).isUnauthenticated, isFalse);
  });

  test('a block and a suspension are walls, not logouts', () {
    expect(at(403, ErrorCodes.userBlocked).isLockedOut, isTrue);
    expect(at(403, ErrorCodes.centerSuspended).isLockedOut, isTrue);
    expect(at(403, ErrorCodes.userBlocked).isUnauthenticated, isFalse);
  });

  test('a failure that never reached the API carries no business code', () {
    final e = ApiException.network('Internet aloqasi yo\'q.');
    expect(e.isNetwork, isTrue);
    expect(e.isUnauthenticated, isFalse);
  });
}
