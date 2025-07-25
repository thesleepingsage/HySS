#!/usr/bin/env bash
#
# Annotation Abstraction Layer
# Handles different annotation tools with version compatibility
#

# Annotate screenshot with available tool
annotate_screenshot() {
    local input_file="$1"
    
    if [[ ! -f "$input_file" ]]; then
        echo "Error: Input file '$input_file' not found" >&2
        return 1
    fi
    
    local annotation_tool
    annotation_tool=$(get_annotation_tool)
    
    case "$annotation_tool" in
        satty)
            annotate_with_satty "$input_file"
            ;;
        swappy)
            annotate_with_swappy "$input_file"
            ;;
        none)
            echo "Warning: No annotation tool available, skipping annotation" >&2
            return 1
            ;;
        *)
            echo "Error: Unknown annotation tool '$annotation_tool'" >&2
            return 1
            ;;
    esac
}

# Annotate with Satty
annotate_with_satty() {
    local input_file="$1"
    
    if [[ "${TOOL_CAPABILITIES[satty_available]:-false}" != "true" ]]; then
        echo "Error: satty is not available" >&2
        return 1
    fi
    
    # Prepare satty arguments
    local satty_args=()
    
    # Input file
    if [[ "${TOOL_CAPABILITIES[satty_filename]:-false}" == "true" ]]; then
        satty_args+=("-f" "$input_file")
    else
        echo "Error: satty does not support file input" >&2
        return 1
    fi
    
    # Output file (same as input for in-place editing)
    if [[ "${TOOL_CAPABILITIES[satty_output_filename]:-false}" == "true" ]]; then
        satty_args+=("-o" "$input_file")
    fi
    
    # Copy command integration
    if [[ "${TOOL_CAPABILITIES[satty_copy_command]:-false}" == "true" ]] && [[ "${TOOL_CAPABILITIES[wl_copy_available]:-false}" == "true" ]]; then
        satty_args+=("--copy-command" "wl-copy")
    fi
    
    # Early exit for smoother workflow
    if [[ "${TOOL_CAPABILITIES[satty_early_exit]:-false}" == "true" ]]; then
        satty_args+=("--early-exit")
    fi
    
    # Fullscreen mode if requested
    if [[ -n "${SCREENSHOT_FULLSCREEN_ANNOTATION:-}" ]] && [[ "${TOOL_CAPABILITIES[satty_fullscreen]:-false}" == "true" ]]; then
        satty_args+=("--fullscreen")
    fi
    
    # Custom config if available
    local satty_config="$CONFIG_DIR/satty/config.toml"
    if [[ "${TOOL_CAPABILITIES[satty_config]:-false}" == "true" ]] && [[ -f "$satty_config" ]]; then
        satty_args+=("--config" "$satty_config")
    else
        # Ensure we have a basic config
        ensure_satty_config
        [[ -f "$satty_config" ]] && satty_args+=("--config" "$satty_config")
    fi
    
    # Launch satty
    echo "Opening annotation tool (satty)..."
    if ! satty "${satty_args[@]}"; then
        echo "Error: satty annotation failed" >&2
        return 1
    fi
    
    return 0
}

# Annotate with Swappy
annotate_with_swappy() {
    local input_file="$1"
    
    if [[ "${TOOL_CAPABILITIES[swappy_available]:-false}" != "true" ]]; then
        echo "Error: swappy is not available" >&2
        return 1
    fi
    
    # Ensure swappy config exists
    ensure_swappy_config "$input_file"
    
    # Prepare swappy arguments
    local swappy_args=()
    
    # Input file
    if [[ "${TOOL_CAPABILITIES[swappy_file]:-false}" == "true" ]]; then
        swappy_args+=("-f" "$input_file")
    else
        echo "Error: swappy does not support file input" >&2
        return 1
    fi
    
    # Output file
    if [[ "${TOOL_CAPABILITIES[swappy_output]:-false}" == "true" ]]; then
        swappy_args+=("-o" "$input_file")
    fi
    
    # Custom config
    local swappy_config="$CONFIG_DIR/swappy/config"
    if [[ "${TOOL_CAPABILITIES[swappy_config]:-false}" == "true" ]] && [[ -f "$swappy_config" ]]; then
        swappy_args+=("-c" "$swappy_config")
    fi
    
    # Launch swappy
    echo "Opening annotation tool (swappy)..."
    if ! swappy "${swappy_args[@]}"; then
        echo "Error: swappy annotation failed" >&2
        return 1
    fi
    
    return 0
}

