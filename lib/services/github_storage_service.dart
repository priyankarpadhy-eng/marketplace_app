import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class GithubStorageService {
  GithubStorageService._();
  static final instance = GithubStorageService._();

  static const String owner = 'priyankarpadhy-eng';
  static const String repo = 'music_database';

  String get _githubToken => dotenv.env['GITHUB_PAT'] ?? '';

  /// Uploads an MP3 file as a GitHub Release Asset to avoid bloating git history.
  Future<String?> uploadMusic(File file, {void Function(int sent, int total)? onProgress}) async {
    if (_githubToken.isEmpty) {
      debugPrint('Error: GITHUB_PAT is not defined in .env');
      throw Exception('GitHub Personal Access Token is missing. Please add GITHUB_PAT to .env');
    }

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      
      // 1. Get or create the "music-assets" release
      int? releaseId = await _getReleaseIdByTag('music-assets');
      if (releaseId == null) {
        releaseId = await _createRelease('music-assets', 'Music Assets', 'Storage for uploaded music');
      }

      // 2. Upload the file as a Release Asset using Dio for progress tracking
      final uploadUrl = 'https://uploads.github.com/repos/$owner/$repo/releases/$releaseId/assets?name=$fileName';
      
      final dio = Dio();
      final length = await file.length();
      
      // Create a stream from the file to avoid loading entire file into memory for Dio
      final stream = file.openRead();

      final response = await dio.post(
        uploadUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_githubToken',
            'Accept': 'application/vnd.github.v3+json',
            'Content-Type': 'audio/mpeg',
            Headers.contentLengthHeader: length,
          },
        ),
        data: stream,
        onSendProgress: onProgress,
      );

      if (response.statusCode == 201) {
        return response.data['browser_download_url'] as String;
      } else {
        debugPrint('GitHub Asset Upload Error: ${response.statusCode} - ${response.data}');
        throw Exception('Failed to upload asset to GitHub Release: ${response.data}');
      }
    } catch (e) {
      debugPrint('Exception uploading to GitHub Release: $e');
      rethrow;
    }
  }

  /// Fetches the list of music files stored as assets in the 'music-assets' release.
  /// Returns a list of maps containing 'name' and 'url'.
  Future<List<Map<String, String>>> fetchMusicAssets() async {
    if (_githubToken.isEmpty) {
      debugPrint('Error: GITHUB_PAT is not defined in .env');
      return [];
    }

    try {
      final url = Uri.parse('https://api.github.com/repos/$owner/$repo/releases/tags/music-assets');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_githubToken',
          'Accept': 'application/vnd.github.v3+json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assets = data['assets'] as List<dynamic>? ?? [];
        
        return assets.map((asset) => {
          'name': asset['name'] as String,
          'url': asset['browser_download_url'] as String,
        }).toList();
      } else {
        debugPrint('Failed to fetch music assets: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception fetching music assets: $e');
      return [];
    }
  }

  Future<int?> _getReleaseIdByTag(String tag) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/releases/tags/$tag');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_githubToken',
        'Accept': 'application/vnd.github.v3+json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'] as int;
    }
    return null; // Release not found
  }

  Future<int> _createRelease(String tag, String name, String body) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/releases');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_githubToken',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'tag_name': tag,
        'name': name,
        'body': body,
      }),
    );
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'] as int;
    } else {
      throw Exception('Failed to create GitHub Release: ${response.body}');
    }
  }
}
