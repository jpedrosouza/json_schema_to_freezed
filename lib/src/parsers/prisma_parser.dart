import '../models/schema_model.dart';

/// Parser para converter Prisma Schema em modelos internos
class PrismaParser {
  Future<Schema> parse(String content) async {
    final models = <Model>[];
    final lines = content.split('\n');
    
    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();
      
      if (line.startsWith('model ')) {
        final modelResult = _parseModelBlock(lines, i);
        models.add(modelResult.model);
        i = modelResult.endIndex;
      } else if (line.startsWith('enum ')) {
        final enumResult = _parseEnumBlock(lines, i);
        models.add(enumResult.model);
        i = enumResult.endIndex;
      } else {
        i++;
      }
    }
    
    return Schema(models: models);
  }

  _ModelParseResult _parseModelBlock(List<String> lines, int startIndex) {
    final firstLine = lines[startIndex].trim();
    final modelName = firstLine.split(' ')[1].trim();
    
    final fields = <Field>[];
    int i = startIndex + 1;
    
    // Ignorar a linha com "{"
    if (lines[i].trim() == '{') {
      i++;
    }
    
    // Processar cada linha até fechar o bloco
    while (i < lines.length && lines[i].trim() != '}') {
      final line = lines[i].trim();
      
      if (line.isNotEmpty && !line.startsWith('//')) {
        final fieldResult = _parseFieldLine(line);
        if (fieldResult != null) {
          fields.add(fieldResult);
        }
      }
      
      i++;
    }
    
    return _ModelParseResult(
      model: Model(
        name: modelName,
        fields: fields,
      ),
      endIndex: i + 1,
    );
  }

  _ModelParseResult _parseEnumBlock(List<String> lines, int startIndex) {
    final firstLine = lines[startIndex].trim();
    final enumName = firstLine.split(' ')[1].trim();
    
    final values = <Field>[];
    int i = startIndex + 1;
    
    // Ignorar a linha com "{"
    if (lines[i].trim() == '{') {
      i++;
    }
    
    // Processar cada valor do enum
    while (i < lines.length && lines[i].trim() != '}') {
      final line = lines[i].trim();
      
      if (line.isNotEmpty && !line.startsWith('//')) {
        // Remover comentários
        final valueContent = line.split('//')[0].trim();
        if (valueContent.isNotEmpty) {
          values.add(Field(
            name: valueContent,
            type: FieldType(kind: TypeKind.string),
          ));
        }
      }
      
      i++;
    }
    
    return _ModelParseResult(
      model: Model(
        name: enumName,
        fields: values,
        isEnum: true,
      ),
      endIndex: i + 1,
    );
  }

  Field? _parseFieldLine(String line) {
    // Ignorar linhas não relevantes
    if (line.isEmpty || line.startsWith('//')) {
      return null;
    }
    
    // Quebrar em nome e tipo
    final parts = line.split(' ');
    if (parts.length < 2) {
      return null;
    }
    
    final fieldName = parts[0].trim();
    String fieldTypePart = parts[1].trim();
    
    // Remover qualquer coisa após o tipo (atributos, comentários)
    if (fieldTypePart.contains('@') || fieldTypePart.contains('//')) {
      fieldTypePart = fieldTypePart.split(RegExp(r'@|//'))[0].trim();
    }
    
    // Verificar se é opcional
    bool isNullable = fieldTypePart.endsWith('?');
    if (isNullable) {
      fieldTypePart = fieldTypePart.substring(0, fieldTypePart.length - 1);
    }
    
    // Verificar se é um array
    bool isArray = fieldTypePart.endsWith('[]');
    if (isArray) {
      fieldTypePart = fieldTypePart.substring(0, fieldTypePart.length - 2);
    }
    
    // Converter tipo Prisma para tipo interno
    final fieldType = _mapPrismaTypeToFieldType(fieldTypePart);
    
    // Ajustar se for array
    FieldType finalType = fieldType;
    if (isArray) {
      finalType = FieldType(
        kind: TypeKind.array,
        itemType: fieldType,
      );
    }
    
    return Field(
      name: fieldName,
      type: finalType,
      isNullable: isNullable,
    );
  }

  FieldType _mapPrismaTypeToFieldType(String prismaType) {
    switch (prismaType.toLowerCase()) {
      case 'string':
        return FieldType(kind: TypeKind.string);
      case 'int':
        return FieldType(kind: TypeKind.integer);
      case 'float':
      case 'decimal':
        return FieldType(kind: TypeKind.float);
      case 'boolean':
      case 'bool':
        return FieldType(kind: TypeKind.boolean);
      case 'datetime':
      case 'date':
        return FieldType(kind: TypeKind.dateTime);
      case 'json':
        return FieldType(kind: TypeKind.map);
      default:
        // Assumir que é uma referência a outro modelo ou enum
        return FieldType(
          kind: TypeKind.reference,
          reference: prismaType,
        );
    }
  }
}

class _ModelParseResult {
  final Model model;
  final int endIndex;

  _ModelParseResult({
    required this.model,
    required this.endIndex,
  });
}