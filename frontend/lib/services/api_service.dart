import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../models/application_model.dart';
import '../models/user_session.dart';
import '../models/escalation_model.dart';
import '../models/incomplete_record_model.dart';
import '../models/reminder_model.dart';
import '../models/weekly_summary_model.dart';

class ApiService {
  static const _stages = {
    'application',
    'verification',
    'endorsement',
    'partner_submission',
    'interview',
    'placement_confirmation',
  };
  static const _interviewStatuses = {
    'not_scheduled',
    'scheduled',
    'completed',
    'offer_received',
    'declined',
  };

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Random _random = Random();
  bool _isConnected = true;
  String? _accessToken;
  void Function()? onUnauthorized;

  bool get isConnected => _isConnected;

  void setAccessToken(String? token) => _accessToken = token;

  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}/login'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(ApiConstants.receiveTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _exceptionForResponse(response, isLogin: true);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> ||
          decoded['token'] is! String ||
          decoded['user'] is! Map<String, dynamic>) {
        throw const ApiException('Unable to sign in. Please try again.');
      }
      return UserSession.fromJson(
        decoded['user'] as Map<String, dynamic>,
        decoded['token'] as String,
      );
    } on TimeoutException {
      throw const ApiException(
        'Unable to reach the service. Check your connection and try again.',
        isNetworkError: true,
        isRecoverable: true,
      );
    } on http.ClientException {
      throw const ApiException(
        'Unable to reach the service. Check your connection and try again.',
        isNetworkError: true,
        isRecoverable: true,
      );
    } on FormatException {
      throw const ApiException('Unable to sign in. Please try again.');
    }
  }

  Future<void> logout() async {
    try {
      final response = await _client
          .post(Uri.parse('${ApiConstants.baseUrl}/logout'), headers: _headers)
          .timeout(ApiConstants.receiveTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _exceptionForResponse(response);
      }
    } on TimeoutException {
      throw const ApiException(
        'Signed out on this device, but the server could not be reached.',
        isNetworkError: true,
        isRecoverable: true,
      );
    } on http.ClientException {
      throw const ApiException(
        'Signed out on this device, but the server could not be reached.',
        isNetworkError: true,
        isRecoverable: true,
      );
    } finally {
      _accessToken = null;
    }
  }

  Future<List<ApplicationModel>> getApplications() async {
    final data = await _getList('/applications');
    return data.map(ApplicationModel.fromJson).toList();
  }

  Future<void> updateWorkflow(
    String applicationId, {
    required String stage,
    String? interviewStatus,
  }) async {
    _validateRecordId(applicationId);
    if (!_stages.contains(stage) ||
        (interviewStatus != null &&
            (!_interviewStatuses.contains(interviewStatus) ||
                stage != 'interview'))) {
      throw const ApiException(
        'Check the information and try again.',
        statusCode: 400,
        isBusinessRuleFailure: true,
      );
    }

    final body = <String, String>{'stage': stage};
    if (interviewStatus != null) {
      body['interview_status'] = interviewStatus;
    }

    await _patch('/applications/$applicationId/workflow', body);
  }

  Future<void> completeMilestone(String milestoneId) {
    _validateRecordId(milestoneId);
    return _patch('/milestones/$milestoneId/complete');
  }

  Future<void> resolveIncompleteRecord(String recordId) {
    _validateRecordId(recordId);
    return _patch('/incomplete-records/$recordId/resolve');
  }

  Future<void> _patch(
    String endpoint, [
    Map<String, String> body = const {},
  ]) async {
    try {
      final response = await _client
          .patch(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: _headers,
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
              headers: _headers,
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

  ApiException _exceptionForResponse(
    http.Response response, {
    bool isLogin = false,
  }) {
    if (response.statusCode == 401 && !isLogin) {
      _accessToken = null;
      onUnauthorized?.call();
    }

    final message = switch (response.statusCode) {
      400 || 422 => 'Check the information and try again.',
      401 when isLogin => 'Email or password is incorrect.',
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You do not have permission to perform this action.',
      404 => 'The requested record is no longer available.',
      408 || 429 => 'The service is busy. Please wait and try again.',
      >= 500 => 'The service is temporarily unavailable. Please try again.',
      _ => 'The request could not be completed.',
    };

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

  void _validateRecordId(String value) {
    if (!RegExp(r'^[1-9]\d*$').hasMatch(value)) {
      throw const ApiException(
        'Check the information and try again.',
        statusCode: 400,
        isBusinessRuleFailure: true,
      );
    }
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

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
