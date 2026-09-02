import 'package:stepix/core/api/api_client.dart';
import 'package:stepix/core/api/api_exception.dart';
import 'package:stepix/core/storage/token_store.dart';

/// An [ApiClient] that answers from a canned map instead of a socket.
///
/// Repositories depend on the interface rather than on Dio precisely so a test
/// like this needs no HTTP stack, no platform channel and no running backend.
class FakeApiClient implements ApiClient {
  FakeApiClient(this.responses);

  /// `GET /home` → the `data` member the envelope would have carried.
  final Map<String, dynamic> responses;

  final calls = <String>[];

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => _answer('GET $path');

  @override
  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query}) =>
      _answer('POST $path');

  @override
  Future<dynamic> put(String path, {Object? body}) => _answer('PUT $path');

  @override
  Future<dynamic> delete(String path, {Object? body}) => _answer('DELETE $path');

  @override
  Future<dynamic> upload(String path, {required String field, required String filePath}) =>
      _answer('POST $path');

  Future<dynamic> _answer(String key) async {
    calls.add(key);
    if (!responses.containsKey(key)) {
      // Mirrors the shape a screen sees when the endpoint is missing, so an
      // unstubbed call fails as a rendered error rather than a type crash.
      throw ApiException(message: 'no stub for $key', statusCode: 404, code: 10000);
    }
    return responses[key];
  }
}

/// The `user` + `center` pair `/auth/me` and `/auth/login` both return.
Map<String, dynamic> identityJson({
  String role = 'student',
  bool mustChangePassword = false,
}) =>
    {
      'user': {
        'id': 'u1',
        'role': role,
        'full_name': 'Ali Valiyev',
        'phone': '+998901234567',
        'language': 'uz',
        'must_change_password': mustChangePassword,
      },
      'center': {'id': 'c1', 'name': 'Stepix Center'},
    };

const settingsJson = {
  'min_supported_version': '1.0.0',
  'latest_version': '1.0.0',
  'force_update': false,
};

/// A token pair that only has to exist: the fake client never looks at it, but
/// its presence is what makes [SessionController.restore] call `/auth/me`.
const signedInTokens = AuthTokens(access: 'a', refresh: 'r');
