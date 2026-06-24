import 'dart:convert';
import 'dart:io';
import '../../domain/entities/lookup_product.dart';
import '../../domain/services/product_lookup_service.dart';

class OpenFoodFactsService implements ProductLookupService {
  @override
  String get providerName => 'Open Food Facts';

  @override
  Future<LookupProduct?> lookup(String barcode) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 10));
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(responseBody);
        if (data['status'] == 1 && data['product'] != null) {
          final productData = data['product'];
          final name = productData['product_name'] ?? productData['product_name_en'] ?? '';
          if (name.toString().trim().isEmpty) return null;
          
          return LookupProduct(
            barcode: barcode,
            productName: name.toString().trim(),
            brand: productData['brands']?.toString().trim(),
            category: productData['categories']?.toString().trim(),
            quantity: productData['quantity']?.toString().trim(),
            imageUrl: productData['image_url']?.toString().trim() ?? productData['image_front_url']?.toString().trim(),
          );
        }
      }
    } catch (_) {
      // Fail silently to let fallback/other services be tried
    } finally {
      client.close();
    }
    return null;
  }
}
