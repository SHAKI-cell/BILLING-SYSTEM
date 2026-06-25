import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';

import 'package:billing_app/core/data/hive_database.dart';
import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/features/product/data/models/product_model.dart';
import 'package:billing_app/features/product/data/repositories/product_repository_impl.dart';
import 'package:billing_app/features/product/data/services/backend_api_service_impl.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/services/backend_api_service.dart';
import 'package:billing_app/features/product/domain/repositories/product_repository.dart';
import 'package:billing_app/features/product/domain/usecases/product_usecases.dart';
import 'package:billing_app/features/product/domain/usecases/recognize_product_usecase.dart';
import 'package:billing_app/features/billing/presentation/bloc/billing_bloc.dart';

// Fake implementations for Bloc Testing
class FakeGetProductByBarcodeUseCase implements GetProductByBarcodeUseCase {
  final Product? Function(String) lookup;
  FakeGetProductByBarcodeUseCase(this.lookup);

  @override
  ProductRepository get repository => throw UnimplementedError();

  @override
  Future<Either<Failure, Product>> call(String params) async {
    final p = lookup(params);
    if (p != null) {
      return Right(p);
    }
    return Left(CacheFailure('Not found'));
  }
}

class FakeRecognizeProductUseCase implements RecognizeProductUseCase {
  final Product? Function(String, Uint8List) recognize;
  FakeRecognizeProductUseCase(this.recognize);

  @override
  BackendApiService get apiService => throw UnimplementedError();
  @override
  ProductRepository get repository => throw UnimplementedError();

  @override
  Future<Either<Failure, Product>> call(RecognizeProductParams params) async {
    final p = recognize(params.barcode, params.imageBytes);
    if (p != null) {
      return Right(p);
    }
    return Left(CacheFailure('AI failure'));
  }
}

