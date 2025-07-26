# Changelog

All notable changes to HySS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-01-25

### Added
- Initial release of HySS
- Update-resilient screenshot tool architecture
- Complete reverse engineering of HyDE's screenshot system
- Modular abstraction layer design with plugin-style interfaces
- Dynamic tool version detection and capability testing
- Automatic configuration migration system
- Comprehensive compatibility testing framework
- Support for multiple capture modes: area, freeze, monitor, screen, OCR
- Integration with Satty and Swappy annotation tools
- Smart Wayland clipboard integration
- Interactive update management system
- Detailed compatibility reporting
- Cross-DE compatibility (DE-agnostic design)

### Core Features
- **screenshot-tool**: Main screenshot utility with 5 capture modes
- **screenshot-tool-update**: Update management and maintenance system
- **Abstraction layers**: Tool detection, capture, annotation, clipboard, migration, testing
- **Configuration management**: Version-aware config generation and migration
- **Testing framework**: Automated compatibility and functionality testing

### Dependencies
- Core: grim, slurp, wl-copy
- Annotation: satty or swappy
- Optional: tesseract, imagemagick, jq, notify-send

[Unreleased]: https://github.com/user/HySS/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/user/HySS/releases/tag/v1.0.0
