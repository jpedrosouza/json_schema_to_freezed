import 'dart:io';
import 'package:json_schema_to_freezed/json_schema_to_freezed.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('JsonSchemaToFreezed manual test', () {
    test('should generate Dart class from TypeScript zod/v4 generated schema '
        'file', ()
    async {
      // Use the existing zstore.json file (skipping file creation)
      final schemaFile = File(path.join('./test', 'zstore_sample.json'));
      if (await schemaFile.exists()) {
        await schemaFile.delete();
      }

      final sampleSchemaJson = '''
        {
          "properties": {
            "id": { "type": "string" },
            "name": { "type": "string" },
            "kind": { "type": "string" },
            "created_on": { "type": "integer" },
            "created_on_iso": { "type": "string" },
            "updated_on": { "type": "integer" },
            "updated_on_iso": { "type": "string" },
            "updated_by": { "type": "string" },
            "tag": { "type": "string" },
            "shop_domain": { "type": "string" },
            "url": { "type": "string" },
            "platform": { "type": "string" },
            "access_token_tag": { "type": "string" },
            "client_uid": { "type": "string" }
          },
          "required": [
            "id", "name", "kind", "created_on", "created_on_iso", 
            "updated_on", "updated_on_iso", "updated_by", "tag", 
            "shop_domain", "url", "platform", "access_token_tag", "client_uid"
          ],
          "\$id": "ZStore"
        }
        ''';
      await schemaFile.writeAsString(sampleSchemaJson);

      // Define output path
      final outputPath = path.join('./test', 'zstore.dart');

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

      // Assert conversion was successful
      expect(success, true, reason: 'Conversion should succeed');

      // Assert output file exists
      final outputFile = File(outputPath);
      expect(
        await outputFile.exists(),
        true,
        reason: 'Output file should exist',
      );

      // Assert file content contains expected class definition
      final content = await outputFile.readAsString();
      expect(
        content.contains('@freezed'),
        true,
        reason: 'Output should contain freezed annotation',
      );
      expect(
        content.contains('class ZStore with _\$ZStore'),
        true,
        reason: 'Output should contain ZStore class',
      );

      // Cleanup - delete the output file
      await outputFile.delete();
      await schemaFile.delete();
    });
  });
}
