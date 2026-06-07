import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class StorageService {
  static const String _apiEndpoint = 'https://igitmarketplace.vercel.app/api/get-upload-url';

  /// Uploads a file to Cloudflare R2 using the same API as the website.
  /// Returns the public URL of the uploaded file.
  Future<String> uploadFile(File file, {String folder = 'uploads'}) async {
    try {
      final fileName = '${folder}/${DateTime.now().millisecondsSinceEpoch}-${path.basename(file.path)}';
      final contentType = _getContentType(file.path);

      // 1. Get Pre-Signed URL from the website backend
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fileName': fileName,
          'contentType': contentType,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get upload URL: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final String uploadUrl = data['url'];
      String publicUrl = data['publicUrl'];

      // Override with .env prefix if available, to fix 401/unauthorized domain issues
      try {
        final envPublicUrl = String.fromEnvironment('CLOUDFLARE_R2_PUBLIC_URL');
        if (envPublicUrl.isNotEmpty) {
          final fileNamePart = publicUrl.split('.dev/').last;
          publicUrl = '${envPublicUrl}/$fileNamePart';
        }
      } catch (_) {}

      // 2. Upload the file directly to R2 using the pre-signed PutObject URL
      final List<int> fileBytes = await file.readAsBytes();
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': contentType,
        },
        body: fileBytes,
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception('Cloudflare R2 upload failed with status ${uploadResponse.statusCode}');
      }

      return publicUrl;
    } catch (e) {
      print('R2 Upload Error: $e');
      rethrow;
    }
  }

  String _getContentType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
