import 'package:hive/hive.dart';
import '../../domain/entities/product.dart';

part 'product_model.g.dart'; // Hive generator

@HiveType(typeId: 0)
class ProductModel extends Product {
  @override
  @HiveField(0)
  final String id;
  @override
  @HiveField(1)
  final String name;
  @override
  @HiveField(2)
  final String barcode;
  @override
  @HiveField(3)
  final double price;
  @override
  @HiveField(4)
  final int stock;
  @override
  @HiveField(5)
  final String? imageUrl;
  @override
  @HiveField(6)
  final String? brand;
  @override
  @HiveField(7)
  final String? variant;
  @override
  @HiveField(8)
  final String? weight;
  @override
  @HiveField(9)
  final String? category;
  @override
  @HiveField(10)
  final double? mrp;
  @override
  @HiveField(11)
  final String? manufacturer;
  @override
  @HiveField(12)
  final bool needsVerification;
  @override
  @HiveField(13)
  final bool adminReview;
  @override
  @HiveField(14)
  final double? aiConfidence;
  @override
  @HiveField(15)
  final int? recognitionTime;
  @override
  @HiveField(16)
  final String? aiProvider;
  @override
  @HiveField(17)
  final String? modelVersion;

  const ProductModel({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.brand,
    this.variant,
    this.weight,
    this.category,
    this.mrp,
    this.manufacturer,
    this.needsVerification = false,
    this.adminReview = false,
    this.aiConfidence,
    this.recognitionTime,
    this.aiProvider,
    this.modelVersion,
  }) : super(
          id: id,
          name: name,
          barcode: barcode,
          price: price,
          stock: stock,
          imageUrl: imageUrl,
          brand: brand,
          variant: variant,
          weight: weight,
          category: category,
          mrp: mrp,
          manufacturer: manufacturer,
          needsVerification: needsVerification,
          adminReview: adminReview,
          aiConfidence: aiConfidence,
          recognitionTime: recognitionTime,
          aiProvider: aiProvider,
          modelVersion: modelVersion,
        );

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      barcode: product.barcode,
      price: product.price,
      stock: product.stock,
      imageUrl: product.imageUrl,
      brand: product.brand,
      variant: product.variant,
      weight: product.weight,
      category: product.category,
      mrp: product.mrp,
      manufacturer: product.manufacturer,
      needsVerification: product.needsVerification,
      adminReview: product.adminReview,
      aiConfidence: product.aiConfidence,
      recognitionTime: product.recognitionTime,
      aiProvider: product.aiProvider,
      modelVersion: product.modelVersion,
    );
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      barcode: barcode,
      price: price,
      stock: stock,
      imageUrl: imageUrl,
      brand: brand,
      variant: variant,
      weight: weight,
      category: category,
      mrp: mrp,
      manufacturer: manufacturer,
      needsVerification: needsVerification,
      adminReview: adminReview,
      aiConfidence: aiConfidence,
      recognitionTime: recognitionTime,
      aiProvider: aiProvider,
      modelVersion: modelVersion,
    );
  }
}
