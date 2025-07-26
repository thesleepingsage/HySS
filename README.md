# HyprScreenShot

A standalone, update-resilient screenshot utility based on HyDE's implementation with advanced maintainability features.

## Overview

HyprScreenShot provides a **portable, DE-agnostic screenshot system** that automatically adapts to tool updates and maintains compatibility across different versions of its dependencies.

### Key Features

- **Update-Resilient Architecture**: Automatically detects tool capabilities and adapts to version changes
- **Automatic Migration System**: Handles configuration updates when tools are upgraded
- **Comprehensive Testing**: Built-in compatibility testing after updates
- **Multiple Capture Modes**: Area, frozen, monitor, screen, and OCR text extraction
- **Modern Annotation**: Supports both Satty and Swappy annotation tools
- **Smart Clipboard Integration**: Seamless Wayland clipboard operations
- **Detailed Reporting**: Comprehensive compatibility and status reports
- **Configurable Notifications**: TOML-based configuration with user-friendly management
- **Subcommand Architecture**: Unified interface for screenshots, updates, and configuration

## Installation

### Dependencies

**Core Requirements:**
- `grim` - Wayland screenshot utility
- `slurp` - Interactive area selection
- `wl-copy` (wl-clipboard) - Clipboard integration
- `imagemagick` - Image processing for OCR and dynamic window sizing
- `tesseract` + `tesseract-data-eng` - OCR text extraction
- `jq` - Enhanced JSON processing for advanced features
- `notify-send` - Desktop notifications

**Annotation Tools (choose one):**
- `satty` - Modern annotation tool (recommended)
- `swappy` - Traditional annotation tool

### Installation

HyprScreenShot provides a simple "plug and play" installation script that works immediately after installation.

#### Quick Installation

**System-wide installation (recommended):**
```bash
# Download and extract HyprScreenShot
# Then run:
sudo ./install.sh
```

**User-local installation:**
```bash
./install.sh --user
```

#### Installation Options

```bash
# Show installation help
./install.sh --help

# Force overwrite existing installation
./install.sh --force

# User installation with force overwrite
./install.sh --user --force
```

#### Post-Installation Verification

After installation, verify everything works:

```bash
# Check that hyss is available
hyss version

# Verify system dependencies
hyss update check

# Run compatibility tests
hyss update test
```

#### Directory Structure

**System-wide installation:**
- Executable: `/usr/local/bin/hyss`
- Libraries: `/usr/local/share/hyss/lib/`

**User installation:**
- Executable: `~/.local/bin/hyss`
- Libraries: `~/.local/share/hyss/lib/`

## Usage

### Basic Screenshot Operations

```bash
# Interactive area/window selection
hyss area

# Frozen screen selection (easier targeting)
hyss freeze

# Current monitor
hyss monitor

# All monitors
hyss screen

# OCR text extraction to clipboard
hyss ocr
```

### Desktop Environment Integration

Add keybindings to your DE configuration:

```bash
# Example keybindings (adapt to your DE)
Super+P              exec /path/to/hyss area
Super+Ctrl+P         exec /path/to/hyss freeze
Super+Alt+P          exec /path/to/hyss monitor
Print                exec /path/to/hyss screen
Super+Shift+S        exec /path/to/hyss ocr
```

### Hyprland Integration

HySS provides clean, simple commands that replace complex manual screenshot tool chains commonly found in Hyprland configurations.

#### Command Simplification

**Before (Complex manual chains):**
```bash
# 78 characters of complexity with multiple tools and parameters
bindd = Super+Shift, S, Screen snip, exec, hyprshot --freeze --clipboard-only --mode region --silent

# 89 characters with temporary files and cleanup
bindd = Super+Shift, T, Character recognition, exec, grim -g "$(slurp $SLURP_ARGS)" "tmp.png" && tesseract "tmp.png" - | wl-copy && rm "tmp.png"

# Multiple tools for simple fullscreen screenshot  
bindld = ,Print, Screenshot >> clipboard, exec, grim - | wl-copy
```

**After (Clean HySS commands):**
```bash
# Simple, memorable commands - just 13-18 characters each
bindd = Super+Shift, S, Screen snip, exec, hyss freeze
bindd = Super+Shift, T, Character recognition, exec, hyss ocr  
bindld = ,Print, Screenshot >> clipboard, exec, hyss screen
```

#### Ready-to-Use Hyprland Keybinds

Drop these into your `hyprland.conf` or keybinds configuration:

