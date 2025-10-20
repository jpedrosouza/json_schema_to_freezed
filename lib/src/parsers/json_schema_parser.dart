import '../models/schema_model.dart';
import 'package:recase/recase.dart';

/// Parser to convert JSON Schema into internal models
class JsonSchemaParser {
  Future<Schema> parse(dynamic jsonData, bool useClassId) async {
    final models = <Model>[];
    
    // Check if we are dealing with a root object that contains multiple models
    if (jsonData is Map<String, dynamic>) {
      // Iterate through each entry in the main object
      jsonData.forEach((modelName, modelData) {
        // Check if the model has the expected format (with 'schema' and 'description')
        if (modelData is Map<String, dynamic> && modelData.containsKey('schema')) {
          final schema = modelData['schema'] as Map<String, dynamic>;
          final description = modelData['description'] as String?;

          // Extract properties from the schema
          if (schema.containsKey('properties')) {
            final model = _parseModel(modelName, schema, description);
            models.add(model);
          }
        } else if (modelData is Map<String, dynamic> && modelData.containsKey('properties')) {
          // Alternative format where the schema is directly in the object
          final model = _parseModel(modelName, modelData);
          models.add(model);
        } else if (modelData is Map<String, dynamic> && modelData.containsKey('definitions')) {
          // Format with 'definitions'
          final definitions = modelData['definitions'] as Map<String, dynamic>;
          definitions.forEach((defName, defValue) {
            models.add(_parseModel('${modelName}_$defName', defValue));
          });
        }
      });
    }
    
    // If no models were found, try as a single schema
    if (models.isEmpty && jsonData is Map<String, dynamic> && jsonData.containsKey('properties')) {
      final classId = useClassId ? jsonData['\$id'] as String : null;
      final String modelName = classId ?? 'Root';
      models.add(_parseModel(modelName, jsonData));
    }
    
    return Schema(
      models: models,
      version: jsonData['\$schema'] as String?,
    );
  }

  Model _parseModel(String name, dynamic modelData, [String? description]) {
    final fields = <Field>[];
    
    if (modelData.containsKey('properties')) {
      final properties = modelData['properties'] as Map<String, dynamic>;
      final required = modelData['required'] is List
          ? (modelData['required'] as List).cast<String>()
          : <String>[];
      
      // Check if there is a property ordering
      List<String>? propertyOrder;
      if (modelData.containsKey('propertyOrder') && modelData['propertyOrder'] is List) {
        propertyOrder = (modelData['propertyOrder'] as List).cast<String>();
      }

      // List of ordered properties, if possible
      final orderedProps = propertyOrder != null
          ? [...propertyOrder]
          : properties.keys.toList();

      // Add properties that are not in the order but exist
      for (final key in properties.keys) {
        if (!orderedProps.contains(key)) {
          orderedProps.add(key);
        }
      }

      // Process properties in the correct order
      for (final propName in orderedProps) {
        if (properties.containsKey(propName)) {
          fields.add(_parseField(
            propName,
            properties[propName],
            isNullable: !required.contains(propName),
          ));
        }
      }
    }
    
    return Model(
      name: _formatClassName(name),
      fields: fields,
      description: description ?? modelData['description'] as String?,
    );
  }

  Field _parseField(String name, dynamic fieldData, {bool isNullable = false}) {
    return Field(
      name: name,
      type: _parseFieldType(fieldData),
      isNullable: isNullable,
      description: fieldData['description'] as String?,
    );
  }

  FieldType _parseFieldType(dynamic typeData) {
    if (typeData.containsKey('\$ref')) {
      final ref = typeData['\$ref'] as String;
      final refName = ref.split('/').last;
      return FieldType(
        kind: TypeKind.reference,
        reference: _formatClassName(refName),
      );
    }
    
    final type = typeData['type'];
    
    switch (type) {
      case 'string':
        if (typeData['format'] == 'date-time') {
          return FieldType(kind: TypeKind.dateTime);
        }
        return FieldType(kind: TypeKind.string);
      case 'integer':
        return FieldType(kind: TypeKind.integer);
      case 'number':
        return FieldType(kind: TypeKind.float);
      case 'boolean':
        return FieldType(kind: TypeKind.boolean);
      case 'array':
        return FieldType(
          kind: TypeKind.array,
          itemType: _parseFieldType(typeData['items']),
        );
      case 'object':
        return FieldType(kind: TypeKind.map);
      default:
        return FieldType(kind: TypeKind.unknown);
    }
  }

  String _formatClassName(String name) {
    // Use recase for consistent formatting
    ReCase rc = ReCase(name);
    String className = rc.pascalCase;

    // Replace Params with AdapterParams
    if (className.endsWith('Params')) {
      className = '${className.substring(0, className.length - 'Params'.length)}AdapterParams';
    }
    
    return className;
  }
}