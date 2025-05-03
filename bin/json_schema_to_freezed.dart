import 'dart:io';

import 'package:args/args.dart';
import 'package:json_schema_to_freezed/json_schema_to_freezed.dart';
import 'package:path/path.dart' as path;

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('url',
        abbr: 'u',
        help: 'URL of the endpoint returning the JSON schema')
    ..addOption('file',
        abbr: 'f', help: 'Path to a local JSON schema file (.json)')
    ..addOption('output',
        abbr: 'o',
        defaultsTo: 'lib/models/generated_models.dart',
        help: 'Output file path for the generated classes')
    ..addMultiOption('header',
        abbr: 'H',
        help: 'HTTP headers for URL requests in the format "key:value"')
    ..addFlag('separate-files',
        abbr: 's',
        defaultsTo: false,
        help: 'Generate a separate file for each model')
    ..addFlag('watch',
        abbr: 'w',
        defaultsTo: false,
        help: 'Watch for changes in the source file (file mode only)')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help menu')
    ..addOption('config',
        abbr: 'c', help: 'Path to a custom configuration file')
    ..addFlag('freezed',
        defaultsTo: true,
        help: 'Generate Freezed classes (default) or regular Dart classes')
    ..addFlag('json-serializable',
        defaultsTo: true,
        help: 'Add json_serializable support for JSON serialization');

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      _printHelp(parser);
      return;
    }

    // Parse headers
    final List<String> headerStrings = results['header'] as List<String>;
    final Map<String, String> headers = {};
    
    for (final headerString in headerStrings) {
      final parts = headerString.split(':');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        // Join back in case the value itself contains colons
        final value = parts.sublist(1).join(':').trim();
        headers[key] = value;
      } else {
        stderr.writeln('⚠️  Warning: Invalid header format: $headerString. Use "key:value"');
      }
    }

    final converter = JsonSchemaToFreezed(
      freezed: results['freezed'] as bool,
      jsonSerializable: results['json-serializable'] as bool,
      headers: headers,
    );

    final String? url = results['url'] as String?;
    final String? file = results['file'] as String?;
    String output = results['output'] as String;
    final bool watch = results['watch'] as bool;
    final bool separateFiles = results['separate-files'] as bool;

    if (url == null && file == null) {
      _printHelp(parser);
      stderr.writeln('\n⚠️  Error: Specify a source URL or file!');
      exit(1);
    }

    if (url != null && file != null) {
      stderr.writeln('⚠️  Error: Specify either a URL OR a file, not both!');
      exit(1);
    }

    // If we should generate separate files, modify the output path
    if (separateFiles) {
      final dir = path.dirname(output);
      final extension = path.extension(output);
      final basename = path.basenameWithoutExtension(output);
      output = path.join(dir, basename + '_*' + extension);
    }

    bool success;
    if (url != null) {
      print('🔄 Fetching schema from URL: $url');
      success = await converter.convertFromUrl(url, output);
    } else {
      print('🔄 Converting schema from file: $file');
      success = await converter.convertFromFile(file!, output);
      
      if (success && watch) {
        print('👀 Watching for changes in $file...');
        File(file).watch().listen((_) async {
          print('🔄 File changed, regenerating...');
          await converter.convertFromFile(file, output);
          print('✅ Regeneration completed!');
        });
        // Keep the process active
        stdin.lineMode = false;
        stdin.echoMode = false;
        stdin.listen((_) {});
      }
    }

    if (success) {
      if (!separateFiles) {
        print('✅ Conversion completed! Classes generated at: $output');
      } else {
        print('✅ Conversion completed! Classes generated as separate files.');
      }
    } else {
      stderr.writeln('❌ Conversion failed');
      exit(1);
    }
  } catch (e) {
    stderr.writeln('❌ Error: $e');
    _printHelp(parser);
    exit(1);
  }
}

void _printHelp(ArgParser parser) {
  print('''
╔════════════════════════════════════════════╗
║           JSON SCHEMA TO FREEZED           ║
╚════════════════════════════════════════════╝

Converts JSON schemas to Dart Freezed classes.

Usage:
  json_schema_to_freezed --url https://your-backend.com/api/schema-types
  json_schema_to_freezed --file ./schema.json
  json_schema_to_freezed --file ./schema.json --output lib/models/generated.dart
  json_schema_to_freezed --url https://api.example.com/schema --separate-files --output lib/models/model.dart

Options:
${parser.usage}
''');
}