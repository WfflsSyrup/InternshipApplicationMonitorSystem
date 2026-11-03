import 'package:flutter/foundation.dart';
import '../models/application_model.dart';
import '../models/reminder_model.dart';
import '../models/incomplete_record_model.dart';
import '../models/escalation_model.dart';
import '../models/weekly_summary_model.dart';
import '../services/api_service.dart';

enum DataLoadingState { loading, success, empty, error, businessFailure, idle }

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  // Data
  List<ReminderModel> _reminders = [];
  List<ApplicationModel> _applications = [];
  List<IncompleteRecordModel> _incompleteRecords = [];
  List<EscalationModel> _escalations = [];
  List<WeeklySummaryModel> _weeklySummaries = [];

  // States
  DataLoadingState _remindersState = DataLoadingState.idle;
  DataLoadingState _applicationsState = DataLoadingState.idle;
  DataLoadingState _incompleteRecordsState = DataLoadingState.idle;
  DataLoadingState _escalationsState = DataLoadingState.idle;
  DataLoadingState _weeklySummariesState = DataLoadingState.idle;

  // Errors
  String _remindersError = '';
  String _applicationsError = '';
  String _workflowUpdateError = '';
  bool _workflowUpdateIsBusinessFailure = false;
  bool _isUpdatingWorkflow = false;
  String _recordActionError = '';
  bool _recordActionIsBusinessFailure = false;
  bool _isUpdatingRecord = false;
  String _incompleteRecordsError = '';
  String _escalationsError = '';
  String _weeklySummariesError = '';

  // Getters
  List<ReminderModel> get reminders => _reminders;
  List<ApplicationModel> get applications => _applications;
  List<IncompleteRecordModel> get incompleteRecords => _incompleteRecords;
  List<EscalationModel> get escalations => _escalations;
  List<WeeklySummaryModel> get weeklySummaries => _weeklySummaries;

  DataLoadingState get remindersState => _remindersState;
  DataLoadingState get applicationsState => _applicationsState;
  DataLoadingState get incompleteRecordsState => _incompleteRecordsState;
  DataLoadingState get escalationsState => _escalationsState;
  DataLoadingState get weeklySummariesState => _weeklySummariesState;

  String get remindersError => _remindersError;
  String get applicationsError => _applicationsError;
  String get workflowUpdateError => _workflowUpdateError;
  bool get workflowUpdateIsBusinessFailure => _workflowUpdateIsBusinessFailure;
  bool get isUpdatingWorkflow => _isUpdatingWorkflow;
  String get recordActionError => _recordActionError;
  bool get recordActionIsBusinessFailure => _recordActionIsBusinessFailure;
  bool get isUpdatingRecord => _isUpdatingRecord;
  String get incompleteRecordsError => _incompleteRecordsError;
  String get escalationsError => _escalationsError;
  String get weeklySummariesError => _weeklySummariesError;

  bool get isConnected => _apiService.isConnected;

  // Fetch all data
  Future<void> fetchAllData() async {
    await Future.wait([
      fetchReminders(),
      fetchApplications(),
      fetchIncompleteRecords(),
      fetchEscalations(),
      fetchWeeklySummaries(),
    ]);
  }

  // Fetch Reminders
  Future<void> fetchReminders() async {
    _remindersState = DataLoadingState.loading;
    _remindersError = '';
    notifyListeners();

    try {
      final data = await _apiService.getReminders();
      _reminders = data;
      _remindersState = data.isEmpty
          ? DataLoadingState.empty
          : DataLoadingState.success;
    } on ApiException catch (error) {
      _remindersState = error.isBusinessRuleFailure
          ? DataLoadingState.businessFailure
          : DataLoadingState.error;
      _remindersError = error.message;
    } on FormatException catch (error) {
      _remindersState = DataLoadingState.error;
      _remindersError =
          'The server returned invalid reminder data: ${error.message}';
    }
    notifyListeners();
  }

  Future<void> fetchApplications() async {
    _applicationsState = DataLoadingState.loading;
    _applicationsError = '';
    notifyListeners();

    try {
      final data = await _apiService.getApplications();
      _applications = data;
      _applicationsState = data.isEmpty
          ? DataLoadingState.empty
          : DataLoadingState.success;
    } on ApiException catch (error) {
      _applicationsState = error.isBusinessRuleFailure
          ? DataLoadingState.businessFailure
          : DataLoadingState.error;
      _applicationsError = error.message;
    } on FormatException catch (error) {
      _applicationsState = DataLoadingState.error;
      _applicationsError =
          'The server returned invalid application data: ${error.message}';
    }
    notifyListeners();
  }

  Future<bool> updateWorkflow(
    String applicationId, {
    required String stage,
    String? interviewStatus,
  }) async {
    _isUpdatingWorkflow = true;
    _workflowUpdateError = '';
    _workflowUpdateIsBusinessFailure = false;
    notifyListeners();

    try {
      await _apiService.updateWorkflow(
        applicationId,
        stage: stage,
        interviewStatus: interviewStatus,
      );
      await fetchApplications();
      return true;
    } on ApiException catch (error) {
      _workflowUpdateError = error.message;
      _workflowUpdateIsBusinessFailure = error.isBusinessRuleFailure;
      return false;
    } finally {
      _isUpdatingWorkflow = false;
      notifyListeners();
    }
  }

  Future<bool> completeMilestone(String milestoneId) async {
    _isUpdatingRecord = true;
    _recordActionError = '';
    _recordActionIsBusinessFailure = false;
    notifyListeners();
    try {
      await _apiService.completeMilestone(milestoneId);
      await fetchReminders();
      return true;
    } on ApiException catch (error) {
      _recordActionError = error.message;
      _recordActionIsBusinessFailure = error.isBusinessRuleFailure;
      return false;
    } finally {
      _isUpdatingRecord = false;
      notifyListeners();
    }
  }

  Future<bool> resolveIncompleteRecord(String recordId) async {
    _isUpdatingRecord = true;
    _recordActionError = '';
    _recordActionIsBusinessFailure = false;
    notifyListeners();
    try {
      await _apiService.resolveIncompleteRecord(recordId);
      await fetchIncompleteRecords();
      return true;
    } on ApiException catch (error) {
      _recordActionError = error.message;
      _recordActionIsBusinessFailure = error.isBusinessRuleFailure;
      return false;
    } finally {
      _isUpdatingRecord = false;
      notifyListeners();
    }
  }

  // Fetch Incomplete Records
  Future<void> fetchIncompleteRecords() async {
    _incompleteRecordsState = DataLoadingState.loading;
    _incompleteRecordsError = '';
    notifyListeners();

    try {
      final data = await _apiService.getIncompleteRecords();
      _incompleteRecords = data;
      _incompleteRecordsState = data.isEmpty
          ? DataLoadingState.empty
          : DataLoadingState.success;
    } on ApiException catch (error) {
      _incompleteRecordsState = error.isBusinessRuleFailure
          ? DataLoadingState.businessFailure
          : DataLoadingState.error;
      _incompleteRecordsError = error.message;
    } on FormatException catch (error) {
      _incompleteRecordsState = DataLoadingState.error;
      _incompleteRecordsError =
          'The server returned invalid record data: ${error.message}';
    }
    notifyListeners();
  }

  // Fetch Escalations
  Future<void> fetchEscalations() async {
    _escalationsState = DataLoadingState.loading;
    _escalationsError = '';
    notifyListeners();

    try {
      final data = await _apiService.getEscalations();
      _escalations = data;
      _escalationsState = data.isEmpty
          ? DataLoadingState.empty
          : DataLoadingState.success;
    } on ApiException catch (error) {
      _escalationsState = error.isBusinessRuleFailure
          ? DataLoadingState.businessFailure
          : DataLoadingState.error;
      _escalationsError = error.message;
    } on FormatException catch (error) {
      _escalationsState = DataLoadingState.error;
      _escalationsError =
          'The server returned invalid escalation data: ${error.message}';
    }
    notifyListeners();
  }

  // Fetch Weekly Summaries
  Future<void> fetchWeeklySummaries() async {
    _weeklySummariesState = DataLoadingState.loading;
    _weeklySummariesError = '';
    notifyListeners();

    try {
      final data = await _apiService.getWeeklySummaries();
      _weeklySummaries = data;
      _weeklySummariesState = data.isEmpty
          ? DataLoadingState.empty
          : DataLoadingState.success;
    } on ApiException catch (error) {
      _weeklySummariesState = error.isBusinessRuleFailure
          ? DataLoadingState.businessFailure
          : DataLoadingState.error;
      _weeklySummariesError = error.message;
    } on FormatException catch (error) {
      _weeklySummariesState = DataLoadingState.error;
      _weeklySummariesError =
          'The server returned invalid summary data: ${error.message}';
    }
    notifyListeners();
  }

  // Retry all failed requests
  Future<void> retryAll() async {
    await fetchAllData();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
