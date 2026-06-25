import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/services/backend_api_service.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final BackendApiService backendApiService;

  ProductRepositoryImpl({required this.backendApiService});

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final box = HiveDatabase.productBox;
      final products = box.values.toList();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    try {
      final searchVal = barcode.trim().toLowerCase();
      final box = HiveDatabase.productBox;
      
      // 1. Query Hive Local Cache first (<20ms)
      final cachedIndex = box.values.toList().indexWhere(
        (element) =>
            element.barcode.trim().toLowerCase() == searchVal ||
            element.id.trim().toLowerCase() == searchVal,
      );
      
      if (cachedIndex >= 0) {
        final cachedProduct = box.values.toList().elementAt(cachedIndex);
        return Right(cachedProduct);
      }

      // 2. Cache Miss -> Query Cloud Database Lookup (<100ms)
      final cloudProduct = await backendApiService.lookupProduct(barcode);
      if (cloudProduct != null) {
        // Cache locally for faster future scans
        await addProduct(cloudProduct);
        return Right(cloudProduct);
      }

      return Left(CacheFailure('Product not found in local cache or cloud database'));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addProduct(Product product) async {
    try {
      final box = HiveDatabase.productBox;
      // You can use add() or put()
      final model = ProductModel.fromEntity(product);
      await box.put(model.id, model); // Using ID as key
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    try {
      final box = HiveDatabase.productBox;
      final model = ProductModel.fromEntity(product);
      await box.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      final box = HiveDatabase.productBox;
      await box.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
