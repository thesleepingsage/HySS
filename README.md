# Update-Resilient Screenshot Tool

A standalone, update-resilient screenshot utility based on HyDE's implementation with advanced maintainability features.

## Overview

This tool provides a **portable, DE-agnostic screenshot system** that automatically adapts to tool updates and maintains compatibility across different versions of its dependencies.

### Key Features

- **🔧 Update-Resilient Architecture**: Automatically detects tool capabilities and adapts to version changes
- **🔄 Automatic Migration System**: Handles configuration updates when tools are upgraded
- **🧪 Comprehensive Testing**: Built-in compatibility testing after updates
- **🎯 Multiple Capture Modes**: Area, frozen, monitor, screen, and OCR text extraction
- **✨ Modern Annotation**: Supports both Satty and Swappy annotation tools
- **📋 Smart Clipboard Integration**: Seamless Wayland clipboard operations
- **📊 Detailed Reporting**: Comprehensive compatibility and status reports

## Installation

### Dependencies

**Core Requirements:**
- `grim` - Wayland screenshot utility
- `slurp` - Interactive area selection
- `wl-copy` (wl-clipboard) - Clipboard integration

**Annotation Tools (choose one):**
- `satty` - Modern annotation tool (recommended)
- `swappy` - Traditional annotation tool

**Optional Enhancements:**
- `tesseract` + `tesseract-data-eng` - OCR text extraction
- `imagemagick` - Image processing for better OCR
- `jq` - Enhanced JSON processing for advanced features
- `notify-send` - Desktop notifications

### Setup

1. **Clone or copy the tool files:**
   ```bash
   # Copy the screenshot-tool and lib/ directory to your desired location
   cp -r screenshot-tool lib/ ~/.local/bin/
   ```

2. **Verify dependencies:**
   ```bash
   ./screenshot-tool-update check
   ```

3. **Run initial setup:**
   ```bash
   ./screenshot-tool-update test
   ```

## Usage

### Basic Screenshot Operations

```bash
# Interactive area/window selection
./screenshot-tool area

# Frozen screen selection (easier targeting)
./screenshot-tool freeze

# Current monitor
./screenshot-tool monitor

# All monitors
./screenshot-tool screen

# OCR text extraction to clipboard
./screenshot-tool ocr
```

### Desktop Environment Integration

Add keybindings to your DE configuration:

```bash
# Example keybindings (adapt to your DE)
Super+P              exec /path/to/screenshot-tool area
Super+Ctrl+P         exec /path/to/screenshot-tool freeze
Super+Alt+P          exec /path/to/screenshot-tool monitor
Print                exec /path/to/screenshot-tool screen
Super+Shift+S        exec /path/to/screenshot-tool ocr
```

### Environment Variables

```bash
# Force specific annotation tool
export SCREENSHOT_ANNOTATION_TOOL=satty

# Skip annotation step
export SCREENSHOT_NO_ANNOTATION=1

# Copy to clipboard only (don't save file)
export SCREENSHOT_COPY_ONLY=1

# Custom save directory
./screenshot-tool area ~/Desktop/screenshots
```

## Update Management

### Automatic Update Handling

The tool automatically:
- Detects when dependencies are updated
- Migrates configurations to new formats
- Tests compatibility after changes
- Provides detailed reports on issues

### Manual Update Operations

```bash
# Check system status and detect updates
./screenshot-tool-update check

# Run comprehensive compatibility tests
./screenshot-tool-update test

# Generate detailed status report
./screenshot-tool-update report

# Force regenerate all configurations
./screenshot-tool-update force-regen

# Show migration and test history
./screenshot-tool-update history

# Clean old data and backups
./screenshot-tool-update clean
```

### Interactive Update Manager

```bash
# Launch interactive update manager
./screenshot-tool-update interactive
```

## Architecture

### Modular Design

The tool uses a **plugin-style architecture** with abstraction layers:

- **Tool Detection** (`lib/tool-detection.sh`): Version detection and capability mapping
- **Capture Abstraction** (`lib/capture-abstraction.sh`): Screenshot capture methods
- **Annotation Abstraction** (`lib/annotation-abstraction.sh`): Annotation tool integration
- **Clipboard Abstraction** (`lib/clipboard-abstraction.sh`): Clipboard operations
- **Migration System** (`lib/migration-system.sh`): Configuration migrations
- **Compatibility Testing** (`lib/compatibility-testing.sh`): Automated testing

