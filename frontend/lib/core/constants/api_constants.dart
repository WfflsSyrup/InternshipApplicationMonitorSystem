class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  static const String reminders = '/automation/reminders';
  static const String incompleteRecords = '/automation/incomplete-records';
  static const String escalations = '/automation/escalations';
  static const String weeklySummaries = '/automation/weekly-summary';

  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(milliseconds: 250);
  static const Duration maxRetryDelay = Duration(seconds: 4);
  static const double retryMultiplier = 2.0;
  static const Duration receiveTimeout = Duration(seconds: 10);
}
