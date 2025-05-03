# JSON Schema to Freezed

A command-line application that converts JSON Schema to Dart Freezed models.

## Usage

```bash
dart run json_schema_to_freezed --file ./schema.json --output lib/models/generated.dart
```

Or from URL:

```bash
dart run json_schema_to_freezed --url https://example.com/api/schema
```

With authentication or custom headers:

```bash
dart run json_schema_to_freezed --url https://example.com/api/schema --header "Authorization:Bearer token123" --header "Content-Type:application/json"
```

## Options

Run with `--help` to see all available options.
