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

  // ===== TAMBAHAN UNTUK PROFILE DATA =====
  String _userBio = 'Edit your bio...';
  List<String> _userSkills = ['UI/UX', 'Frontend', 'Backend'];

  AuthStatus get authStatus => _authStatus;
  AuthenticatedUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authStatus == AuthStatus.authenticated && _user != null;

  // ===== GETTERS UNTUK PROFILE DATA =====
  String get userBio => _userBio;
  List<String> get userSkills => List.from(_userSkills);

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
        // Load profile data setelah login berhasil
        await _loadProfileData();
      } catch (e) {
        print("Error validasi token saat startup: $e");
        await _apiService.deleteToken(); // Hapus token yang tidak valid
        _user = null;
        _token = null;
        _authStatus = AuthStatus.unauthenticated;
        _resetProfileData(); // Reset profile data jika token invalid
      }
    } else {
      _user = null;
      _token = null;
      _authStatus = AuthStatus.unauthenticated;
      _resetProfileData(); // Reset profile data jika tidak ada token
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
      // Load profile data setelah login berhasil
      await _loadProfileData();
      notifyListeners();
      return true;
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _user = null;
      _token = null;
      _resetProfileData(); // Reset profile data jika login gagal
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
      // Load profile data setelah register berhasil
      await _loadProfileData();
      notifyListeners();
      return true;
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      _errorMessage = e.toString().replaceFirst("Exception: ", "");
      _user = null;
      _token = null;
      _resetProfileData(); // Reset profile data jika register gagal
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
    _resetProfileData(); // Reset profile data saat logout
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
        // Refresh profile data juga
        await _loadProfileData();
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

  // ===== METHODS UNTUK PROFILE DATA =====

  // Update bio
  void updateUserBio(String newBio) {
    _userBio = newBio;
    notifyListeners();
    // Optional: simpan ke API/database
    _saveProfileToServer();
  }

  // Update skills
  void updateUserSkills(List<String> newSkills) {
    _userSkills = List.from(newSkills);
    notifyListeners();
    // Optional: simpan ke API/database
    _saveProfileToServer();
  }

  // Update semua profile data sekaligus
  void updateProfileData({
    String? bio,
    List<String>? skills,
  }) {
    bool hasChanges = false;

    if (bio != null && bio != _userBio) {
      _userBio = bio;
      hasChanges = true;
    }
    if (skills != null && !_listEquals(_userSkills, skills)) {
      _userSkills = List.from(skills);
      hasChanges = true;
    }

    if (hasChanges) {
      notifyListeners();
      _saveProfileToServer();
    }
  }

  // Load profile data dari server (dipanggil saat login/register)
  Future<void> _loadProfileData() async {
    try {
      // TODO: Implement API call untuk load profile
      // final profileData = await _apiService.getUserProfile();
      // _userBio = profileData['bio'] ?? 'hi';
      // _userSkills = List<String>.from(profileData['skills'] ?? ['UI/UX', 'Frontend', 'Backend']);

      // Sementara ini, kita biarkan default values
      print('Profile data loaded for user: ${_user?.name}');
    } catch (e) {
      print('Error loading profile data: $e');
      // Jika error, gunakan default values
      _userBio = 'Edit your bio...';
      _userSkills = ['UI/UX', 'Frontend', 'Backend'];
    }
  }

  // Save profile data ke server
  Future<void> _saveProfileToServer() async {
    if (!isAuthenticated) return;

    try {
      // TODO: Implement API call untuk save profile
      // await _apiService.updateUserProfile({
      //   'bio': _userBio,
      //   'skills': _userSkills,
      // });

      print('Profile saved - Bio: $_userBio, Skills: $_userSkills');
    } catch (e) {
      print('Error saving profile: $e');
    }
  }

  // Reset profile data (dipanggil saat logout atau error)
  void _resetProfileData() {
    _userBio = 'Edit your bio...';
    _userSkills = ['UI/UX', 'Frontend', 'Backend'];
  }

  // Helper method untuk compare lists
  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}