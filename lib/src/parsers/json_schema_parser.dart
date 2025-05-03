import '../models/schema_model.dart';
import 'package:recase/recase.dart';

/// Parser para converter JSON Schema em modelos internos
class JsonSchemaParser {
  Future<Schema> parse(dynamic jsonData) async {
    final models = <Model>[];
    
    // Verificar se estamos lidando com um objeto raiz que contém vários modelos
    if (jsonData is Map<String, dynamic>) {
      // Iterar por cada entrada no objeto principal
      jsonData.forEach((modelName, modelData) {
        // Verificar se o modelo tem o formato esperado (com 'schema' e 'description')
        if (modelData is Map<String, dynamic> && modelData.containsKey('schema')) {
          final schema = modelData['schema'] as Map<String, dynamic>;
          final description = modelData['description'] as String?;
          
          // Extrair propriedades do schema
          if (schema.containsKey('properties')) {
            final model = _parseModel(modelName, schema, description);
            models.add(model);
          }
        } else if (modelData is Map<String, dynamic> && modelData.containsKey('properties')) {
          // Formato alternativo onde o schema está diretamente no objeto
          final model = _parseModel(modelName, modelData);
          models.add(model);
        } else if (modelData is Map<String, dynamic> && modelData.containsKey('definitions')) {
          // Formato com 'definitions'
          final definitions = modelData['definitions'] as Map<String, dynamic>;
          definitions.forEach((defName, defValue) {
            models.add(_parseModel('${modelName}_$defName', defValue));
          });
        }
      });
    }
    
    // Se não encontrou modelos, tente como um único schema
    if (models.isEmpty && jsonData is Map<String, dynamic> && jsonData.containsKey('properties')) {
      models.add(_parseModel('Root', jsonData));
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
      
      // Verificar se existe uma ordenação de propriedades
      List<String>? propertyOrder;
      if (modelData.containsKey('propertyOrder') && modelData['propertyOrder'] is List) {
        propertyOrder = (modelData['propertyOrder'] as List).cast<String>();
      }
      
      // Lista de propriedades ordenadas, se possível
      final orderedProps = propertyOrder != null
          ? [...propertyOrder]
          : properties.keys.toList();
          
      // Adicionar propriedades que não estão na ordem, mas existem
      for (final key in properties.keys) {
        if (!orderedProps.contains(key)) {
          orderedProps.add(key);
        }
      }
      
      // Processar as propriedades na ordem correta
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
    // Usar recase para formatação consistente
    ReCase rc = ReCase(name);
    String className = rc.pascalCase;
    
    // Substituir Params por AdapterParams
    if (className.endsWith('Params')) {
      className = className.substring(0, className.length - 'Params'.length) + 'AdapterParams';
    }
    
    return className;
  }
}