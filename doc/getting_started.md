# Getting Started with JSON Schema to Freezed

This guide will help you get started with converting JSON schema files to Dart classes using JSON Schema to Freezed.

## Installation

You can install JSON Schema to Freezed as a global package for CLI usage:

```bash
dart pub global activate json_schema_to_freezed
```

Or add it as a development dependency in your project:

```bash
dart pub add json_schema_to_freezed --dev
```

## Basic Usage

### Prepare Your JSON Schema

Create a JSON schema file that defines your models. Here's a simple example:

```json
{
  "version": "1.0.0",
  "models": [
    {
      "name": "Person",
      "description": "Represents a person",
      "fields": [
        {
          "name": "name",
          "type": "string",
          "description": "Person's full name"
        },
        {
          "name": "age",
          "type": "integer",
          "description": "Person's age in years"
        },
        {
          "name": "email",
          "type": "string",
          "isNullable": true,
          "description": "Person's email address (optional)"
        }
      ]
    }
  ]
}
```

### Generate Dart Class

Run the following command to generate a Freezed class:

```bash
json_schema_to_freezed -f path/to/schema.json -o lib/models/generated.dart
```

### Use the Generated Class

After running the build_runner to generate the Freezed and JSON serialization files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

You can use the generated class in your code:

```dart
import 'models/generated.dart';

void main() {
  final person = Person(
    name: 'John Doe',
    age: 30,
    email: 'john.doe@example.com',
  );
  
  // Convert to JSON
  final json = person.toJson();
  print(json);
  
  // Parse from JSON
  final parsedPerson = Person.fromJson(json);
  print(parsedPerson);
}
```

## Using Separate Files

You can generate a separate file for each model:

```bash
json_schema_to_freezed -f path/to/schema.json -o lib/models/*.dart --separate-files
```

## Advanced Configuration

### Using Regular Dart Classes

To generate regular Dart classes instead of Freezed classes:

```bash
json_schema_to_freezed -f path/to/schema.json -o lib/models/generated.dart --no-freezed
```

### Watch Mode

Enable watch mode to automatically regenerate when the source file changes:

```bash
json_schema_to_freezed -f path/to/schema.json -o lib/models/generated.dart -w
```

## Supported Types

The converter supports the following JSON schema types:

- `string` → `String`
- `integer` → `int`
- `number` → `double`
- `boolean` → `bool`
- `array` → `List<T>`
- `object` → `Map<String, dynamic>`

## Next Steps

- Check out the [README](../README.md) for more information
- Look at the [example](../example/) directory for usage examples
- Contribute to the project by following the [contribution guidelines](../CONTRIBUTING.md)
