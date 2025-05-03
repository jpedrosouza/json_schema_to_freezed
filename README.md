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

```bash
# Generate Freezed classes from a JSON schema file
json_schema_to_freezed -f schema.json -o lib/models/generated.dart

# Generate regular Dart classes
json_schema_to_freezed -f schema.json -o lib/models/generated.dart --no-freezed

# Generate separate files for each model
json_schema_to_freezed -f schema.json -o lib/models/*.dart --separate-files

# Watch for changes in the source file
json_schema_to_freezed -f schema.json -o lib/models/generated.dart -w
```

### Command Line Options

```
-f, --file          Path to the JSON schema file
-o, --output        Path to the generated Dart file or directory pattern
-s, --separate-files  Generate separate files for each model
-w, --watch         Watch for changes in the source file (file mode only)
-h, --help          Show this help menu
-c, --config        Path to a custom configuration file
    --[no-]freezed  Generate Freezed classes (default) or regular Dart classes
    --[no-]json-serializable  Add json_serializable support for JSON serialization
```

## Example

### Input JSON Schema

```json
{
  "version": "1.0.0",
  "models": [
    {
      "name": "User",
      "description": "A user in the system",
      "fields": [
        {
          "name": "id",
          "type": "string",
          "description": "Unique identifier for the user"
        },
        {
          "name": "email",
          "type": "string",
          "description": "User's email address"
        },
        {
          "name": "age",
          "type": "integer",
          "isNullable": true,
          "description": "User's age (optional)"
        },
        {
          "name": "createdAt",
          "type": "string",
          "description": "Account creation timestamp"
        }
      ]
    }
  ]
}
```

### Generated Freezed Class

```dart
// GENERATED CODE - DO NOT MODIFY MANUALLY

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'generated.freezed.dart';
part 'generated.g.dart';

/// A user in the system
@freezed
class User with _$User {
  const factory User({
    /// Unique identifier for the user
    required String id,
    /// User's email address
    required String email,
    /// User's age (optional)
    int? age,
    /// Account creation timestamp
    required String createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);
}
```

## Additional Notes

After generating the Freezed classes, you'll need to run the Freezed and JSON serializable code generators:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