# Ensure Satty configuration exists
ensure_satty_config() {
    local config_dir="$CONFIG_DIR/satty"
    local config_file="$config_dir/config.toml"
    
    # Create config directory
    mkdir -p "$config_dir"
    
    # Skip if config already exists and is recent
    if [[ -f "$config_file" ]] && [[ $(find "$config_file" -mtime -30 2>/dev/null) ]]; then
        return 0
    fi
    
    # Generate version-appropriate config
    local satty_version="${TOOL_VERSIONS[satty]:-unknown}"
    generate_satty_config "$satty_version" "$config_file"
}

# Generate Satty configuration based on version
generate_satty_config() {
    local version="$1"
    local config_file="$2"
    
    echo "Generating satty configuration for version $version..."
    
    # Create basic configuration that works across versions
    cat > "$config_file" << 'EOF'
[general]
# Start Satty in fullscreen mode
fullscreen = false

# Exit directly after copy/save action
early-exit = true

# Draw corners of rectangles round if the value is greater than 0
corner-roundness = 12

# Select the tool on startup
# Options: pointer, crop, line, arrow, rectangle, text, marker, blur, brush
initial-tool = "brush"

# Configure the command to be called on copy
copy-command = "wl-copy"

# Increase or decrease the size of the annotations
annotation-size-factor = 1.0

# Action to perform when the Enter key is pressed
# Options: save-to-clipboard, save-to-file
action-on-enter = "save-to-clipboard"

# After copying the screenshot, save it to a file as well
save-after-copy = false

# Hide toolbars by default
default-hide-toolbars = false

# The primary highlighter to use
# Options: block, freehand
primary-highlighter = "block"

# Disable notifications
disable-notifications = false

# Font to use for text annotations
[font]
family = "Sans"
style = "Bold"

# Custom colours for the colour palette
[color-palette]
palette = [
    "#dc143c",  # Crimson
    "#00bfff",  # Deep Sky Blue
    "#32cd32",  # Lime Green
    "#ffd700",  # Gold
    "#ff69b4",  # Hot Pink
    "#8a2be2",  # Blue Violet
    "#ff4500",  # Orange Red
    "#00ced1",  # Dark Turquoise
]
EOF
    
    # Add version-specific features
    case "$version" in
        1.0.*|1.1.*)
            # Older versions might not support all features
            echo "# Configuration for older satty version" >> "$config_file"
            ;;
        1.2.*|1.3.*|1.4.*)
            # Current versions support all features
            echo "# Configuration for current satty version" >> "$config_file"
            ;;
        *)
            # Future versions - use latest known format
            echo "# Configuration for satty version $version" >> "$config_file"
            ;;
    esac
    
    echo "✓ Satty configuration created at $config_file"
}

# Ensure Swappy configuration exists
ensure_swappy_config() {
    local input_file="$1"
    local config_dir="$CONFIG_DIR/swappy"
    local config_file="$config_dir/config"
    
    # Create config directory
    mkdir -p "$config_dir"
    
    # Always regenerate swappy config for current session
    # (swappy expects specific save directory and filename format)
    local save_dir
    save_dir=$(dirname "$input_file")
    local save_filename
    save_filename=$(basename "$input_file")
    
    cat > "$config_file" << EOF
[Default]
save_dir=$save_dir
save_filename_format=$save_filename
show_panel=true
line_size=5
text_size=20
text_font=Sans Bold
paint_mode=brush
early_exit=true
EOF
    
    echo "✓ Swappy configuration updated at $config_file"
}

# Get optimal annotation tool configuration
get_annotation_config() {
    local tool="$1"
    
    case "$tool" in
        satty)
            # Return satty-specific configuration
            echo "early_exit=true copy_command=wl-copy initial_tool=brush"
            ;;
        swappy)
            # Return swappy-specific configuration
            echo "early_exit=true show_panel=true"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Test annotation tool functionality
