// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
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
  String?
  _token; // Menyimpan token di provider bisa berguna, tapi sumber utama tetap secure storage
  String? _errorMessage;

  AuthStatus get authStatus => _authStatus;
  AuthenticatedUser? get user => _user;
  String? get tokenValue =>
      _token; // Ganti nama agar tidak bentrok dengan getter token di ApiService
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Panggil _checkLoginStatus saat inisialisasi
    await _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _authStatus = AuthStatus.authenticating; // Mulai dengan status loading
    notifyListeners();

    String? storedToken =
        await _apiService.getToken(); // Ambil token dari ApiService

    if (storedToken != null && storedToken.isNotEmpty) {
      _token = storedToken; // Simpan token di provider untuk sementara
      try {
        // Validasi token dengan mengambil data user
        _user = await _apiService.getAuthenticatedUser();
        _authStatus = AuthStatus.authenticated;
        _errorMessage = null;
      } catch (e) {
        // Jika getAuthenticatedUser gagal (misal token tidak valid, error 401, atau error jaringan)
        print("Error validating token: $e");
        await _apiService.deleteToken(); // Hapus token yang tidak valid
        _user = null;
        _token = null;
        _authStatus = AuthStatus.unauthenticated;
        // _errorMessage = e.toString().replaceFirst("Exception: ", ""); // Bisa diset jika ingin ditampilkan
      }
    } else {
      // Tidak ada token tersimpan
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
    print('AuthProvider: Attempting login for $email'); // Tambahkan ini
    try {
      final response = await _apiService.login(email, password);
      _user = response['user'] as AuthenticatedUser;
      _token = response['token'] as String;
      _authStatus = AuthStatus.authenticated;
      _errorMessage = null; // Pastikan error message bersih jika sukses
      print('AuthProvider: Login successful for $email'); // Tambahkan ini
      notifyListeners();
      return true;
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _user = null;
      _token = null;
      print(
        'AuthProvider: Login failed for $email. Error: $_errorMessage',
      ); // Tambahkan ini
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    _authStatus = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiService.register(
        name,
        email,
        password,
        passwordConfirmation,
      );
      _user = response['user'] as AuthenticatedUser;
      _token =
          response['token']
              as String; // Token sudah disimpan oleh ApiService.saveToken
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
    // Panggil API logout dulu
    try {
      await _apiService
          .logout(); // ApiService.logout() sudah menghandle deleteToken()
    } catch (e) {
      print("Error during API logout call in AuthProvider: $e");
      // Meskipun API call gagal, kita tetap harus logout di sisi client
      await _apiService
          .deleteToken(); // Pastikan token dihapus jika API call gagal
    }
    _user = null;
    _token = null;
    _authStatus = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchUserDetails() async {
    // Method ini dipanggil untuk refresh data user, misal setelah update profil atau keanggotaan grup
    if (_authStatus == AuthStatus.authenticated) {
      // _authStatus = AuthStatus.authenticating; // Opsional: tampilkan loading saat refresh
      // notifyListeners();
      try {
        _user = await _apiService.getAuthenticatedUser();
        _authStatus =
            AuthStatus
                .authenticated; // Pastikan status kembali ke authenticated
        _errorMessage = null;
        notifyListeners();
      } catch (e) {
        print("Error fetching user details: $e");
        // Jika gagal fetch user details (misal token jadi tidak valid), logout user
        await logout(); // logout akan set status ke unauthenticated dan notifyListeners
      }
    } else {
      // Jika tidak terotentikasi, tidak ada yang perlu di-fetch
      print("Cannot fetch user details: User not authenticated.");
    }
  }
}
