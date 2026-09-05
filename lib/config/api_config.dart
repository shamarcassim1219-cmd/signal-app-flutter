class ApiConfig {
  // TODO: ඔයාගේ actual cPanel Node.js App domain එකට මාරු කරන්න
  static const String baseUrl = 'https://finbassshamar.online/api';

  static const String signup = '$baseUrl/auth/signup';
  static const String verifySignup = '$baseUrl/auth/verify-signup';
  static const String resendVerification = '$baseUrl/auth/resend-verification';
  static const String login = '$baseUrl/auth/login';
  static const String socialLogin = '$baseUrl/auth/social-login';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String resetPassword = '$baseUrl/auth/reset-password';
  static const String logout = '$baseUrl/auth/logout';
  static const String changeEmailRequestOtp = '$baseUrl/auth/change-email/request-otp';
  static const String changeEmailVerifyOtp = '$baseUrl/auth/change-email/verify-otp';
  static const String updateMobile = '$baseUrl/auth/mobile/update';
  static const String coinsList = '$baseUrl/coins';
  static const String generateSignal = '$baseUrl/signal/generate';
  static const String planStatus = '$baseUrl/user/plan-status';
  static const String changePlan = '$baseUrl/user/change-plan';
  static const String signalHistory = '$baseUrl/user/history';
}
