# Contributing to HySS

Thank you for your interest in contributing to HySS! This document provides guidelines for contributing to the project.

## Development Workflow

### Branch Structure

- **`main`**: Stable releases and production-ready code
- **`dev`**: Active development branch for new features and fixes
- **Feature branches**: `feature/description` for new features
- **Bugfix branches**: `fix/description` for bug fixes

### Getting Started

1. **Fork the repository**
2. **Clone your fork locally**
   ```bash
   git clone https://github.com/yourusername/HySS.git
   cd HySS
   ```

3. **Set up development environment**
   ```bash
   # Install dependencies (example for Arch Linux)
   sudo pacman -S grim slurp wl-clipboard satty tesseract jq

   # Run compatibility check
   ./screenshot-tool-update check
   ```

4. **Create a development branch**
   ```bash
   git checkout dev
   git checkout -b feature/your-feature-name
   ```

### Making Changes

#### Code Style
- Follow existing bash scripting conventions
- Use shellcheck for script validation
- Add comments for complex logic
- Maintain modular architecture

#### Testing
- Test changes with `./screenshot-tool-update test`
- Verify compatibility across different tool versions
- Test all capture modes (area, freeze, monitor, screen, OCR)
- Ensure update/migration functionality works

#### Documentation
- Update README.md for user-facing changes
- Update CHANGELOG.md following Keep a Changelog format
- Add comments to complex functions
- Update capability detection for new tools

### Submitting Changes

1. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add support for new screenshot tool"
   ```

2. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create a Pull Request**
   - Target the `dev` branch (not `main`)
   - Provide clear description of changes
   - Include test results
   - Reference any related issues

### Pull Request Guidelines

#### PR Title Format
- `feat: description` - New features
- `fix: description` - Bug fixes
- `docs: description` - Documentation changes
- `refactor: description` - Code refactoring
- `test: description` - Test improvements

#### PR Description Should Include
- **What changed**: Brief description of the changes
- **Why**: Motivation for the changes
- **Testing**: How the changes were tested
- **Compatibility**: Any compatibility implications
- **Breaking changes**: List any breaking changes

### Code Architecture

#### Adding New Tools
1. **Extend tool detection** (`lib/tool-detection.sh`)
   - Add capability detection functions
   - Update version checking logic

2. **Create abstraction layer** (relevant `lib/*.sh` file)
   - Add tool-specific functions
   - Implement fallback mechanisms

3. **Add migration support** (`lib/migration-system.sh`)
   - Define migration requirements
   - Implement config migration functions

4. **Update testing** (`lib/compatibility-testing.sh`)
   - Add tool-specific tests
   - Update integration tests

#### Adding New Features
1. **Design for modularity**: Keep features in appropriate abstraction layers
2. **Implement capability detection**: Check tool support dynamically
3. **Add graceful degradation**: Ensure core functionality works without new features
4. **Include comprehensive testing**: Test with and without dependencies

### Testing

#### Manual Testing
```bash
# Test all capture modes
./screenshot-tool area
./screenshot-tool freeze
./screenshot-tool monitor
./screenshot-tool screen
./screenshot-tool ocr

# Test update system
./screenshot-tool-update check
./screenshot-tool-update test
./screenshot-tool-update report
```

#### Automated Testing
```bash
# Run full compatibility test suite
./screenshot-tool-update test --verbose

# Generate compatibility report
./screenshot-tool-update report
```

### Release Process

#### For Maintainers

1. **Merge to dev**: All changes go to `dev` first
2. **Testing phase**: Thorough testing on `dev` branch
3. **Release preparation**:
   - Update CHANGELOG.md
   - Update version numbers
   - Run final compatibility tests
4. **Merge to main**: Create PR from `dev` to `main`
5. **Tag release**: Create git tag for version
6. **GitHub release**: Create release with changelog

### Issue Reporting

#### Bug Reports
- Use GitHub Issues
- Include system information
- Provide steps to reproduce
- Include output from `./screenshot-tool-update report`

#### Feature Requests
- Describe the use case
- Explain why the feature would be useful
- Consider implementation complexity
- Discuss compatibility implications

### Development Tips

#### Understanding the Codebase
1. **Start with** `screenshot-tool` - main entry point
2. **Review** `lib/tool-detection.sh` - capability system
3. **Examine** abstraction layers in `lib/` directory
4. **Test** with `screenshot-tool-update` commands

#### Common Development Tasks

**Adding a new screenshot tool**:
1. Add detection in `tool-detection.sh`
2. Create abstraction functions in `capture-abstraction.sh`
3. Add testing in `compatibility-testing.sh`
4. Update documentation

**Adding a new annotation tool**:
1. Add detection in `tool-detection.sh`
2. Create abstraction functions in `annotation-abstraction.sh`
3. Add config generation/migration
4. Update testing

### Community

- **Be respectful**: Follow code of conduct
- **Be helpful**: Assist other contributors
- **Be patient**: Reviews take time
- **Be collaborative**: Discuss major changes before implementing

### Questions?

Feel free to:
- Open an issue for questions
- Start a discussion for feature ideas
- Reach out to maintainers for guidance

Thank you for contributing to HySS!
