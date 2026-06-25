import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';
import '../services/backend_api_service.dart';

class RecognizeProductParams {
  final Uint8List imageBytes;
  final String barcode;

  RecognizeProductParams({required this.imageBytes, required this.barcode});
}

class RecognizeProductUseCase implements UseCase<Product, RecognizeProductParams> {
  final BackendApiService apiService;
  final ProductRepository repository;

  RecognizeProductUseCase({
    required this.apiService,
    required this.repository,
  });

  @override
  Future<Either<Failure, Product>> call(RecognizeProductParams params) async {
    try {
      final product = await apiService.recognizeProduct(params.imageBytes, params.barcode);
      if (product != null) {
        // Cache locally in Hive for fast future scans
        await repository.addProduct(product);
        return Right(product);
      }
      return Left(CacheFailure('AI Recognition failed or returned low confidence.'));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
