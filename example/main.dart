import 'dart:io';
import 'package:json_schema_to_freezed/json_schema_to_freezed.dart';
import 'package:path/path.dart' as path;

void main() async {
  // Create a simple schema for demonstration
  final schemaJson = '''
      {
        "\$schema": "https://json-schema.org/draft/2020-12/schema",
        "\$id": "Product",
        "title": "Product",
        "description": "A product in the catalog",
        "type": "object",
        "properties": {
          "id": {
            "type": "string",
            "description": "Unique identifier for the product"
          },
          "name": {
            "type": "string",
            "description": "Product name"
          },
          "price": {
            "type": "number",
            "description": "Product price"
          },
          "tags": {
            "type": "array",
            "items": {
              "type": "string"
            },
            "description": "Optional product tags"
          }
        },
        "required": ["id", "name", "price"]
      }
      ''';

  // Save schema to a temporary file
  final tempDir = Directory.systemTemp;
  final schemaFile = File(path.join(tempDir.path, 'example_schema.json'));
  await schemaFile.writeAsString(schemaJson);
  
  // Define output path
  final outputPath = path.join(tempDir.path, 'generated_product.dart');
  
  // Create converter instance
  final converter = JsonSchemaToFreezed(
    freezed: true,
    jsonSerializable: true,
  );
  
  // Convert schema to Dart class
  final success = await converter.convertFromFile(
    schemaFile.path,
    outputPath,
  );

  // Is possible to convert from URL as well
  // final successFromUrl = await converter.convertFromUrl(
  //   'https://example.com/schema.json',
  //   outputPath,
  // );
  
  if (success) {
    print('✅ Conversion successful! Generated file at: $outputPath');
    print('Generated content:');
    print('------------------');
    print(await File(outputPath).readAsString());
  } else {
    print('❌ Conversion failed');
  }
  
  // Clean up
  await schemaFile.delete();
}
