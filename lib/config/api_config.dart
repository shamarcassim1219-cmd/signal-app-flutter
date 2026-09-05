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
  static const String changeEmail = '$baseUrl/auth/change-email';
  static const String coinsList = '$baseUrl/coins';
  static const String generateSignal = '$baseUrl/signal/generate';
}