### Update Resilience

The system maintains compatibility through:

1. **Dynamic Capability Detection**: Tests tool features at runtime
2. **Version-Aware Configuration**: Generates configs based on detected versions
3. **Graceful Degradation**: Core functionality works even if advanced features fail
4. **Automatic Fallbacks**: Switches to alternative methods when tools change
5. **Migration Framework**: Handles configuration updates automatically

### Data Storage

```
~/.config/screenshot-tool/          # Configuration files
├── satty/config.toml              # Satty annotation config
└── swappy/config                  # Swappy annotation config

~/.local/share/screenshot-tool/    # Data and cache
├── tool-capabilities.json         # Cached tool capabilities
├── migration-metadata.json        # Migration tracking
└── compatibility-test-results.json # Test results

~/Pictures/Screenshots/            # Default screenshot location
```

## Troubleshooting

### Common Issues

**1. "Missing required dependencies"**
```bash
# Check which tools are missing
./screenshot-tool-update status

# Install missing tools (example for Arch Linux)
sudo pacman -S grim slurp wl-clipboard satty
```

**2. "Annotation tool failed"**
```bash
# Check annotation tool status
./screenshot-tool-update test

# Try alternative annotation tool
export SCREENSHOT_ANNOTATION_TOOL=swappy
./screenshot-tool area
```

**3. "Clipboard integration not working"**
```bash
# Verify Wayland clipboard tools
which wl-copy wl-paste

# Test clipboard directly
echo "test" | wl-copy
wl-paste
```

**4. "Configuration errors after tool updates"**
```bash
# Force regenerate configurations
./screenshot-tool-update force-regen

# Check migration history
./screenshot-tool-update history
```

### Debug Mode

Enable verbose output for troubleshooting:
```bash
./screenshot-tool-update check --verbose
```

### Compatibility Reports

Generate detailed compatibility reports:
```bash
# Generate report file
./screenshot-tool-update report > screenshot-tool-report.txt

# View current status
./screenshot-tool-update status
```

## Advanced Features

### OCR Text Extraction

The tool includes sophisticated OCR capabilities:
- Interactive area selection for text regions
- Automatic image enhancement for better recognition  
- Direct clipboard integration
- Notification with extracted text preview

### Workflow Integration

Examples of advanced usage:

```bash
# Screenshot with custom processing
./screenshot-tool area && convert ~/Pictures/Screenshots/latest.png -resize 50% ~/Pictures/Screenshots/thumbnail.png

# OCR with custom language
TESSERACT_OPTS="-l fra" ./screenshot-tool ocr

# Automated screenshot series
for i in {1..5}; do
    ./screenshot-tool screen ~/Desktop/series_$i.png
    sleep 2
done
```

### Custom Configurations

Create custom annotation configurations:

```bash
# Custom Satty config
mkdir -p ~/.config/screenshot-tool/satty
cat > ~/.config/screenshot-tool/satty/config.toml << 'EOF'
[general]
initial-tool = "rectangle"
corner-roundness = 0
early-exit = true

[color-palette]
palette = ["#ff0000", "#00ff00", "#0000ff"]
EOF
```

## Development

### Extending the Tool

The modular architecture makes it easy to:
- Add support for new screenshot tools
- Implement additional annotation tools
- Create custom capture modes
- Add new export formats

### Testing Changes

```bash
# Run full test suite
./screenshot-tool-update test

# Test specific functionality
./screenshot-tool-update test --verbose
```

### Contributing

When adding new features:
1. Update capability detection in `lib/tool-detection.sh`
2. Add abstraction layer support if needed
3. Include migration logic for configuration changes
4. Add compatibility tests
5. Update documentation

## License

This tool is based on HyDE's screenshot implementation and maintains compatibility with its design principles while adding update resilience and portability features.

---

**Note**: This tool is designed to be a drop-in replacement for HyDE's screenshot system while providing enhanced maintainability and cross-DE compatibility.