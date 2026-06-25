import 'dart:typed_data';
import '../entities/product.dart';

abstract class BackendApiService {
  /// Calls the FastAPI/Flask backend at `/api/recognize` to execute 
  /// the asynchronous Celery + Redis AI recognition pipeline.
  Future<Product?> recognizeProduct(Uint8List imageBytes, String barcode);

  /// Calls the backend at `/api/products/{barcode}` to perform 
  /// a cloud database query to fetch matching product info.
  Future<Product?> lookupProduct(String barcode);
}
