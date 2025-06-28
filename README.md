# JSON Schema to Freezed

A Dart tool that converts JSON schema files to Dart classes with [Freezed](https://pub.dev/packages/freezed) or regular Dart classes with JSON serialization support.

[![Pub Version](https://img.shields.io/pub/v/json_schema_to_freezed)](https://pub.dev/packages/json_schema_to_freezed)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features

- Generate Freezed classes from JSON schema files
- Generate regular Dart classes with json_serializable support
- Support for field descriptions and nullable types
- Option to generate separate files for each model
- Watch mode for automatic regeneration when source files change
- Fetch JSON schema from local files or APIs
- Customizable output format and location

## Installation

```bash
# Install globally to use the CLI
dart pub global activate json_schema_to_freezed

# Or add as a dev dependency in your project
dart pub add json_schema_to_freezed --dev
```

## Usage

### Command Line

You can use JSON Schema to Freezed with either local schema files or fetch schemas from an API.

- DART now recommends the use of `dart run` for running globally activated 
packages. 

#### Using a Local JSON Schema File

```bash
# Generate Freezed classes from a local JSON schema file
dart run json_schema_to_freezed -f schema.json -o lib/models/generated.dart

# Generate regular Dart classes
dart run json_schema_to_freezed -f schema.json -o lib/models/generated.dart 
--no-freezed

# Generate separate files for each model
dart run json_schema_to_freezed -f schema.json -o lib/models/*.dart 
--separate-files

# Watch for changes in the source file
dart run json_schema_to_freezed -f schema.json -o lib/models/generated.dart -w
```

#### Fetching JSON Schema from an API

```bash
# Generate Freezed classes from a JSON schema API endpoint
dart run json_schema_to_freezed --url https://example.com/api/json-schema?
moduleType=contact --output lib/models/generated.dart

# With authentication headers
dart run json_schema_to_freezed --url https://example.com/api/json-schema?
moduleType=contact --header "token:123" --output lib/models/gen.dart --separate-files

# Multiple headers can be passed
dart run json_schema_to_freezed --url https://example.com/api/json-schema 
--header "token:123" --header "Content-Type:application/json" --output lib/models/gen.dart
```

### Command Line Options

```
Options:
-u, --url                       URL of the endpoint returning the JSON schema
-f, --file                      Path to a local JSON schema file (.json)
-o, --output                    Output file path for the generated classes
                                (defaults to "lib/models/generated_models.dart")
-H, --header                    HTTP headers for URL requests in the format "key:value"
-s, --[no-]separate-files       Generate a separate file for each model
-w, --[no-]watch                Watch for changes in the source file (file mode only)
-h, --help                      Show this help menu
-c, --config                    Path to a custom configuration file
    --[no-]freezed              Generate Freezed classes (default) or regular Dart classes
                                (defaults to on)
    --[no-]json-serializable    Add json_serializable support for JSON serialization
                                (defaults to on)
    --[no-]camel-case           Convert snake-case to camel-case and add @JsonKey()
                                (defaults to on)
    --[no-]abstract             Declare freezed class as abstract (v3 requirement)
                                (defaults to on)
    --[no-]use-dollar-id        Parse $id as the root class name instead of creating a "Root" class.
                                (defaults to on)
```

## Example

### Input JSON Schema

JSON schemas can contain multiple model definitions. Here's an example of a JSON schema with multiple models:

```json
{
    "CreateContactParams": {
        "schema": {
            "type": "object",
            "properties": {
                "title": {
                    "type": "string"
                },
                "phone": {
                    "type": "string"
                }
            },
            "additionalProperties": false,
            "propertyOrder": [
                "title",
                "phone"
            ],
            "required": [
                "phone",
                "title"
            ],
            "$schema": "http://json-schema.org/draft-07/schema#"
        },
        "description": ""
    },
    "ShowContactByIdParams": {
        "schema": {
            "type": "object",
            "properties": {
                "id": {
                    "type": "string"
                }
            },
            "additionalProperties": false,
            "propertyOrder": [
                "id"
            ],
            "required": [
                "id"
            ],
            "$schema": "http://json-schema.org/draft-07/schema#"
        },
        "description": ""
    },
    "UpdateContactParams": {
        "schema": {
            "additionalProperties": false,
            "type": "object",
            "properties": {
                "title": {
                    "type": "string"
                },
                "phone": {
                    "type": "string"
                },
                "id": {
                    "type": "string"
                }
            },
            "required": [
                "id"
            ],
            "$schema": "http://json-schema.org/draft-07/schema#"
        },
        "description": ""
    },
    "DeleteContactParams": {
        "schema": {
            "type": "object",
            "properties": {
                "id": {
                    "type": "string"
                }
            },
            "additionalProperties": false,
            "propertyOrder": [
                "id"
            ],
            "required": [
                "id"
            ],
            "$schema": "http://json-schema.org/draft-07/schema#"
        },
        "description": ""
    }
}
```

### Generated Freezed Classes

When using the `--separate-files` option, the tool will generate separate files for each model. For example:

```dart
// create_contact_params.dart
// GENERATED CODE - DO NOT MODIFY MANUALLY

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_contact_params.freezed.dart';
part 'create_contact_params.g.dart';

@freezed
class CreateContactParams with _$CreateContactParams {
  const factory CreateContactParams({
    required String title,
    required String phone,
  }) = _CreateContactParams;

  factory CreateContactParams.fromJson(Map<String, dynamic> json) =>
      _$CreateContactParamsFromJson(json);
}
```

## Additional Notes

After generating the Freezed classes, you'll need to run the Freezed and JSON serializable code generators:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
