# Changelog

# 1.0.2

* New Features Added
  * Freezed 3 support added, classes will now be `abstract`,
  * Snake case to Camel Case conversion added. On by default, 
  * Updated the JSON schema examples and test code for the latest specification,
  * Updated documentation to align with new DART recommendations,
  * Added more unit tests, specifically to convert TypeScript zod/v4 JSON 
    Schema outputs.

## 1.0.1

* Documentation improvements in README.md:
  * Clarified installation instructions
  * Enhanced usage examples for command line operations
  * Added more detailed descriptions of features and options

## 1.0.0

* Initial release with core functionality:
  * Generate Freezed classes from JSON schema files
  * Generate regular Dart classes with json_serializable support
  * Support for field descriptions and nullable types
  * Option to generate separate files for each model
  * Watch mode for automatic regeneration when source files change
  * Fetch JSON schema from local files or APIs
  * Customizable output format and location
