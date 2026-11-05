import 'dart:convert';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/token_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    String currency = 'INR',
  }) async {
    final res = await ApiClient.post(
      ApiConstants.register,
      body: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'currency': currency,
      },
    );
    return UserModel.fromJson(res);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.post(
      ApiConstants.login,
      body: {
        'email': email,
        'password': password,
      },
    );
    final token = res['access_token'];
    final user = UserModel.fromJson(res['user']);

    await TokenStorage.saveToken(token);
    await TokenStorage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  Future<UserModel> getCurrentUser() async {
    final res = await ApiClient.get(ApiConstants.me);
    final user = UserModel.fromJson(res);
    await TokenStorage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  Future<UserModel> updateProfile({
    String? fullName,
    String? currency,
    String? email,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (currency != null) body['currency'] = currency;
    if (email != null) body['email'] = email;

    final res = await ApiClient.put(ApiConstants.me, body: body);
    final user = UserModel.fromJson(res);
    await TokenStorage.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.post(
      ApiConstants.changePassword,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  Future<void> logout() async {
    try {
      await ApiClient.post(ApiConstants.logout);
    } catch (_) {}
    await TokenStorage.clear();
  }
}

