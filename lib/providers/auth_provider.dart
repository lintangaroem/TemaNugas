import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/API/api_services.dart';
import '../models/user/authenticated_user.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthStatus _authStatus = AuthStatus.uninitialized;
  AuthenticatedUser? _user;
  String? _token;
  String? _errorMessage;

  // Flag untuk mencegah notifikasi berlebihan
  bool _notificationsEnabled = true;

  AuthStatus get authStatus => _authStatus;
  AuthenticatedUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _authStatus == AuthStatus.authenticated && _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _checkLoginStatus();
  }

  // Override notifyListeners untuk mencegah notifikasi saat tidak diinginkan
  @override
  void notifyListeners() {
    if (_notificationsEnabled) {
      print("AuthProvider: Notifying listeners, status: $_authStatus");
      super.notifyListeners();
    } else {
      print("AuthProvider: Notification suppressed, status: $_authStatus");
    }
  }

  // Method untuk update state tanpa notifikasi
  void _updateStateWithoutNotification(Function updateFn) {
    _notificationsEnabled = false;
    updateFn();
    _notificationsEnabled = true;
  }

  Future<void> _checkLoginStatus() async {
    _updateStateWithoutNotification(() {
      _authStatus = AuthStatus.authenticating;
    });
    notifyListeners();

    String? storedToken = await _apiService.getToken();

    if (storedToken != null && storedToken.isNotEmpty) {
      _token = storedToken;
      try {
        _user = await _apiService.getAuthenticatedUser();
        _authStatus = AuthStatus.authenticated;
        _errorMessage = null;
      } catch (e) {
        print("Error validasi token saat startup: $e");
        await _clearAllAuthData();
        _user = null;
        _token = null;
        _authStatus = AuthStatus.unauthenticated;
      }
    } else {
      _user = null;
      _token = null;
      _authStatus = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    print("AuthProvider: Starting login process");

    _updateStateWithoutNotification(() {
      _authStatus = AuthStatus.authenticating;
      _errorMessage = null;
    });
    notifyListeners();

    try {
      print("AuthProvider: Calling API login");
      final response = await _apiService.login(email, password);

      print("AuthProvider: Login API response received");

      _updateStateWithoutNotification(() {
        _user = response['user'] as AuthenticatedUser;
        _token = response['token'] as String;
        _authStatus = AuthStatus.authenticated;
        _errorMessage = null;
      });

      print("AuthProvider: Login successful, user: ${_user?.name}");
      notifyListeners();

      // Tambahkan callback untuk navigasi jika diperlukan
      if (_loginSuccessCallback != null) {
        _loginSuccessCallback!();
      }

      return true;
    } catch (e) {
      print("AuthProvider: Login failed with error: $e");

      _updateStateWithoutNotification(() {
        _authStatus = AuthStatus.unauthenticated;
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
        _user = null;
        _token = null;
      });

      notifyListeners();
      return false;
    }
  }

  // Tambahkan property dan method ini di AuthProvider
  Function? _loginSuccessCallback;

  void setLoginSuccessCallback(Function callback) {
    _loginSuccessCallback = callback;
  }

  void clearLoginSuccessCallback() {
    _loginSuccessCallback = null;
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    _updateStateWithoutNotification(() {
      _authStatus = AuthStatus.authenticating;
      _errorMessage = null;
    });
    notifyListeners();

    try {
      final response = await _apiService.register(
        name,
        email,
        password,
        passwordConfirmation,
      );

      _updateStateWithoutNotification(() {
        _user = response['user'] as AuthenticatedUser;
        _token = response['token'] as String;
        _authStatus = AuthStatus.authenticated;
        _errorMessage = null;
      });

      notifyListeners();
      return true;
    } catch (e) {
      _updateStateWithoutNotification(() {
        _authStatus = AuthStatus.unauthenticated;
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
        _user = null;
        _token = null;
      });

      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    print("AuthProvider: Starting logout process");

    try {
      _updateStateWithoutNotification(() {
        _authStatus = AuthStatus.authenticating;
      });
      notifyListeners();

      // Tambahkan delay kecil untuk memastikan semua operasi async selesai
      await Future.delayed(const Duration(milliseconds: 300));

      await _apiService.logout();
      await _clearAllAuthData();

      _updateStateWithoutNotification(() {
        _user = null;
        _token = null;
        _errorMessage = null;
        _authStatus = AuthStatus.unauthenticated;
      });

      print("AuthProvider: Logout completed successfully");
      notifyListeners();
    } catch (e) {
      print("AuthProvider: Error during logout: $e");

      // Tetap clear data meskipun ada error
      await _clearAllAuthData();

      _updateStateWithoutNotification(() {
        _user = null;
        _token = null;
        _errorMessage = null;
        _authStatus = AuthStatus.unauthenticated;
      });

      notifyListeners();
    }
  }

  Future<void> _clearAllAuthData() async {
    try {
      await _apiService.deleteToken();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');

      print("AuthProvider: All auth data cleared");
    } catch (e) {
      print("AuthProvider: Error clearing auth data: $e");
    }
  }

  Future<void> fetchUserDetails() async {
    if (_authStatus == AuthStatus.authenticated || _token != null) {
      try {
        _user = await _apiService.getAuthenticatedUser();

        _updateStateWithoutNotification(() {
          _authStatus = AuthStatus.authenticated;
          _errorMessage = null;
        });

        notifyListeners();
      } catch (e) {
        print("Error fetching user details: $e");
        await logout();
      }
    } else {
      print(
        "Tidak bisa fetch user details: Pengguna tidak terotentikasi atau tidak ada token.",
      );
    }
  }

  void clearError() {
    _updateStateWithoutNotification(() {
      _errorMessage = null;
    });
    notifyListeners();
  }

  void resetState() {
    print("AuthProvider: Resetting state");

    _updateStateWithoutNotification(() {
      _user = null;
      _token = null;
      _errorMessage = null;
      _authStatus = AuthStatus.unauthenticated;
    });

    notifyListeners();
  }
}
