// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 0;

  @override
  ProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductModel(
      id: fields[0] as String,
      name: fields[1] as String,
      barcode: fields[2] as String,
      price: fields[3] as double,
      stock: fields[4] as int,
      imageUrl: fields[5] as String?,
      brand: fields[6] as String?,
      variant: fields[7] as String?,
      weight: fields[8] as String?,
      category: fields[9] as String?,
      mrp: fields[10] as double?,
      manufacturer: fields[11] as String?,
      needsVerification: fields[12] == true,
      adminReview: fields[13] == true,
      aiConfidence: fields[14] as double?,
      recognitionTime: fields[15] as int?,
      aiProvider: fields[16] as String?,
      modelVersion: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.barcode)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.stock)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.brand)
      ..writeByte(7)
      ..write(obj.variant)
      ..writeByte(8)
      ..write(obj.weight)
      ..writeByte(9)
      ..write(obj.category)
      ..writeByte(10)
      ..write(obj.mrp)
      ..writeByte(11)
      ..write(obj.manufacturer)
      ..writeByte(12)
      ..write(obj.needsVerification)
      ..writeByte(13)
      ..write(obj.adminReview)
      ..writeByte(14)
      ..write(obj.aiConfidence)
      ..writeByte(15)
      ..write(obj.recognitionTime)
      ..writeByte(16)
      ..write(obj.aiProvider)
      ..writeByte(17)
      ..write(obj.modelVersion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
