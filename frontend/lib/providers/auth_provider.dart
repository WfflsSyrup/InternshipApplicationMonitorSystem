import 'package:flutter/foundation.dart';

import '../models/user_session.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({ApiService? apiService})
    : apiService = apiService ?? ApiService(),
      _ownsApiService = apiService == null {
    this.apiService.onUnauthorized = _expireSession;
  }

  final ApiService apiService;
  final bool _ownsApiService;
  UserSession? _session;
  bool _isLoading = false;
  String? _notice;

  UserSession? get session => _session;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _session != null;
  String? get notice => _notice;

  Future<void> signIn({required String email, required String password}) async {
    _isLoading = true;
    _notice = null;
    notifyListeners();

    try {
      final session = await apiService.login(email: email, password: password);
      apiService.setAccessToken(session.accessToken);
      _session = session;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    String? notice;
    try {
      await apiService.logout();
    } on ApiException catch (error) {
      notice = error.message;
    } finally {
      _session = null;
      _notice = notice;
      notifyListeners();
    }
  }

  void _expireSession() {
    if (_session == null) return;
    _session = null;
    _notice = 'Your session has expired. Please sign in again.';
    notifyListeners();
  }

  @override
  void dispose() {
    apiService.onUnauthorized = null;
    if (_ownsApiService) apiService.dispose();
    super.dispose();
  }
}