void main() {
  late Directory tempDir;
  late HttpServer server;
  late BackendApiServiceImpl apiService;
  late ProductRepositoryImpl repository;

  setUpAll(() async {
    // Initialize temporary Hive database directory
    tempDir = Directory.systemTemp.createTempSync('hive_test_api');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProductModelAdapter());
    }
  });

  tearDownAll(() async {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    // Re-open/clear boxes for each test
    await Hive.openBox<ProductModel>(HiveDatabase.productBoxName);
    await Hive.openBox(HiveDatabase.settingsBoxName);
    await HiveDatabase.productBox.clear();
    await HiveDatabase.settingsBox.clear();

    // Start local server to intercept requests
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    HiveDatabase.settingsBox.put('backend_api_url', 'http://localhost:${server.port}');

    apiService = BackendApiServiceImpl();
    repository = ProductRepositoryImpl(backendApiService: apiService);
  });

  tearDown(() async {
    await server.close();
    await HiveDatabase.productBox.close();
    await HiveDatabase.settingsBox.close();
  });

  group('Backend API Client REST Serialization', () {
    test('lookupProduct handles successful response & serializes fields correctly', () async {
      server.listen((HttpRequest request) {
        expect(request.uri.path, '/api/products/12345');
        expect(request.method, 'GET');

        final responsePayload = {
          'id': 'prod_123',
          'name': 'Matcha Green Tea',
          'barcode': '12345',
          'price': 249.99,
          'stock': 12,
          'imageUrl': 'https://example.com/matcha.jpg',
          'brand': 'ZenTea',
          'variant': 'Premium Grade',
          'weight': '100g',
          'category': 'Tea',
          'mrp': 299.00,
          'manufacturer': 'Zen Foods Ltd',
          'needsVerification': false,
          'adminReview': false,
          'aiConfidence': 0.98,
          'recognitionTime': 350,
          'aiProvider': 'gemini-1.5-pro',
          'modelVersion': 'v1.5'
        };

        request.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode(responsePayload))
          ..close();
      });

      final product = await apiService.lookupProduct('12345');

      expect(product, isNotNull);
      expect(product!.id, 'prod_123');
      expect(product.name, 'Matcha Green Tea');
      expect(product.barcode, '12345');
      expect(product.price, 249.99);
      expect(product.imageUrl, 'https://example.com/matcha.jpg');
      expect(product.brand, 'ZenTea');
      expect(product.variant, 'Premium Grade');
      expect(product.weight, '100g');
      expect(product.category, 'Tea');
      expect(product.mrp, 299.00);
      expect(product.manufacturer, 'Zen Foods Ltd');
      expect(product.needsVerification, false);
      expect(product.adminReview, false);
      expect(product.aiConfidence, 0.98);
      expect(product.recognitionTime, 350);
      expect(product.aiProvider, 'gemini-1.5-pro');
      expect(product.modelVersion, 'v1.5');
    });

    test('recognizeProduct serializes base64 image request & handles response', () async {
      final sampleImageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      server.listen((HttpRequest request) async {
        expect(request.uri.path, '/api/recognize');
        expect(request.method, 'POST');
        expect(request.headers.contentType?.mimeType, 'application/json');

        // Verify request payload contains base64 image and barcode
        final bodyStr = await request.cast<List<int>>().transform(utf8.decoder).join();
        final bodyJson = jsonDecode(bodyStr);
        expect(bodyJson['barcode'], '98765');
        expect(bodyJson['image'], base64Encode(sampleImageBytes));

        final responsePayload = {
          'id': 'prod_987',
          'name': 'Unknown Product (98765)',
          'barcode': '98765',
          'price': 0.0,
          'needsVerification': true,
          'aiConfidence': 0.45,
          'aiProvider': 'gemini-1.5-flash'
        };

        request.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode(responsePayload))
          ..close();
      });

      final product = await apiService.recognizeProduct(sampleImageBytes, '98765');

      expect(product, isNotNull);
      expect(product!.name, 'Unknown Product (98765)');
      expect(product.price, 0.0);
      expect(product.needsVerification, true);
      expect(product.aiConfidence, 0.45);
    });
  });

  group('Cache updating and repository integration', () {
    test('lookupProduct cache miss -> fetches cloud DB -> caches locally', () async {
      server.listen((HttpRequest request) {
        final responsePayload = {
          'id': 'prod_cache',
          'name': 'Cacheable Product',
          'barcode': '55555',
          'price': 15.0,
        };
        request.response
          ..headers.contentType = ContentType.json
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode(responsePayload))
          ..close();
      });

      // Initially local cache is empty
      expect(HiveDatabase.productBox.isEmpty, true);

      // Call repository - cache miss, should fetch from mock server
      final repoResult = await repository.getProductByBarcode('55555');
      expect(repoResult.isRight(), true);
      
      final product = repoResult.getOrElse((_) => throw Exception());
      expect(product.name, 'Cacheable Product');

      // Verify it got saved to local Hive cache
      expect(HiveDatabase.productBox.length, 1);
      final cached = HiveDatabase.productBox.get('prod_cache');
      expect(cached, isNotNull);
      expect(cached!.name, 'Cacheable Product');
    });
  });

  group('BillingBloc Background AI Flows', () {
    test('ScanBarcodeEvent adds product directly if found in cache/cloud', () async {
      final existingProduct = Product(
        id: 'prod_exist',
        name: 'Existing Chips',
        barcode: '11111',
        price: 45.0,
      );

      final fakeGetProduct = FakeGetProductByBarcodeUseCase((barcode) {
        if (barcode == '11111') return existingProduct;
        return null;
      });

      final fakeRecognize = FakeRecognizeProductUseCase((barcode, img) => null);

      final bloc = BillingBloc(
        getProductByBarcodeUseCase: fakeGetProduct,
        recognizeProductUseCase: fakeRecognize,
      );

      // Expect that scanning 11111 triggers AddProductToCartEvent directly
      bloc.add(const ScanBarcodeEvent('11111'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<BillingState>((state) =>
              state.cartItems.length == 1 &&
              state.cartItems[0].product.id == 'prod_exist'),
        ]),
      );

      await bloc.close();
    });

    test('ScanBarcodeEvent DB miss -> calls AI recognition & adds placeholder on low confidence', () async {
      final sampleImage = Uint8List.fromList([10, 20]);
      final placeholderProduct = Product(
        id: 'unknown_22222',
        name: 'Unknown Product (22222)',
        barcode: '22222',
        price: 0.0,
        needsVerification: true,
      );

      final fakeGetProduct = FakeGetProductByBarcodeUseCase((barcode) => null); // DB miss

      final fakeRecognize = FakeRecognizeProductUseCase((barcode, img) {
        expect(barcode, '22222');
        expect(img, sampleImage);
        return placeholderProduct;
      });

      final bloc = BillingBloc(
        getProductByBarcodeUseCase: fakeGetProduct,
        recognizeProductUseCase: fakeRecognize,
      );

      bloc.add(ScanBarcodeEvent('22222', imageBytes: sampleImage));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<BillingState>((state) =>
              state.cartItems.length == 1 &&
              state.cartItems[0].product.name == 'Unknown Product (22222)' &&
              state.cartItems[0].product.price == 0.0),
        ]),
      );

      await bloc.close();
    });

    test('ScanBarcodeEvent DB miss & AI offline/fails -> triggers manual fallback error', () async {
      final sampleImage = Uint8List.fromList([10, 20]);

      final fakeGetProduct = FakeGetProductByBarcodeUseCase((barcode) => null); // DB miss
      final fakeRecognize = FakeRecognizeProductUseCase((barcode, img) => null); // AI fails (returns null)

      final bloc = BillingBloc(
        getProductByBarcodeUseCase: fakeGetProduct,
        recognizeProductUseCase: fakeRecognize,
      );

      bloc.add(ScanBarcodeEvent('33333', imageBytes: sampleImage));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<BillingState>((state) =>
              state.error == 'Product not found: 33333'),
          predicate<BillingState>((state) => state.error == null), // clearError resets it
        ]),
      );

      await bloc.close();
    });
  });
}
