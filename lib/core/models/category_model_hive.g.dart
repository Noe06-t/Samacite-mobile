// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryModelHiveAdapter extends TypeAdapter<CategoryModelHive> {
  @override
  final int typeId = 2;

  @override
  CategoryModelHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryModelHive(
      id: fields[0] as int,
      name: fields[1] as String,
      description: fields[2] as String?,
      icon: fields[3] as String?,
      createdAt: fields[4] as String?,
      updatedAt: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryModelHive obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModelHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
