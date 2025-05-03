import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

import 'models/schema_model.dart';
import 'parsers/json_schema_parser.dart';

/// Classe principal que gerencia a conversão de schemas para classes Dart/Freezed
class JsonSchemaToFreezed {
  final bool freezed;
  final bool jsonSerializable;
  final Map<String, String> headers;

  JsonSchemaToFreezed({
    this.freezed = true,
    this.jsonSerializable = true,
    this.headers = const {},
  });

  /// Converte schema de uma URL para classes Dart/Freezed
  Future<bool> convertFromUrl(String url, String outputPath) async {
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to retrieve schema. Status: ${response.statusCode}');
      }
      
      final jsonData = json.decode(response.body);
      return _processSchemaData(jsonData, outputPath);
    } catch (e) {
      print('Error converting from URL: $e');
      return false;
    }
  }

  /// Converte schema de um arquivo local para classes Dart/Freezed
  Future<bool> convertFromFile(String filePath, String outputPath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }
      
      final content = await file.readAsString();
      final extension = path.extension(filePath).toLowerCase();
      
      if (extension == '.json') {
        final jsonData = json.decode(content);
        return _processSchemaData(jsonData, outputPath);
      } else {
        throw Exception('Unsupported file format: $extension. Use .json');
      }
    } catch (e) {
      print('Error converting from file: $e');
      return false;
    }
  }

