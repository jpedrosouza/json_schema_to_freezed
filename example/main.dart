import 'dart:io';
import 'package:json_schema_to_freezed/json_schema_to_freezed.dart';
import 'package:path/path.dart' as path;

void main() async {
  // Create a simple schema for demonstration
  final schemaJson = '''
  {
    "version": "1.0.0",
    "models": [
      {
        "name": "Product",
        "description": "A product in the catalog",
        "fields": [
          {
            "name": "id",
            "type": "string",
            "description": "Unique identifier for the product"
          },
          {
            "name": "name",
            "type": "string",
            "description": "Product name"
          },
          {
            "name": "price",
            "type": "number",
            "description": "Product price"
          },
          {
            "name": "tags",
            "type": "array",
            "items": {
              "type": "string"
            },
            "isNullable": true,
            "description": "Optional product tags"
          }
        ]
      }
    ]
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
