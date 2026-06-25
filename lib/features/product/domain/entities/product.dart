import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id; // Using barcode as ID usually, but keeping separate ID is safer
  final String name;
  final String barcode;
  final double price;
  final int stock; // Optional implementation detail
  final String? imageUrl;
  final String? brand;
  final String? variant;
  final String? weight;
  final String? category;
  final double? mrp;
  final String? manufacturer;
  final bool needsVerification;
  final bool adminReview;
  final double? aiConfidence;
  final int? recognitionTime;
  final String? aiProvider;
  final String? modelVersion;

  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    this.stock = 0,
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
  });

  @override
  List<Object?> get props => [
        id,
        name,
        barcode,
        price,
        stock,
        imageUrl,
        brand,
        variant,
        weight,
        category,
        mrp,
        manufacturer,
        needsVerification,
        adminReview,
        aiConfidence,
        recognitionTime,
        aiProvider,
        modelVersion,
      ];
}
