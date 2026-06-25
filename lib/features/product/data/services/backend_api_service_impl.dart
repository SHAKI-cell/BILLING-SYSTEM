import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../../../core/data/hive_database.dart';
import '../../domain/entities/product.dart';
import '../../domain/services/backend_api_service.dart';

class BackendApiServiceImpl implements BackendApiService {
  final HttpClient _client = HttpClient();

  String get _baseUrl {
    final url = HiveDatabase.settingsBox.get('backend_api_url', defaultValue: 'http://10.0.2.2:8000');
    // Normalize URL
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  @override
  Future<Product?> lookupProduct(String barcode) async {
    try {
      final base = _baseUrl;
      if (base.isEmpty) return null;

      final uri = Uri.parse('$base/api/products/$barcode');
      final request = await _client.getUrl(uri).timeout(const Duration(milliseconds: 1500));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(responseBody);
        return _mapJsonToProduct(data);
      }
    } catch (e) {
      print('Backend Cloud Database Lookup Error: $e');
    }
    return null;
  }

  @override
  Future<Product?> recognizeProduct(Uint8List imageBytes, String barcode) async {
    try {
      final base = _baseUrl;
      if (base.isEmpty) return null;

      final uri = Uri.parse('$base/api/recognize');
      final request = await _client.postUrl(uri).timeout(const Duration(seconds: 15));
      request.headers.contentType = ContentType.json;
      request.headers.set('Accept-Language', 'hi-IN,hi;q=0.9,en-IN;q=0.8,en;q=0.7');

      final body = {
        'barcode': barcode,
        'image': base64Encode(imageBytes),
        'language': 'hi',
        'locale': 'hi_IN',
        'language_preference': 'Hindi/English',
      };

      request.write(jsonEncode(body));
      final response = await request.close();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(responseBody);
        return _mapJsonToProduct(data);
      }
    } catch (e) {
      print('Backend AI Recognition Request Error: $e');
    }
    return null;
  }

  Product _mapJsonToProduct(Map<String, dynamic> data) {
    // Map backend JSON to clean Product entity
    return Product(
      id: data['id'] ?? data['barcode'] ?? '',
      name: data['name'] ?? data['productName'] ?? 'Unknown Product',
      barcode: data['barcode'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      stock: data['stock'] ?? 0,
      imageUrl: data['imageUrl'] ?? data['image_url'],
      brand: data['brand'],
      variant: data['variant'],
      weight: data['weight'] ?? data['quantity'],
      category: data['category'],
      mrp: data['mrp'] != null ? (data['mrp'] as num).toDouble() : null,
      manufacturer: data['manufacturer'],
      needsVerification: data['needsVerification'] == true || data['needs_verification'] == true,
      adminReview: data['adminReview'] == true || data['admin_review'] == true,
      aiConfidence: data['aiConfidence'] != null ? (data['aiConfidence'] as num).toDouble() : null,
      recognitionTime: data['recognitionTime'] as int?,
      aiProvider: data['aiProvider']?.toString(),
      modelVersion: data['modelVersion']?.toString(),
    );
  }
}
