class ApiConstants {
  static const String baseUrl = 'http://localhost:8000/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String session = '/auth/session';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Resources
  static const String leads = '/leads/public';
  static const String quotes = '/quotations';
  static const String jobs = '/jobs';
  static const String inventory = '/inventory';
  static const String storage = '/storage';
  static const String invoices = '/finance/invoices';
  static const String tickets = '/support/tickets';
  static const String claims = '/support/claims';
  static const String notifications = '/notifications';
  static const String documents = '/customers';
}
