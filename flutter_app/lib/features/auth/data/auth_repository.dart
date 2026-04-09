import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<AuthResponse> login(String phone, String password) async {
    final response = await _dio.post(ApiConstants.login, data: {
      'phoneNumber': phone,
      'password': password,
    });
    return AuthResponse.fromJson(response.data);
  }

  Future<void> register(String fullName, String phone, String password) async {
    await _dio.post(ApiConstants.register, data: {
      'fullName': fullName,
      'phoneNumber': phone,
      'password': password,
    });
  }
}