test_annotation_tool() {
    local tool="$1"
    
    # Create a small test image
    local test_image
    test_image=$(mktemp -t annotation_test_XXXXXX.png)
    
    # Cleanup function
    cleanup_annotation_test() {
        [[ -f "$test_image" ]] && rm -f "$test_image"
    }
    trap cleanup_annotation_test RETURN
    
    # Create a simple test image (if ImageMagick is available)
    if [[ "${TOOL_CAPABILITIES[imagemagick_available]:-false}" == "true" ]]; then
        local magick_cmd="${TOOL_CAPABILITIES[imagemagick_command]:-magick}"
        
        if "$magick_cmd" -size 100x100 xc:white -pointsize 20 -gravity center -annotate +0+0 "Test" "$test_image" 2>/dev/null; then
            echo "Created test image for annotation tool testing"
        else
            echo "Could not create test image" >&2
            return 1
        fi
    else
        # Skip test if we can't create test image
        echo "ImageMagick not available, skipping annotation tool test"
        return 0
    fi
    
    # Test tool availability
    case "$tool" in
        satty)
            if [[ "${TOOL_CAPABILITIES[satty_available]:-false}" == "true" ]]; then
                # Test if satty can read help (indicates it's working)
                if satty --help >/dev/null 2>&1; then
                    echo "✓ Satty is available and responsive"
                    return 0
                else
                    echo "✗ Satty is installed but not responsive"
                    return 1
                fi
            else
                echo "✗ Satty is not available"
                return 1
            fi
            ;;
        swappy)
            if [[ "${TOOL_CAPABILITIES[swappy_available]:-false}" == "true" ]]; then
                # Test if swappy can read help
                if swappy --help >/dev/null 2>&1; then
                    echo "✓ Swappy is available and responsive"
                    return 0
                else
                    echo "✗ Swappy is installed but not responsive"
                    return 1
                fi
            else
                echo "✗ Swappy is not available"
                return 1
            fi
            ;;
        *)
            echo "✗ Unknown annotation tool: $tool"
            return 1
            ;;
    esac
}

# Update annotation tool configurations
update_annotation_configs() {
    echo "Updating annotation tool configurations..."
    
    # Update satty config if available
    if [[ "${TOOL_CAPABILITIES[satty_available]:-false}" == "true" ]]; then
        local satty_version="${TOOL_VERSIONS[satty]:-unknown}"
        local satty_config="$CONFIG_DIR/satty/config.toml"
        
        # Backup existing config
        if [[ -f "$satty_config" ]]; then
            cp "$satty_config" "$satty_config.backup.$(date +%s)"
        fi
        
        generate_satty_config "$satty_version" "$satty_config"
    fi
    
    # Swappy config is generated dynamically, so no update needed
    
    echo "✓ Annotation tool configurations updated"
}

# Get annotation tool capabilities summary
get_annotation_capabilities() {
    local tool="$1"
    
    case "$tool" in
        satty)
            echo "Available features:"
            [[ "${TOOL_CAPABILITIES[satty_copy_command]:-false}" == "true" ]] && echo "  ✓ Copy command integration"
            [[ "${TOOL_CAPABILITIES[satty_early_exit]:-false}" == "true" ]] && echo "  ✓ Early exit support"
            [[ "${TOOL_CAPABILITIES[satty_fullscreen]:-false}" == "true" ]] && echo "  ✓ Fullscreen mode"
            [[ "${TOOL_CAPABILITIES[satty_config]:-false}" == "true" ]] && echo "  ✓ Custom configuration"
            ;;
        swappy)
            echo "Available features:"
            [[ "${TOOL_CAPABILITIES[swappy_file]:-false}" == "true" ]] && echo "  ✓ File input support"
            [[ "${TOOL_CAPABILITIES[swappy_output]:-false}" == "true" ]] && echo "  ✓ Output file support"
            [[ "${TOOL_CAPABILITIES[swappy_config]:-false}" == "true" ]] && echo "  ✓ Custom configuration"
            ;;
        *)
            echo "No capabilities information available for '$tool'"
            ;;
    esac
}