Future<bool> _processSchemaData(dynamic jsonData, String outputPath) async {
    final parser = JsonSchemaParser();
    final schema = await parser.parse(jsonData);
    
    // Transform model names to use AdapterParams instead of Params
    for (var model in schema.models) {
      if (model.name.endsWith('Params')) {
        model.name = '${model.name.substring(0, model.name.length - 'Params'.length)}AdapterParams';
      }
    }
    
    // Verificar se o usuário solicitou arquivos separados
    final generateSeparateFiles = outputPath.contains("*");
    
    if (generateSeparateFiles) {
      return _generateSeparateFiles(schema, outputPath);
    } else {
      return _generateDartClasses(schema, outputPath);
    }
  }

  Future<bool> _generateSeparateFiles(Schema schema, String outputPathTemplate) async {
    try {
      bool allSuccess = true;
      final directory = Directory(path.dirname(outputPathTemplate.replaceAll("*", "")));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      for (final model in schema.models) {
        // Obter o nome do arquivo em snake_case
        String fileName = ReCase(model.name).snakeCase;
        
        // Substituir "adapter_params" por "adapter_params" no nome do arquivo para manter consistência
        if (fileName.endsWith('_adapter_params')) {
          fileName = '${fileName.substring(0, fileName.length - '_adapter_params'.length)}_adapter';
        } else if (fileName.endsWith('_params')) {
          // Manter compatibilidade com código existente que pode ainda usar _params
          fileName = '${fileName.substring(0, fileName.length - '_params'.length)}_adapter';
        }
        
        // Gerar o caminho do arquivo sem adicionar "generated_" como prefixo
        final outputPath = outputPathTemplate.replaceAll("*", fileName);
        
        final output = File(outputPath);
        final buffer = StringBuffer();
        
        // Adicionar imports necessários
        if (freezed) {
          buffer.writeln("// GENERATED CODE - NÃO MODIFIQUE MANUALMENTE");
          buffer.writeln("// Gerado em: ${DateTime.now().toIso8601String()}");
          buffer.writeln();
          buffer.writeln("import 'package:freezed_annotation/freezed_annotation.dart';");
          
          if (jsonSerializable) {
            buffer.writeln("import 'package:json_annotation/json_annotation.dart';");
          }
          
          buffer.writeln("import 'dart:convert';");
          buffer.writeln();
          
          final fileNameBase = path.basenameWithoutExtension(outputPath);
          buffer.writeln("part '$fileNameBase.freezed.dart';");
          
          if (jsonSerializable) {
            buffer.writeln("part '$fileNameBase.g.dart';");
          }
          
          buffer.writeln();
        }
        
        // Gerar classe para este modelo
        _generateModelClass(buffer, model);
        
        await output.writeAsString(buffer.toString());
        print('✅ Class generated: ${model.name} -> $outputPath');
      }
      
      return allSuccess;
    } catch (e) {
      print('Error generating Dart classes: $e');
      return false;
    }
  }

  Future<bool> _generateDartClasses(Schema schema, String outputPath) async {
    try {
      final directory = Directory(path.dirname(outputPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      final output = File(outputPath);
      final buffer = StringBuffer();
      
      // Adicionar imports necessários
      if (freezed) {
        buffer.writeln("// GENERATED CODE - NÃO MODIFIQUE MANUALMENTE");
        buffer.writeln();
        buffer.writeln("import 'package:freezed_annotation/freezed_annotation.dart';");
        
        if (jsonSerializable) {
          buffer.writeln("import 'package:json_annotation/json_annotation.dart';");
        }
        
        buffer.writeln("import 'dart:convert';");
        buffer.writeln();
        
        final fileName = path.basenameWithoutExtension(outputPath);
        buffer.writeln("part '$fileName.freezed.dart';");
        
        if (jsonSerializable) {
          buffer.writeln("part '$fileName.g.dart';");
        }
        
        buffer.writeln();
      }
      
      // Gerar classes para cada modelo no schema
      for (final model in schema.models) {
        _generateModelClass(buffer, model);
      }
      
      await output.writeAsString(buffer.toString());
      return true;
    } catch (e) {
      print('Error generating Dart classes: $e');
      return false;
    }
  }

  void _generateModelClass(StringBuffer buffer, Model model) {
    if (freezed) {
      buffer.writeln("@freezed");
      buffer.writeln("class ${model.name} with _\$${model.name} {");
      buffer.writeln("  const factory ${model.name}({");
      
      for (final field in model.fields) {
        final dartType = _mapTypeToDart(field.type);
        final nullableMark = field.isNullable ? '?' : '';
        final requiredMark = field.isNullable ? '' : 'required ';
        
        if (field.description != null && field.description!.isNotEmpty) {
          buffer.writeln("    /// ${field.description}");
        }
        
        buffer.writeln("    $requiredMark$dartType$nullableMark ${field.name},");
      }
      
      buffer.writeln("  }) = _${model.name};");
      buffer.writeln();
      
      if (jsonSerializable) {
        buffer.writeln("  factory ${model.name}.fromJson(Map<String, dynamic> json) =>");
        buffer.writeln("      _\$${model.name}FromJson(json);");
      }
      
      buffer.writeln("}");
    } else {
      // Implementação para classes Dart regulares (não-Freezed)
      buffer.writeln("class ${model.name} {");
      
      // Declaração de campos
      for (final field in model.fields) {
        final dartType = _mapTypeToDart(field.type);
        final nullableMark = field.isNullable ? '?' : '';
        
        if (field.description != null && field.description!.isNotEmpty) {
          buffer.writeln("  /// ${field.description}");
        }
        
        buffer.writeln("  final $dartType$nullableMark ${field.name};");
      }
      
      buffer.writeln();
      
      // Construtor
      buffer.writeln("  ${model.name}({");
      for (final field in model.fields) {
        final requiredMark = field.isNullable ? '' : 'required ';
        buffer.writeln("    ${requiredMark}this.${field.name},");
      }
      buffer.writeln("  });");
      
      // fromJson
      if (jsonSerializable) {
        buffer.writeln();
        buffer.writeln("  factory ${model.name}.fromJson(Map<String, dynamic> json) {");
        buffer.writeln("    return ${model.name}(");
        for (final field in model.fields) {
          final castOp = _getCastOperation(field.type, field.isNullable);
          buffer.writeln("      ${field.name}: ${castOp("json['${field.name}']")},");
        }
        buffer.writeln("    );");
        buffer.writeln("  }");
        
        // toJson
        buffer.writeln();
        buffer.writeln("  Map<String, dynamic> toJson() {");
        buffer.writeln("    return {");
        for (final field in model.fields) {
          buffer.writeln("      '${field.name}': ${field.name},");
        }
        buffer.writeln("    };");
        buffer.writeln("  }");
      }
      
      buffer.writeln("}");
    }
    
    buffer.writeln();
  }

  String _mapTypeToDart(FieldType type) {
    switch (type.kind) {
      case TypeKind.string:
        return 'String';
      case TypeKind.integer:
        return 'int';
      case TypeKind.float:
        return 'double';
      case TypeKind.boolean:
        return 'bool';
      case TypeKind.dateTime:
        return 'DateTime';
      case TypeKind.array:
        final itemType = _mapTypeToDart(type.itemType!);
        return 'List<$itemType>';
      case TypeKind.map:
        return 'Map<String, dynamic>';
      case TypeKind.reference:
        return type.reference!;
      default:
        return 'dynamic';
    }
  }

  String Function(String) _getCastOperation(FieldType type, bool isNullable) {
    switch (type.kind) {
      case TypeKind.string:
        return (source) => isNullable 
            ? "$source as String?" 
            : "$source as String";
      case TypeKind.integer:
        return (source) => isNullable 
            ? "$source as int?" 
            : "$source as int";
      case TypeKind.float:
        return (source) => isNullable 
            ? "$source as double?" 
            : "$source as double";
      case TypeKind.boolean:
        return (source) => isNullable 
            ? "$source as bool?" 
            : "$source as bool";
      case TypeKind.dateTime:
        return (source) => isNullable 
            ? "$source != null ? DateTime.parse($source as String) : null" 
            : "DateTime.parse($source as String)";
      case TypeKind.array:
        final itemCast = _getCastOperation(type.itemType!, false);
        return (source) => isNullable 
            ? "$source != null ? ($source as List).map((e) => ${itemCast('e')}).toList() : null" 
            : "($source as List).map((e) => ${itemCast('e')}).toList()";
      case TypeKind.reference:
        final ref = type.reference!;
        return (source) => isNullable 
            ? "$source != null ? $ref.fromJson($source as Map<String, dynamic>) : null" 
            : "$ref.fromJson($source as Map<String, dynamic>)";
      default:
        return (source) => source;
    }
  }
}