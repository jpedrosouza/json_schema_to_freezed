import 'package:json_schema_to_freezed/src/converter.dart';
void main() async {
  final converter = JsonSchemaToFreezed(
    freezed: true,
    jsonSerializable: true,
  );

  // Exemplo de uso com URL
  final urlSuccess = await converter.convertFromUrl(
    'https://example.com/api/schema-types',
    'lib/models/models_from_url.dart',
  );
  
  print('Conversão da URL: ${urlSuccess ? 'Sucesso' : 'Falha'}');
}