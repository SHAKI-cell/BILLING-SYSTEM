import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/features/product/domain/entities/lookup_product.dart';
import 'package:billing_app/features/product/domain/services/product_lookup_service.dart';
import 'package:billing_app/features/product/domain/repositories/product_lookup_repository.dart';

class FakeLookupService implements ProductLookupService {
  final String _providerName;
  final Map<String, LookupProduct> _db;

  FakeLookupService(this._providerName, this._db);

  @override
  String get providerName => _providerName;

  @override
  Future<LookupProduct?> lookup(String barcode) async {
    return _db[barcode];
  }
}

void main() {
  group('ProductLookupRepository tests', () {
    test('Sequential service execution - returns first non-null match', () async {
      final db1 = {
        '111': const LookupProduct(barcode: '111', productName: 'Service 1 Product'),
      };
      final db2 = {
        '111': const LookupProduct(barcode: '111', productName: 'Service 2 Product'),
        '222': const LookupProduct(barcode: '222', productName: 'Service 2 Product'),
      };

      final service1 = FakeLookupService('Service1', db1);
      final service2 = FakeLookupService('Service2', db2);

      final repository = ProductLookupRepository(services: [service1, service2]);

      // Scans '111': Service 1 should respond first
      final result1 = await repository.lookup('111');
      expect(result1, isNotNull);
      expect(result1!.productName, 'Service 1 Product');

      // Scans '222': Service 1 doesn't have it, Service 2 should respond
      final result2 = await repository.lookup('222');
      expect(result2, isNotNull);
      expect(result2!.productName, 'Service 2 Product');

      // Scans '333': Neither service has it
      final result3 = await repository.lookup('333');
      expect(result3, isNull);
    });
  });
}
