import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:recase/recase.dart';

import 'models/schema_model.dart';
import 'parsers/json_schema_parser.dart';

/// Main class that manages the conversion of schemas to Dart/Freezed classes
class JsonSchemaToFreezed {
  final bool freezed;
  final bool jsonSerializable;
  final Map<String, String> headers;
  final bool camelCase;
  final bool declareAbstract;
  final bool useId;
  final bool useDollarId;

  JsonSchemaToFreezed({
    this.freezed = true,
    this.jsonSerializable = true,
    this.headers = const {},
    this.camelCase = true,
    this.declareAbstract = true,
    this.useId = true,
    this.useDollarId = true,
  });

  /// Converts schema from a URL to Dart/Freezed classes
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

  /// Converts schema from a local file to Dart/Freezed classes
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
    final schema = await parser.parse(jsonData, useDollarId);
    
    // Transform model names to use AdapterParams instead of Params
    for (var model in schema.models) {
      if (model.name.endsWith('Params')) {
        model.name = '${model.name.substring(0, model.name.length - 'Params'.length)}AdapterParams';
      }
    }
    
    // Check if user requested separate files
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
        // Get the file name in snake_case
        String fileName = ReCase(model.name).snakeCase;
        
        // Replace "adapter_params" with "adapter_params" in the file name for consistency
        if (fileName.endsWith('_adapter_params')) {
          fileName = '${fileName.substring(0, fileName.length - '_adapter_params'.length)}_adapter';
        } else if (fileName.endsWith('_params')) {
            // Maintain compatibility with existing code that may still use _params
          fileName = '${fileName.substring(0, fileName.length - '_params'.length)}_adapter';
        }
        
        // Generate the file path without adding "generated_" as a prefix
        final outputPath = outputPathTemplate.replaceAll("*", fileName);
        
        final output = File(outputPath);
        final buffer = StringBuffer();
        
        // Add necessary imports
        if (freezed) {
          buffer.writeln("// GENERATED CODE - DO NOT MODIFY MANUALLY");
          buffer.writeln("// Generated on: ${DateTime.now().toIso8601String()}");
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
        
        // Generate class for this model
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
      
      // Add necessary imports
      if (freezed) {
        buffer.writeln("// GENERATED CODE - DO NOT MODIFY MANUALLY");
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
      
      // Generate classes for each model in the schema
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
      // V3 Freezed requires "abstract class"
      final classHeader = declareAbstract ? "abstract class" : "class";
      buffer.writeln("@freezed");
      buffer.writeln("$classHeader ${model.name} with _\$${model.name} {");
      buffer.writeln("  const factory ${model.name}({");
      
      for (final field in model.fields) {
        final dartType = _mapTypeToDart(field.type);
        final nullableMark = field.isNullable ? '?' : '';
        final requiredMark = field.isNullable ? '' : 'required ';
        
        if (field.description != null && field.description!.isNotEmpty) {
          buffer.writeln("    /// ${field.description}");
        }

        // DART prefers the camel Case variables instead of snake case.
        final fieldName = field.name;
        final camelCaseName = ReCase(fieldName).camelCase;
        final usesCamelCase = fieldName == camelCaseName;

        if (!usesCamelCase && camelCase) {
          var required = "";
          if (requiredMark == "required ") {
            required=", required: true";
          }
          buffer.writeln("    @JsonKey(name: '${field.name}'$required)");
        }
          buffer.writeln(
              "    $requiredMark$dartType$nullableMark $camelCaseName,");
      }

      buffer.writeln("  }) = _${model.name};");
      buffer.writeln();
      
      if (jsonSerializable) {
        buffer.writeln("  factory ${model.name}.fromJson(Map<String, dynamic> json) =>");
        buffer.writeln("      _\$${model.name}FromJson(json);");
      }
      
      buffer.writeln("}");
    } else {
      // Implementation for regular Dart classes (non-Freezed)
      buffer.writeln("class ${model.name} {");
      
      // Field declarations
      for (final field in model.fields) {
        final dartType = _mapTypeToDart(field.type);
        final nullableMark = field.isNullable ? '?' : '';
        
        if (field.description != null && field.description!.isNotEmpty) {
          buffer.writeln("  /// ${field.description}");
        }
        
        final fieldName = field.name;
        final camelCaseName = ReCase(fieldName).camelCase;
        final usesCamelCase = fieldName == camelCaseName;

        if (!usesCamelCase) {
          buffer.writeln("  @JsonKey(name: '${field.name}')");
        }
        buffer.writeln("  final $dartType$nullableMark $camelCaseName;");
      }

      buffer.writeln();
      
      // Constructor
      buffer.writeln("  ${model.name}({");
      for (final field in model.fields) {
        final requiredMark = field.isNullable ? '' : 'required ';
        final camelCaseName = ReCase(field.name).camelCase;
        buffer.writeln("    ${requiredMark}this.$camelCaseName,");
      }
      buffer.writeln("  });");
      
      // fromJson
      if (jsonSerializable) {
        buffer.writeln();
        buffer.writeln("  factory ${model.name}.fromJson(Map<String, dynamic> json) {");
        buffer.writeln("    return ${model.name}(");
        for (final field in model.fields) {
          final castOp = _getCastOperation(field.type, field.isNullable);
          final camelCaseName = ReCase(field.name).camelCase;
          buffer.writeln(
              "      $camelCaseName: ${castOp("json['${field.name}']")},");
        }
        buffer.writeln("    );");
        buffer.writeln("  }");
        
        // toJson
        buffer.writeln();
        buffer.writeln("  Map<String, dynamic> toJson() {");
        buffer.writeln("    return {");
        for (final field in model.fields) {
          final fieldName = field.name;
          final camelCaseName = ReCase(fieldName).camelCase;
          buffer.writeln("      '$fieldName': $camelCaseName,");
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