```bash
# Screenshot operations
bindd = Super+Shift, S, Screen snip, exec, hyss freeze           # Frozen screen region selection
bindd = Super+Alt, S, Area selection, exec, hyss area            # Interactive area selection  
bindld = ,Print, Screenshot >> clipboard, exec, hyss screen     # Fullscreen to clipboard
bindd = Super, Print, Monitor screenshot, exec, hyss monitor     # Current monitor only

# Advanced features
bindd = Super+Shift, T, Character recognition, exec, hyss ocr    # OCR text extraction
bindd = Super+Shift, C, Color picker, exec, hyprpicker -a        # Color picker (system tool)
```

#### Benefits for Dotfile Sharing

- **Cleaner configs**: Easy to read and understand at a glance
- **Reduced complexity**: No need to memorize tool-specific parameters  
- **Better maintenance**: HySS automatically handles tool updates and compatibility
- **Consistent behavior**: Same commands work regardless of underlying tool versions
- **Simplified sharing**: Others can easily understand and modify your keybinds

#### Migration from Manual Commands

Replace your existing complex screenshot commands with HySS equivalents:

| Manual Command Chain | HySS Replacement | Function |
|---------------------|------------------|----------|
| `hyprshot --freeze --clipboard-only --mode region --silent` | `hyss freeze` | Frozen screen selection |
| `grim -g "$(slurp)" \| wl-copy` | `hyss area` | Interactive region selection |
| `grim - \| wl-copy` | `hyss screen` | Fullscreen to clipboard |
| `grim $(xdg-user-dir PICTURES)/Screenshots/...` | `hyss screen` | Fullscreen with auto-save |
| `grim -g "$(slurp)" "tmp.png" && tesseract...` | `hyss ocr` | OCR text extraction |

### Environment Variables

```bash
# Force specific annotation tool
export HYSS_ANNOTATION_TOOL=satty

# Skip annotation step
export HYSS_NO_ANNOTATION=1

# Copy to clipboard only (don't save file)
export HYSS_COPY_ONLY=1

# Custom save directory
hyss area ~/Desktop/screenshots
```

### Configuration Management

HyprScreenShot uses a TOML configuration file for user-friendly settings:

```bash
# Show current configuration
hyss config show

# Edit configuration file
hyss config edit

# Get specific setting
hyss config get notifications enabled

# Set specific setting
hyss config set notifications enabled false

# Create default configuration
hyss config init

# Validate configuration
hyss config validate
```

The configuration file is located at `~/.config/hyss/config.toml` and supports:
- Notification settings (enabled, app name, urgency, timeout)
- Default directories and filename formats
- Annotation tool preferences
- Clipboard behavior settings

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
hyss update check

# Run comprehensive compatibility tests
hyss update test

# Generate detailed status report
hyss update report

# Force regenerate all configurations
hyss update force-regen

# Show migration and test history
hyss update history

# Clean old data and backups
hyss update clean
```

### Interactive Update Manager

```bash
# Launch interactive update manager
hyss update interactive
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
~/.config/hyss/                    # Configuration files
├── config.toml                    # Main configuration file
├── satty/config.toml              # Satty annotation config
└── swappy/config                  # Swappy annotation config

~/.local/share/hyss/               # Data and cache
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
hyss update status

# Install missing tools (example for Arch Linux)
sudo pacman -S grim slurp wl-clipboard satty imagemagick tesseract tesseract-data-eng jq libnotify
```

**2. "Annotation tool failed"**
```bash
# Check annotation tool status
hyss update test

# Try alternative annotation tool
export HYSS_ANNOTATION_TOOL=swappy
hyss area
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
hyss update force-regen

# Check migration history
hyss update history
```

### Debug Mode

Enable verbose output for troubleshooting:
```bash
hyss update check --verbose
```

### Compatibility Reports

Generate detailed compatibility reports:
```bash
# Generate report file
hyss update report > hyss-report.txt

# View current status
hyss update status
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
hyss area && convert ~/Pictures/Screenshots/latest.png -resize 50% ~/Pictures/Screenshots/thumbnail.png

# OCR with custom language
TESSERACT_OPTS="-l fra" hyss ocr

# Automated screenshot series
for i in {1..5}; do
    hyss screen ~/Desktop/series_$i.png
    sleep 2
done
```

### Custom Configurations

Create custom annotation configurations:

```bash
# Custom Satty config
mkdir -p ~/.config/hyss/satty
cat > ~/.config/hyss/satty/config.toml << 'EOF'
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
hyss update test

# Test specific functionality
hyss update test --verbose
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
