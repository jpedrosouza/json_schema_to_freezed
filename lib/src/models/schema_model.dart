/// Represents a complete schema with multiple models
class Schema {
  final List<Model> models;
  final String? version;
  final Map<String, dynamic>? metadata;

  Schema({
    required this.models,
    this.version,
    this.metadata,
  });
}

/// Represents a model or entity in the schema
class Model {
  final String name;
  final List<Field> fields;
  final String? description;
  final bool isEnum;

  Model({
    required this.name,
    required this.fields,
    this.description,
    this.isEnum = false,
  });
}

/// Represents a field in a model
class Field {
  final String name;
  final FieldType type;
  final bool isNullable;
  final String? description;
  final bool isId;
  final bool isUnique;
  final Map<String, dynamic>? attributes;

  Field({
    required this.name,
    required this.type,
    this.isNullable = false,
    this.description,
    this.isId = false,
    this.isUnique = false,
    this.attributes,
  });
}

/// Type of a field
class FieldType {
  final TypeKind kind;
  final FieldType? itemType; // For arrays
  final String? reference;   // For references to other models

  FieldType({
    required this.kind,
    this.itemType,
    this.reference,
  });
}

/// Enumeration of possible field types
enum TypeKind {
  string,
  integer,
  float,
  boolean,
  dateTime,
  array,
  map,
  reference,
  enum_,
  unknown,
}