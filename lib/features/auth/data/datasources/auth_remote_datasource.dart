import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthResponse> login({
    required String email,
    required String password,
  });

  Future<AuthResponse> register({
    required String email,
    required String password,
    String? name,
  });

  /// Best-effort server-side logout; never throws.
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) =>
      _postAuth(ApiConstants.login, {'email': email, 'password': password});

  @override
  Future<AuthResponse> register({
    required String email,
    required String password,
    String? name,
  }) =>
      _postAuth(ApiConstants.register, {
        'email': email,
        'password': password,
        'name': ?name,
      });

  @override
  Future<void> logout() async {
    try {
      await _dioClient.post<void>(ApiConstants.logout);
    } on Exception {
      // Local data is cleared regardless; a failed server logout is harmless.
    }
  }

  /// Network and server errors from [DioClient] propagate unchanged; a body
  /// that doesn't match [AuthResponse] becomes a [ParseException].
  Future<AuthResponse> _postAuth(String path, Map<String, dynamic> body) async {
    final response = await _dioClient.post<Map<String, dynamic>>(
      path,
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw const ServerException(message: 'Empty response from server');
    }
    try {
      return AuthResponse.fromJson(data);
    } on Object catch (e) {
      throw ParseException(message: 'Invalid auth response: $e');
    }
  }
}
