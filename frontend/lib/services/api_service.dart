import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../models/application_model.dart';
import '../models/escalation_model.dart';
import '../models/incomplete_record_model.dart';
import '../models/reminder_model.dart';
import '../models/weekly_summary_model.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Random _random = Random();
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  Future<List<ApplicationModel>> getApplications() async {
    final data = await _getList('/applications');
    return data.map(ApplicationModel.fromJson).toList();
  }

  Future<void> updateWorkflow(
    String applicationId, {
    required String stage,
    String? interviewStatus,
  }) async {
    final body = <String, String>{'stage': stage};
    if (interviewStatus != null) {
      body['interview_status'] = interviewStatus;
    }

    await _patch('/applications/$applicationId/workflow', body);
  }

  Future<void> completeMilestone(String milestoneId) =>
      _patch('/milestones/$milestoneId/complete');

  Future<void> resolveIncompleteRecord(String recordId) =>
      _patch('/incomplete-records/$recordId/resolve');

  Future<void> _patch(
    String endpoint, [
    Map<String, String> body = const {},
  ]) async {
    try {
      final response = await _client
          .patch(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _isConnected = true;
        throw _exceptionForResponse(response);
      }
      _isConnected = true;
    } on TimeoutException {
      _isConnected = false;
      throw const ApiException(
        'The server did not respond. Check the application status before trying again.',
        isNetworkError: true,
        isRecoverable: true,
      );
    } on http.ClientException {
      _isConnected = false;
      throw const ApiException(
        'Unable to reach the server. Check your connection and try again.',
        isNetworkError: true,
        isRecoverable: true,
      );
    }
  }

  Future<List<ReminderModel>> getReminders() async {
    final data = await _getList(ApiConstants.reminders);
    return data.map(ReminderModel.fromJson).toList();
  }

  Future<List<IncompleteRecordModel>> getIncompleteRecords() async {
    final data = await _getList(ApiConstants.incompleteRecords);
    return data.map(IncompleteRecordModel.fromJson).toList();
  }

  Future<List<EscalationModel>> getEscalations() async {
    final data = await _getList(ApiConstants.escalations);
    return data.map(EscalationModel.fromJson).toList();
  }

  Future<List<WeeklySummaryModel>> getWeeklySummaries() async {
    final data = await _getList(ApiConstants.weeklySummaries);
    return data.map(WeeklySummaryModel.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> _getList(String endpoint) async {
    final response = await _get(endpoint);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const ApiException('The server returned an unexpected response.');
    }

    return decoded.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const ApiException('The server returned an invalid record.');
      }
      return item;
    }).toList();
  }

  Future<http.Response> _get(String endpoint) async {
    var retries = 0;
    var delay = ApiConstants.initialRetryDelay;

    while (true) {
      try {
        final response = await _client
            .get(
              Uri.parse('${ApiConstants.baseUrl}$endpoint'),
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            )
            .timeout(ApiConstants.receiveTimeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _isConnected = true;
          return response;
        }

        if (_isRetryableStatus(response.statusCode) &&
            retries < ApiConstants.maxRetries) {
          retries++;
          await _waitWithJitter(delay);
          delay = _nextDelay(delay);
          continue;
        }

        _isConnected = true;
        throw _exceptionForResponse(response);
      } on TimeoutException {
        _isConnected = false;
        if (retries >= ApiConstants.maxRetries) {
          throw ApiException(
            'The server did not respond after ${retries + 1} attempts.',
            isNetworkError: true,
            isRecoverable: true,
          );
        }
        retries++;
        await _waitWithJitter(delay);
        delay = _nextDelay(delay);
      } on http.ClientException {
        _isConnected = false;
        if (retries >= ApiConstants.maxRetries) {
          throw ApiException(
            'Unable to reach the server after ${retries + 1} attempts.',
            isNetworkError: true,
            isRecoverable: true,
          );
        }
        retries++;
        await _waitWithJitter(delay);
        delay = _nextDelay(delay);
      }
    }
  }

  ApiException _exceptionForResponse(http.Response response) {
    var message = 'The request could not be completed.';
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] is String) {
        message = body['message'] as String;
      } else if (body is Map<String, dynamic> && body['error'] is String) {
        message = body['error'] as String;
      }
    } on FormatException {
      message = 'The server returned an error (${response.statusCode}).';
    }

    return ApiException(
      message,
      statusCode: response.statusCode,
      isBusinessRuleFailure: _isBusinessFailureStatus(response.statusCode),
      isRecoverable: _isRetryableStatus(response.statusCode),
    );
  }

  bool _isRetryableStatus(int statusCode) =>
      statusCode == 408 || statusCode == 429 || statusCode >= 500;

  bool _isBusinessFailureStatus(int statusCode) =>
      statusCode >= 400 &&
      statusCode < 500 &&
      statusCode != 408 &&
      statusCode != 429;

  Future<void> _waitWithJitter(Duration delay) async {
    final jitter = _random.nextInt(500);
    await Future<void>.delayed(delay + Duration(milliseconds: jitter));
  }

  Duration _nextDelay(Duration current) {
    final nextMilliseconds = min(
      (current.inMilliseconds * ApiConstants.retryMultiplier).round(),
      ApiConstants.maxRetryDelay.inMilliseconds,
    );
    return Duration(milliseconds: nextMilliseconds);
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.isNetworkError = false,
    this.isRecoverable = false,
    this.isBusinessRuleFailure = false,
  });

  final String message;
  final int? statusCode;
  final bool isNetworkError;
  final bool isRecoverable;
  final bool isBusinessRuleFailure;

  @override
  String toString() => message;
}
