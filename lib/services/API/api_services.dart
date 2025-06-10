import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal

// Sesuaikan path import model Anda
import '../../models/user/authenticated_user.dart';
import '../../models/user/user.dart';
import '../../models/project.dart';
import '../../models/todo.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.78.243:8000/api';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _authTokenKey = 'auth_token';

  Future<String?> getToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _authTokenKey);
  }

  // --- Helper untuk Headers ---
  Future<Map<String, String>> _getHeaders({bool requiresAuth = true, bool isJsonContent = true}) async {
    Map<String, String> headers = {};
    if (isJsonContent) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
      headers['Accept'] = 'application/json';
    }
    if (requiresAuth) {
      String? token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // --- Helper untuk Error Handling ---
  Exception _handleErrorResponse(http.Response response, String defaultMessage) {
    try {
      final responseData = jsonDecode(response.body);
      return Exception(responseData['message'] as String? ?? '$defaultMessage (Status: ${response.statusCode})');
    } catch (e) {
      return Exception('$defaultMessage (Status: ${response.statusCode}), Respons tidak valid: ${response.body}');
    }
  }


  // === OTENTIKASI ===
  Future<Map<String, dynamic>> register(String name, String email, String password, String passwordConfirmation) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: await _getHeaders(requiresAuth: false),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );
    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      if (responseData['token'] != null && responseData['user'] != null) {
        await saveToken(responseData['token'] as String);
        return {
          'user': AuthenticatedUser.fromJson(responseData['user'] as Map<String, dynamic>),
          'token': responseData['token'] as String
        };
      }
    }
    throw _handleErrorResponse(response, 'Gagal melakukan registrasi');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: await _getHeaders(requiresAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['token'] != null && responseData['user'] != null) {
        await saveToken(responseData['token'] as String);
        return {
          'user': AuthenticatedUser.fromJson(responseData['user'] as Map<String, dynamic>),
          'token': responseData['token'] as String
        };
      }
    }
    throw _handleErrorResponse(response, 'Gagal login');
  }

  Future<void> logout() async {
    final String? token = await getToken();
    if (token == null || token.isEmpty) {
      await deleteToken(); // Pastikan token bersih
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: await _getHeaders(),
      );
      if (response.statusCode != 200) {
        print('API logout gagal: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error saat memanggil API logout: $e');
    } finally {
      await deleteToken(); // Selalu hapus token dari storage
    }
  }

  Future<AuthenticatedUser> getAuthenticatedUser() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/user'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return AuthenticatedUser.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else if (response.statusCode == 401) {
      await deleteToken(); // Token tidak valid, hapus
      throw Exception('Sesi tidak valid. Silakan login kembali.');
    }
    throw _handleErrorResponse(response, 'Gagal mengambil data pengguna');
  }

  // === PROYEK ===
  Future<List<Project>> getDiscoverableProjects() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/projects'),
      headers: await _getHeaders(), // Asumsi perlu otentikasi
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final List<dynamic> projectListJson = responseData['data'] as List<dynamic>? ?? responseData as List<dynamic>;
      return projectListJson.map((json) => Project.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw _handleErrorResponse(response, 'Gagal memuat daftar proyek');
  }

  Future<Project> createProject(String name, String? description, DateTime? deadline) async {
    String? formattedDeadline;
    if (deadline != null) {
      formattedDeadline = DateFormat('yyyy-MM-dd').format(deadline);
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/projects'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'description': description,
        'deadline': formattedDeadline,
      }),
    );
    if (response.statusCode == 201) {
      return Project.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw _handleErrorResponse(response, 'Gagal membuat proyek');
  }

  Future<Project> getProjectDetails(int projectId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/projects/$projectId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return Project.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw _handleErrorResponse(response, 'Gagal memuat detail proyek');
  }

  Future<String> requestToJoinProject(int projectId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/projects/$projectId/request-join'),
      headers: await _getHeaders(),
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) return responseData['message'] as String? ?? 'Permintaan terkirim';
    throw _handleErrorResponse(response, 'Gagal mengirim permintaan bergabung');
  }

  Future<List<User>> listProjectJoinRequests(int projectId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/projects/$projectId/join-requests'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> requestListJson = jsonDecode(response.body) as List<dynamic>;
      return requestListJson.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw _handleErrorResponse(response, 'Gagal memuat permintaan bergabung');
  }

  Future<String> approveProjectJoinRequest(int projectId, int userIdToApprove) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/projects/$projectId/join-requests/$userIdToApprove/approve'),
      headers: await _getHeaders(),
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) return responseData['message'] as String? ?? 'Permintaan disetujui';
    throw _handleErrorResponse(response, 'Gagal menyetujui permintaan');
  }

  Future<String> rejectProjectJoinRequest(int projectId, int userIdToReject) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/projects/$projectId/join-requests/$userIdToReject/reject'),
      headers: await _getHeaders(),
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) return responseData['message'] as String? ?? 'Permintaan ditolak';
    throw _handleErrorResponse(response, 'Gagal menolak permintaan');
  }

   Future<String> leaveProject(int projectId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/projects/$projectId/leave'),
      headers: await _getHeaders(),
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) return responseData['message'] as String? ?? 'Berhasil keluar dari proyek';
    throw _handleErrorResponse(response, 'Gagal keluar dari proyek');
  }

  // === TODOS ===
  Future<List<Todo>> getTodosForProject(int projectId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/projects/$projectId/todos'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final List<dynamic> todoListJson = responseData['data'] as List<dynamic>? ?? responseData as List<dynamic>;
      return todoListJson.map((json) => Todo.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw _handleErrorResponse(response, 'Gagal memuat tugas');
  }

  Future<Todo> createTodo(int projectId, String title) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/projects/$projectId/todos'),
      headers: await _getHeaders(),
      body: jsonEncode({'title': title}),
    );
    if (response.statusCode == 201) {
      return Todo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw _handleErrorResponse(response, 'Gagal membuat tugas');
  }

  Future<Todo> updateTodo(int projectId, int todoId, String title, bool isCompleted) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/projects/$projectId/todos/$todoId'),
      headers: await _getHeaders(),
      body: jsonEncode({'title': title, 'is_completed': isCompleted}),
    );
    if (response.statusCode == 200) {
      return Todo.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw _handleErrorResponse(response, 'Gagal memperbarui tugas');
  }

  Future<void> deleteTodo(int projectId, int todoId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/projects/$projectId/todos/$todoId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) { // 204 No Content juga sukses
      throw _handleErrorResponse(response, 'Gagal menghapus tugas');
    }
    // Tidak ada body untuk di-return pada delete sukses
  }
  // Mirip dengan implementasi Todos, sesuaikan dengan endpoint dan model Note Anda.
  // Contoh:
  // Future<List<Note>> getNotesForProject(int projectId) async { ... }
  // Future<Note> createNote(int projectId, String content, {String? title}) async { ... }
}
