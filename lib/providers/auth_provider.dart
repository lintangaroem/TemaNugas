import 'package:flutter/material.dart';
// Sesuaikan path import service dan model Anda
import '../services/API/api_services.dart'; // Menggunakan nama file dari kode Anda
import '../models/user/authenticated_user.dart';

enum AuthStatus { uninitialized, authenticated, authenticating, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthStatus _authStatus = AuthStatus.uninitialized;
  AuthenticatedUser? _user;
  String? _token; // Token juga disimpan di secure storage oleh ApiService
  String? _errorMessage;

  AuthStatus get authStatus => _authStatus;
  AuthenticatedUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated && _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _authStatus = AuthStatus.authenticating;
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
        await _apiService.deleteToken(); // Hapus token yang tidak valid
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
    _authStatus = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.login(email, password);
      _user = response['user'] as AuthenticatedUser;
      _token = response['token'] as String;
      _authStatus = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _user = null;
      _token = null;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String passwordConfirmation) async {
    _authStatus = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.register(name, email, password, passwordConfirmation);
      _user = response['user'] as AuthenticatedUser;
      _token = response['token'] as String;
      _authStatus = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _user = null;
      _token = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout(); // ApiService akan menghapus token dari storage
    _user = null;
    _token = null;
    _authStatus = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchUserDetails() async {
    if (_authStatus == AuthStatus.authenticated || _token != null) {
      // Tetap coba fetch jika ada token, meskipun status mungkin belum authenticated (misal saat startup)
      // _authStatus = AuthStatus.authenticating; // Opsional: tampilkan loading saat refresh
      // notifyListeners();
      try {
        _user = await _apiService.getAuthenticatedUser();
        _authStatus = AuthStatus.authenticated; // Pastikan status kembali ke authenticated
        _errorMessage = null;
      } catch (e) {
        print("Error fetching user details: $e");
        await logout(); // Jika gagal (misal token tidak valid), logout user
      } finally {
        notifyListeners();
      }
    } else {
      print("Tidak bisa fetch user details: Pengguna tidak terotentikasi atau tidak ada token.");
    }
  }
}
