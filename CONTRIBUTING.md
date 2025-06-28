# Contributing to JSON Schema to Freezed

Thank you for considering contributing to this project! Here's how you can help:

## How to Contribute

1. **Fork the repository** and create your branch from `main`.
2. **Clone your fork** locally.
3. **Install dependencies**: `dart pub get`
4. **Make your changes**: Add features, fix bugs, or improve documentation.
5. **Run tests**: Ensure all tests pass with `dart test`.
6. **Commit changes**: Write clear commit messages.
7. **Push to your fork** and submit a pull request to the `main` branch.

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/json_schema_to_freezed.git
cd json_schema_to_freezed

# Install dependencies
dart pub get

# Run tests
dart test
```
### Running the Local Development Version

```bash
dart run bin/json_schema_to_freezed.dart ...parameters...
```

### Activating the Local Development Version 

If you prefer to use the command directly in your terminal (just like an 
end-user would), you can "globally activate" your local version. This links the command name to your local project directory instead of the version on . `json_schema_to_freezed``pub.dev`
Run the following command from the root of your project directory:


```bash
cd <to the root of the project>
dart pub global activate --source path .
```
## Guidelines

- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style).
- Add tests for new features or bug fixes.
- Keep the code clean and well-documented.
- Make sure your code has no linting errors.

## Pull Request Process

1. Ensure your code passes all tests.
2. Update documentation if needed.
3. Update the CHANGELOG.md with details of your changes.
4. Your pull request will be merged once it is reviewed and approved.

## Feature Requests and Bug Reports

Please submit issues through the [issue tracker](https://github.com/joaopedrosouza/json_schema_to_freezed/issues).

## License

By contributing, you agree that your contributions will be licensed under the project's [MIT License](LICENSE).
