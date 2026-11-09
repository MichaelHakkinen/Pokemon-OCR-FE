import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/collection_item.dart';
import '../models/export_field_config.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS simulator, or machine IP
  static String baseUrl = 'http://10.0.2.2:3003';
  static String mockUserId = '00000000-0000-0000-0000-000000000001';

  static Map<String, String> get _headers => {
        'Accept': 'application/json',
        'x-user-id': mockUserId,
      };

  /**
   * Uploads cropped card image to NestJS Backend OCR Gateway
   */
  static Future<ScanCardResponse> scanCard({
    required File imageFile,
    String? languageHint,
  }) async {
    final uri = Uri.parse('$baseUrl/ocr/scan').replace(
      queryParameters: languageHint != null && languageHint != 'auto'
          ? {'languageHint': languageHint}
          : null,
    );

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers);
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonBody = jsonDecode(response.body);
      final data = jsonBody['data'] ?? jsonBody;
      return ScanCardResponse.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception('OCR scan failed (${response.statusCode}): ${response.body}');
    }
  }

  /**
   * Fetches user's collected cards
   */
  static Future<List<UserCardItem>> getCollection() async {
    final uri = Uri.parse('$baseUrl/collection');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonBody = jsonDecode(response.body);
      final List<dynamic> list = jsonBody['data'] ?? jsonBody;
      return list.map((e) => UserCardItem.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load collection (${response.statusCode}): ${response.body}');
    }
  }

  /**
   * Adds a scanned card to user's collection
   */
  static Future<void> addToCollection({
    required String cardId,
    String condition = 'NM',
    String grade = 'Raw',
    String language = 'en',
    int quantity = 1,
    Map<String, dynamic>? customFields,
  }) async {
    final uri = Uri.parse('$baseUrl/collection');
    final response = await http.post(
      uri,
      headers: {
        ..._headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'cardId': cardId,
        'condition': condition,
        'grade': grade,
        'language': language,
        'quantity': quantity,
        'customFields': customFields ?? {},
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to add to collection: ${response.body}');
    }
  }

  /**
   * Fetches dynamic pre-export confirmation survey configuration
   */
  static Future<ExportConfig> getExportConfig() async {
    final uri = Uri.parse('$baseUrl/collection/export-config');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonBody = jsonDecode(response.body);
      final data = jsonBody['data'] ?? jsonBody;
      return ExportConfig.fromJson(data as Map<String, dynamic>);
    } else {
      // Fallback to local default if offline
      return ExportConfig.defaultConfiguration();
    }
  }

  /**
   * Updates export popup configuration
   */
  static Future<void> updateExportConfig(ExportConfig config) async {
    final uri = Uri.parse('$baseUrl/collection/export-config');
    final response = await http.put(
      uri,
      headers: {
        ..._headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(config.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update export config: ${response.body}');
    }
  }
}

