import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/instrument.dart';
import '../models/signal.dart';
import 'storage_service.dart';

class ApiResult {
  final bool success;
  final String message;
  final Map<String, dynamic> data;
  ApiResult({required this.success, required this.message, this.data = const {}});
}

class ApiService {
  static Future<ApiResult> signup(String fullName, String email, String password) async {
    final res = await http.post(
      Uri.parse(ApiConfig.signup),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'full_name': fullName, 'email': email, 'password': password}),
    );
    final body = jsonDecode(res.body);
    return ApiResult(success: body['success'] ?? false, message: body['message'] ?? '', data: body);
  }

  static Future<ApiResult> verifySignup(String email, String otp) async {
    final res = await http.post(
      Uri.parse(ApiConfig.verifySignup),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return _handleAuthResponse(res);
  }

  static Future<ApiResult> resendVerification(String email) async {
    final res = await http.post(
      Uri.parse(ApiConfig.resendVerification),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final body = jsonDecode(res.body);
    return ApiResult(success: body['success'] ?? false, message: body['message'] ?? '');
  }

  static Future<ApiResult> login(String email, String password) async {
    final res = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleAuthResponse(res);
  }

  static Future<ApiResult> socialLogin({
    required String provider,
    required String providerUid,
    required String email,
    required String fullName,
  }) async {
    final res = await http.post(
      Uri.parse(ApiConfig.socialLogin),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': provider,
        'provider_uid': providerUid,
        'email': email,
        'full_name': fullName,
      }),
    );
    return _handleAuthResponse(res);
  }

  static Future<ApiResult> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse(ApiConfig.forgotPassword),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    final body = jsonDecode(res.body);
    return ApiResult(success: body['success'] ?? false, message: body['message'] ?? '');
  }

  static Future<ApiResult> resetPassword(String email, String otp, String newPassword) async {
    final res = await http.post(
      Uri.parse(ApiConfig.resetPassword),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp, 'new_password': newPassword}),
    );
    final body = jsonDecode(res.body);
    return ApiResult(success: body['success'] ?? false, message: body['message'] ?? '');
  }

  static Future<ApiResult> changeEmail(String newEmail, String currentPassword) async {
    final token = await StorageService.getToken();
    final res = await http.post(
      Uri.parse(ApiConfig.changeEmail),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'new_email': newEmail, 'current_password': currentPassword}),
    );
    final body = jsonDecode(res.body);
    return ApiResult(success: body['success'] ?? false, message: body['message'] ?? '', data: body);
  }

  static Future<void> logout() async {
    final token = await StorageService.getToken();
    try {
      await http.post(
        Uri.parse(ApiConfig.logout),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (_) {
      // ignore network errors on logout - clear local session regardless
    }
    await StorageService.clearSession();
  }

  static Future<List<Instrument>> getInstruments({String? market}) async {
    final uri = market != null
        ? Uri.parse('${ApiConfig.coinsList}?market=$market')
        : Uri.parse(ApiConfig.coinsList);
    final res = await http.get(uri);
    final body = jsonDecode(res.body);
    if (body['success'] == true) {
      return (body['instruments'] as List).map((e) => Instrument.fromJson(e)).toList();
    }
    return [];
  }

  /// Returns (signal, alreadyClaimedToday, message)
  static Future<Map<String, dynamic>> generateSignal(int instrumentId) async {
    final userId = await StorageService.getUserId();
    final res = await http.post(
      Uri.parse(ApiConfig.generateSignal),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'instrument_id': instrumentId}),
    );
    final body = jsonDecode(res.body);

    if (body['success'] != true) {
      return {'signal': null, 'alreadyClaimed': false, 'message': body['message'] ?? 'Something went wrong'};
    }
    if (body['signal'] == null) {
      return {
        'signal': null,
        'alreadyClaimed': false,
        'message': body['message'] ?? 'No signal available yet',
        'limitReached': body['limit_reached'] ?? false,
      };
    }
    return {
      'signal': TradeSignal.fromJson(body['signal']),
      'alreadyClaimed': body['already_claimed_today'] ?? false,
      'message': '',
    };
  }

  static Future<Map<String, dynamic>> getPlanStatus() async {
    final userId = await StorageService.getUserId();
    final res = await http.get(Uri.parse('${ApiConfig.planStatus}?user_id=$userId'));
    final body = jsonDecode(res.body);
    if (body['success'] != true) {
      return {'plan': 'free', 'dailyLimit': 1, 'usedToday': 0, 'remaining': 1};
    }
    return {
      'plan': body['plan'] ?? 'free',
      'dailyLimit': body['daily_limit'] ?? 1,
      'usedToday': body['used_today'] ?? 0,
      'remaining': body['remaining'] ?? 0,
    };
  }

  static Future<ApiResult> changePlan(String plan) async {
    final userId = await StorageService.getUserId();
    final res = await http.post(
      Uri.parse(ApiConfig.changePlan),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'plan': plan}),
    );
    final body = jsonDecode(res.body);
    return ApiResult(success: body['success'] ?? false, message: body['message'] ?? '');
  }

  /// Returns the list of signals the user has claimed before, newest first.
  static Future<List<TradeSignal>> getSignalHistory({int limit = 50}) async {
    final userId = await StorageService.getUserId();
    final res = await http.get(
      Uri.parse('${ApiConfig.signalHistory}?user_id=$userId&limit=$limit'),
    );
    final body = jsonDecode(res.body);
    if (body['success'] != true) return [];
    return (body['history'] as List).map((e) => TradeSignal.fromJson(e)).toList();
  }

  static ApiResult _handleAuthResponse(http.Response res) {
    final body = jsonDecode(res.body);
    final success = body['success'] ?? false;
    if (success && body['token'] != null) {
      StorageService.saveSession(
        body['token'],
        int.parse(body['user']['id'].toString()),
        body['user']['full_name'] ?? '',
        body['user']['email'] ?? '',
      );
    }
    return ApiResult(success: success, message: body['message'] ?? '', data: body);
  }
}
