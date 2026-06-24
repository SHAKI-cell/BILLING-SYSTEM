import '../entities/lookup_product.dart';

abstract class ProductLookupService {
  String get providerName;
  Future<LookupProduct?> lookup(String barcode);
}
