// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/user/authenticated_user.dart';
import 'package:intl/intl.dart';
import '../../models/group.dart';
import '../../models/project.dart';
import '../../models/user/authenticated_user.dart';
import '../../models/user/user.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.78.243:8000/api'; // Sesuaikan!
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
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/groups',
      ), // Menggunakan endpoint /groups yang sudah ada
      headers: await _getHeaders(
        requiresAuth: true,
      ), // Biasanya perlu auth untuk lihat daftar grup
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final List<dynamic> groupListJson =
          responseData['data'] ?? responseData; // Sesuaikan jika ada paginasi
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
      // Pastikan response.body adalah JSON yang valid sebelum di-decode
      try {
        return Group.fromJson(jsonDecode(response.body));
      } catch (e) {
        print("Error parsing JSON for created group: $e");
        throw Exception('Respons server tidak valid setelah membuat grup.');
      }
    } else {
      final responseData = jsonDecode(response.body);
      // Pastikan 'message' ada dan bukan null sebelum digunakan
      final errorMessage =
          responseData['message'] as String? ??
          'Gagal membuat grup (Status: ${response.statusCode})';
      throw Exception(errorMessage);
    }
  }

  Future<Group> getGroupDetails(int groupId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/groups/$groupId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return Group.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to load group details: ${response.statusCode} ${response.body}',
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

  Future<List<User>> listJoinRequests(int groupId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/groups/$groupId/join-requests'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> requestListJson = jsonDecode(response.body);
      return requestListJson
          .map((json) => User.fromJson(json))
          .toList(); // Backend mengirim list User
    } else {
      throw Exception(
        'Failed to list join requests: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<String> approveJoinRequest(int groupId, int userIdToApprove) async {
    final response = await http.post(
      Uri.parse(
        '$_baseUrl/groups/$groupId/join-requests/$userIdToApprove/approve',
      ),
      headers: await _getHeaders(),
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return responseData['message'];
    } else {
      throw Exception(
        responseData['message'] ??
            'Failed to approve request: ${response.statusCode}',
      );
    }
  }

  Future<String> rejectJoinRequest(int groupId, int userIdToReject) async {
    final response = await http.post(
      Uri.parse(
        '$_baseUrl/groups/$groupId/join-requests/$userIdToReject/reject',
      ),
      headers: await _getHeaders(),
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return responseData['message'];
    } else {
      throw Exception(
        responseData['message'] ??
            'Failed to reject request: ${response.statusCode}',
      );
    }
  }

  // --- Projects ---
  Future<Project> createProject(
    int groupId,
    String name,
    String? description,
    DateTime? deadline,
  ) async {
    String? formattedDeadline;
    if (deadline != null) {
      formattedDeadline = DateFormat('yyyy-MM-dd').format(deadline);
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/groups/$groupId/projects'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'description': description,
        'deadline': formattedDeadline, // Kirim sebagai YYYY-MM-DD
      }),
    );
    if (response.statusCode == 201) {
      return Project.fromJson(jsonDecode(response.body));
    } else {
      final responseData = jsonDecode(response.body);
      throw Exception(
        responseData['message'] ??
            'Failed to create project: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<List<Project>> getProjectsForGroup(int groupId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/groups/$groupId/projects'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      // Asumsi backend mengirim list project dalam 'data' jika ada paginasi, atau langsung list
      final List<dynamic> projectListJson =
          responseData['data'] ?? responseData;
      return projectListJson.map((json) => Project.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load projects for group: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<Project> createFullProject(
    String projectName,
    String? projectDescription,
    DateTime? projectDeadline,
    String groupName,
    String? groupDescription,
  ) async {
    String? formattedDeadline;
    if (projectDeadline != null) {
      formattedDeadline = DateFormat('yyyy-MM-dd').format(projectDeadline);
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/projects-with-group'), // Endpoint baru
      headers: await _getHeaders(),
      body: jsonEncode({
        'project_name': projectName,
        'project_description': projectDescription,
        'project_deadline': formattedDeadline,
        'group_name': groupName,
        'group_description': groupDescription,
      }),
    );

    if (response.statusCode == 201) {
      return Project.fromJson(jsonDecode(response.body));
    } else {
      final responseData = jsonDecode(response.body);
      final errorMessage =
          responseData['message'] as String? ??
          'Gagal membuat proyek dan grup (Status: ${response.statusCode})';
      throw Exception(errorMessage);
    }
  }
}
