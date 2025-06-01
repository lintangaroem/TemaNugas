// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/user/authenticated_user.dart';
import '../../models/group.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.31.81:8000/api'; // Sesuaikan!
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Jadikan publik atau buat metode wrapper jika ingin menjaga _storage tetap private
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<Map<String, String>> _getHeaders({
    bool requiresAuth = true,
    bool isJsonContent = true,
  }) async {
    Map<String, String> headers = {};
    if (isJsonContent) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
      headers['Accept'] = 'application/json';
    }
    if (requiresAuth) {
      String? token = await getToken(); // Gunakan metode publik
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // --- Auth ---
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: await _getHeaders(requiresAuth: false),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 201 && responseData['token'] != null) {
      await saveToken(responseData['token']); // Gunakan metode publik
      return {
        'user': AuthenticatedUser.fromJson(responseData['user']),
        'token': responseData['token'],
      };
    } else {
      throw Exception(
        responseData['message'] ??
            'Failed to register: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    final headers = await _getHeaders(requiresAuth: false);
    final body = jsonEncode({'email': email, 'password': password});

    print('--- LOGIN REQUEST ---');
    print('URL: $url');
    print('Headers: $headers');
    print('Body: $body');

    try {
      final response = await http.post(url, headers: headers, body: body);

      print('--- LOGIN RESPONSE ---');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['token'] != null) {
        await saveToken(responseData['token']);
        return {
          'user': AuthenticatedUser.fromJson(responseData['user']),
          'token': responseData['token'],
        };
      } else {
        // Cetak pesan error dari server jika ada, atau buat pesan default
        final errorMessage =
            responseData['message'] ??
            'Failed to login (Status: ${response.statusCode})';
        print('Login Error (Server): $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Tangkap error koneksi atau error parsing JSON
      print('Login Error (Client/Network): $e');
      throw Exception(
        'Tidak dapat terhubung ke server atau respons tidak valid. Error: $e',
      );
    }
  }

  Future<void> logout() async {
    final String? token = await getToken();
    if (token == null) {
      await deleteToken();
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: await _getHeaders(),
      );
      if (response.statusCode != 200) {
        print('API logout failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error during API logout call: $e');
    } finally {
      await deleteToken(); // Selalu hapus token dari storage
    }
  }

  Future<AuthenticatedUser> getAuthenticatedUser() async {
    final String? token = await getToken();
    if (token == null) {
      // Jika tidak ada token sama sekali, tidak perlu panggil API, langsung throw error unauthenticated
      throw Exception('Unauthenticated. No token found.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/user'),
      headers:
          await _getHeaders(), // _getHeaders akan otomatis menyertakan token jika ada
    );

    if (response.statusCode == 200) {
      return AuthenticatedUser.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      // Token tidak valid atau expired, hapus dari storage
      await deleteToken();
      throw Exception('Unauthorized. Please login again.');
    } else {
      throw Exception(
        'Failed to load user: ${response.statusCode} ${response.body}',
      );
    }
  }

  // ... (sisa metode ApiService) ...
  // --- Groups ---
  Future<List<Group>> getDiscoverableGroups() async {
    // Asumsi endpoint ini tidak memerlukan auth, jika ya, set requiresAuth: true
    final response = await http.get(
      Uri.parse('$_baseUrl/discoverable-groups'), // Endpoint baru dari backend
      headers: await _getHeaders(
        requiresAuth: false,
      ), // Atau true jika perlu auth
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Backend mungkin mengirim data dalam 'data' jika menggunakan paginasi Laravel Resource
      final List<dynamic> groupListJson = responseData['data'] ?? responseData;
      return groupListJson.map((json) => Group.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load discoverable groups: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<Group> createGroup(String name, String? description) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/groups'),
      headers: await _getHeaders(),
      body: jsonEncode({'name': name, 'description': description}),
    );
    if (response.statusCode == 201) {
      return Group.fromJson(jsonDecode(response.body));
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(
        responseData['message'] ??
            'Failed to create group: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> requestToJoinGroup(int groupId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/groups/$groupId/request-join'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      // Berhasil, mungkin ada pesan di response.body
      print(jsonDecode(response.body)['message']);
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(
        responseData['message'] ??
            'Failed to request join: ${response.statusCode} ${response.body}',
      );
    }
  }
}
