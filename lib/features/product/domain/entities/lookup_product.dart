import 'package:equatable/equatable.dart';

class LookupProduct extends Equatable {
  final String barcode;
  final String productName;
  final String? brand;
  final String? category;
  final String? quantity;
  final String? imageUrl;

  const LookupProduct({
    required this.barcode,
    required this.productName,
    this.brand,
    this.category,
    this.quantity,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
        barcode,
        productName,
        brand,
        category,
        quantity,
        imageUrl,
      ];
}
