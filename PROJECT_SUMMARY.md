# HySS (HyprShot System) - Project Summary

## What is HySS?

HySS is an **update-resilient screenshot utility** that provides the complete functionality of HyDE's screenshot system while being **portable, maintainable, and DE-agnostic**.

## Origin Story

This project emerged from reverse-engineering HyDE's sophisticated screenshot implementation, which combines:
- **grim** (Wayland screenshot utility)
- **slurp** (interactive area selection)
- **satty/swappy** (annotation tools)
- **wl-copy** (clipboard integration)
- **tesseract** (OCR text extraction)

The original HyDE system is tightly integrated with Hyprland and requires manual maintenance when dependencies update. HySS solves this by providing **automatic adaptation to tool updates**.

## Architecture Innovation

### The Update Problem
When screenshot tools like `grim`, `satty`, or `slurp` update:
- Configuration formats may change
- Command-line options may be added/removed/renamed
- Features may be deprecated or enhanced
- Integration between tools may break

### HySS Solution: **Abstraction Layer Architecture**

```
User Command
    ↓
screenshot-tool (main orchestrator)
    ↓
Abstraction Layers:
├─ Tool Detection      (detects versions & capabilities)
├─ Capture Abstraction (handles grim+slurp integration)
├─ Annotation Layer    (manages satty/swappy)
├─ Clipboard Layer     (handles wl-copy operations)
├─ Migration System    (updates configs automatically)
└─ Testing Framework   (verifies compatibility)
```

### Key Innovation: **Dynamic Capability Detection**

Instead of hardcoding tool behavior, HySS:
1. **Detects** what tools are available and their versions
2. **Tests** what features each tool supports
3. **Adapts** configuration and behavior accordingly
4. **Migrates** settings when tools update
5. **Validates** everything still works

## Core Features

### Screenshot Modes
- **Area Selection**: Interactive region/window selection
- **Frozen Selection**: Selection on frozen screen (easier targeting)
- **Monitor Capture**: Current monitor only
- **Screen Capture**: All monitors
- **OCR Mode**: Text extraction to clipboard

### Update Resilience
- **Automatic tool detection** and capability mapping
- **Configuration migration** when tools update
- **Compatibility testing** after changes
- **Graceful degradation** when features aren't available
- **Detailed reporting** of system status

### Cross-Platform Design
- **DE-agnostic**: Works with any desktop environment
- **Wayland-focused**: Optimized for modern Wayland compositors
- **Fallback mechanisms**: Continues working even when advanced features fail

## Technical Implementation

### File Structure
```
HySS/
├── screenshot-tool              # Main screenshot utility
├── screenshot-tool-update       # Update management system
├── lib/                        # Abstraction layer modules
│   ├── tool-detection.sh       # Version & capability detection
│   ├── capture-abstraction.sh  # Screenshot capture methods
│   ├── annotation-abstraction.sh # Annotation tool integration
│   ├── clipboard-abstraction.sh # Clipboard operations
│   ├── migration-system.sh     # Configuration migrations
│   └── compatibility-testing.sh # Automated testing
├── README.md                   # User documentation
├── CONTRIBUTING.md             # Developer guidelines
└── CHANGELOG.md               # Version history
```

### Example: How Updates Are Handled

**Scenario**: Satty updates from v1.1 to v1.2 with new config format

1. **Detection**: HySS detects version change on next run
2. **Migration**: Automatically converts config from v1.1 to v1.2 format
3. **Testing**: Runs compatibility tests to verify everything works
4. **Reporting**: Shows user what changed and current status
5. **Fallback**: If migration fails, falls back to generating new config

**User Experience**: Screenshot tool continues working seamlessly, with optional detailed report available.

## Unique Value Proposition

### For Users
- **Zero maintenance**: Tool updates handle themselves
- **Never breaks**: Robust fallback mechanisms
- **Full featured**: All the power of HyDE's system
- **Portable**: Works across different desktop environments

### For Developers
- **Modular architecture**: Easy to extend and modify
- **Comprehensive testing**: Built-in compatibility verification
- **Clear abstraction**: Each component has well-defined responsibilities
- **Migration framework**: Structured approach to handling updates

### For System Administrators
- **Predictable behavior**: Detailed logging and reporting
- **Automatic adaptation**: No manual intervention required
- **Compatibility monitoring**: Early warning of issues
- **Easy deployment**: Single tool with clear dependencies

## Development Workflow

- **`main`** branch: Stable releases only
- **`dev`** branch: Active development
- **Feature branches**: New functionality development
- **Comprehensive testing**: Every change validated
- **Semantic versioning**: Clear version progression

## Future Roadmap

### Planned Enhancements
- Support for additional screenshot tools (grimshot, wayshot)
- Additional annotation tools (krita, gimp integration)
- Advanced OCR features (multiple languages, formatting)
- Integration with cloud storage services
- Plugin system for custom extensions

### Architectural Goals
- Maintain zero-maintenance user experience
- Expand cross-platform compatibility
- Enhance testing and validation capabilities
- Improve performance and resource usage

## Success Metrics

- **Reliability**: Users never experience broken functionality due to tool updates
- **Adoption**: Easy migration from HyDE and other screenshot tools
- **Maintainability**: Contributors can easily add new features and tools
- **Performance**: Matches or exceeds HyDE's screenshot performance
- **Compatibility**: Works across wide range of desktop environments

---

**HySS represents a new approach to tool integration**: instead of brittle scripts that break with updates, we have a **resilient system that adapts and evolves** with its dependencies while maintaining a consistent user experience.