import '../entities/lookup_product.dart';
import '../services/product_lookup_service.dart';

class ProductLookupRepository {
  final List<ProductLookupService> _services;

  ProductLookupRepository({required List<ProductLookupService> services})
      : _services = services;

  Future<LookupProduct?> lookup(String barcode) async {
    for (final service in _services) {
      final result = await service.lookup(barcode);
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}
