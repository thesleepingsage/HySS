#!/usr/bin/env bash
#
# HyprScreenShot Configuration System
# Handles TOML configuration loading and management
#

# Default configuration values
HYSS_NOTIFICATIONS="${HYSS_NOTIFICATIONS:-true}"
HYSS_NOTIFICATION_APP_NAME="${HYSS_NOTIFICATION_APP_NAME:-HyprScreenShot}"
HYSS_NOTIFICATION_URGENCY="${HYSS_NOTIFICATION_URGENCY:-normal}"
HYSS_NOTIFICATION_TIMEOUT="${HYSS_NOTIFICATION_TIMEOUT:-3000}"
HYSS_NOTIFICATION_SHOW_PREVIEW="${HYSS_NOTIFICATION_SHOW_PREVIEW:-true}"
HYSS_DEFAULT_DIRECTORY="${HYSS_DEFAULT_DIRECTORY:-}"
HYSS_FILENAME_FORMAT="${HYSS_FILENAME_FORMAT:-%y%m%d_%Hh%Mm%Ss_hyss.png}"
HYSS_COPY_TO_CLIPBOARD="${HYSS_COPY_TO_CLIPBOARD:-true}"
HYSS_ANNOTATION_TOOL="${HYSS_ANNOTATION_TOOL:-auto}"

# Configuration file path
HYSS_CONFIG_FILE="$CONFIG_DIR/config.toml"

# Initialize configuration system
init_hyss_config() {
    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"

    # Create default config if it doesn't exist
    if [[ ! -f "$HYSS_CONFIG_FILE" ]]; then
        create_default_config
    fi

    # Load configuration
    load_hyss_config
}

# Create default TOML configuration
create_default_config() {
    cat > "$HYSS_CONFIG_FILE" << 'EOF'
[general]
# HyprScreenShot Configuration
app_name = "hyss"
version = "1.0.0"

[notifications]
enabled = true
app_name = "HyprScreenShot"
urgency = "normal"     # low, normal, critical
timeout = 3000         # milliseconds
show_preview = true    # show image preview in notifications

[screenshots]
default_directory = ""                           # empty = use XDG Pictures/Screenshots
filename_format = "%y%m%d_%Hh%Mm%Ss_hyss.png"  # date format for filenames
copy_to_clipboard = true                         # automatically copy to clipboard

[tools]
# Tool preferences (auto-detected if not specified)
annotation_tool = "auto"                         # auto, satty, swappy, none
EOF

    echo "✓ Created default configuration at $HYSS_CONFIG_FILE"
}

# Simple TOML parser for our specific needs
parse_toml_value() {
    local file="$1"
    local section="$2"
    local key="$3"
    local default_value="$4"

    if [[ ! -f "$file" ]]; then
        echo "$default_value"
        return
    fi

    # Simple TOML parsing using awk
    local value
    value=$(awk -v section="$section" -v key="$key" '
        BEGIN { in_section = 0 }
        /^\[.*\]$/ {
            current_section = substr($0, 2, length($0)-2)
            in_section = (current_section == section)
            next
        }
        in_section && /^[[:space:]]*[^#]/ {
            if (match($0, "^[[:space:]]*" key "[[:space:]]*=[[:space:]]*(.*)$", arr)) {
                value = arr[1]
                # Remove quotes if present
                gsub(/^"/, "", value)
                gsub(/"$/, "", value)
                gsub(/^'"'"'/, "", value)
                gsub(/'"'"'$/, "", value)
                # Remove trailing comments
                gsub(/[[:space:]]*#.*$/, "", value)
                print value
                exit
            }
        }
    ' "$file")

    if [[ -n "$value" ]]; then
        echo "$value"
    else
        echo "$default_value"
    fi
}

# Load configuration from TOML file
load_hyss_config() {
    if [[ ! -f "$HYSS_CONFIG_FILE" ]]; then
        return 0
    fi

    # Load notification settings
    HYSS_NOTIFICATIONS=$(parse_toml_value "$HYSS_CONFIG_FILE" "notifications" "enabled" "$HYSS_NOTIFICATIONS")
    HYSS_NOTIFICATION_APP_NAME=$(parse_toml_value "$HYSS_CONFIG_FILE" "notifications" "app_name" "$HYSS_NOTIFICATION_APP_NAME")
    HYSS_NOTIFICATION_URGENCY=$(parse_toml_value "$HYSS_CONFIG_FILE" "notifications" "urgency" "$HYSS_NOTIFICATION_URGENCY")
    HYSS_NOTIFICATION_TIMEOUT=$(parse_toml_value "$HYSS_CONFIG_FILE" "notifications" "timeout" "$HYSS_NOTIFICATION_TIMEOUT")
    HYSS_NOTIFICATION_SHOW_PREVIEW=$(parse_toml_value "$HYSS_CONFIG_FILE" "notifications" "show_preview" "$HYSS_NOTIFICATION_SHOW_PREVIEW")

    # Load screenshot settings
    HYSS_DEFAULT_DIRECTORY=$(parse_toml_value "$HYSS_CONFIG_FILE" "screenshots" "default_directory" "$HYSS_DEFAULT_DIRECTORY")
    HYSS_FILENAME_FORMAT=$(parse_toml_value "$HYSS_CONFIG_FILE" "screenshots" "filename_format" "$HYSS_FILENAME_FORMAT")
    HYSS_COPY_TO_CLIPBOARD=$(parse_toml_value "$HYSS_CONFIG_FILE" "screenshots" "copy_to_clipboard" "$HYSS_COPY_TO_CLIPBOARD")

    # Load tool settings
    HYSS_ANNOTATION_TOOL=$(parse_toml_value "$HYSS_CONFIG_FILE" "tools" "annotation_tool" "$HYSS_ANNOTATION_TOOL")

    # Export for use in other scripts
    export HYSS_NOTIFICATIONS HYSS_NOTIFICATION_APP_NAME HYSS_NOTIFICATION_URGENCY
    export HYSS_NOTIFICATION_TIMEOUT HYSS_NOTIFICATION_SHOW_PREVIEW
    export HYSS_DEFAULT_DIRECTORY HYSS_FILENAME_FORMAT HYSS_COPY_TO_CLIPBOARD
    export HYSS_ANNOTATION_TOOL
}

# Enhanced notification function with configuration support
notify_hyss() {
    # Check if notifications are enabled
    if [[ "$HYSS_NOTIFICATIONS" != "true" ]]; then
        return 0
    fi

    local message="$1"
    local image_path="${2:-}"

    # Check if notify-send is available
    if ! command -v notify-send >/dev/null 2>&1; then
        return 0
    fi

    # Build notification arguments
    local notify_args=("-a" "$HYSS_NOTIFICATION_APP_NAME")

    # Add urgency if specified
    if [[ -n "$HYSS_NOTIFICATION_URGENCY" ]]; then
        notify_args+=("-u" "$HYSS_NOTIFICATION_URGENCY")
    fi

    # Add timeout if specified
    if [[ -n "$HYSS_NOTIFICATION_TIMEOUT" ]] && [[ "$HYSS_NOTIFICATION_TIMEOUT" != "0" ]]; then
        notify_args+=("-t" "$HYSS_NOTIFICATION_TIMEOUT")
    fi

    # Add image preview if enabled and available
    if [[ "$HYSS_NOTIFICATION_SHOW_PREVIEW" == "true" ]] && [[ -n "$image_path" ]] && [[ -f "$image_path" ]]; then
        notify_args+=("-i" "$image_path")
    fi

    # Send notification
    notify-send "${notify_args[@]}" "$message"
}

# Configuration management functions
show_hyss_config() {
    echo "=== HyprScreenShot Configuration ==="
    echo ""
    echo "Configuration file: $HYSS_CONFIG_FILE"
    echo ""

    if [[ -f "$HYSS_CONFIG_FILE" ]]; then
        echo "Current settings:"
        echo ""
        cat "$HYSS_CONFIG_FILE"
    else
        echo "No configuration file found. Default settings in use."
        echo ""
        echo "Run 'hyss config init' to create a configuration file."
    fi
}

# Edit configuration file
edit_hyss_config() {
    local editor="${EDITOR:-nano}"

    # Ensure config exists
    if [[ ! -f "$HYSS_CONFIG_FILE" ]]; then
        create_default_config
    fi

    echo "Opening configuration file with $editor..."
    "$editor" "$HYSS_CONFIG_FILE"

    # Reload configuration after editing
    load_hyss_config
    echo "✓ Configuration reloaded"
}

# Reset configuration to defaults
reset_hyss_config() {
    echo "Resetting configuration to defaults..."

    # Backup existing config
    if [[ -f "$HYSS_CONFIG_FILE" ]]; then
        local backup_file="$HYSS_CONFIG_FILE.backup.$(date +%s)"
        cp "$HYSS_CONFIG_FILE" "$backup_file"
        echo "✓ Backed up existing config to $backup_file"
    fi

    # Create new default config
    create_default_config
    load_hyss_config
    echo "✓ Configuration reset to defaults"
}

# Validate configuration file
validate_hyss_config() {
    if [[ ! -f "$HYSS_CONFIG_FILE" ]]; then
        echo "No configuration file found at $HYSS_CONFIG_FILE"
        return 1
    fi

    # Basic TOML syntax validation
    local syntax_errors=0

    # Check for balanced brackets
    local bracket_count
    bracket_count=$(grep -c '^\[.*\]$' "$HYSS_CONFIG_FILE" || echo "0")

    if [[ "$bracket_count" -eq 0 ]]; then
        echo "Warning: No TOML sections found in configuration file"
        syntax_errors=$((syntax_errors + 1))
    fi

    # Check for basic key=value format
    if ! grep -q '.*=.*' "$HYSS_CONFIG_FILE"; then
        echo "Warning: No key=value pairs found in configuration file"
        syntax_errors=$((syntax_errors + 1))
    fi

    if [[ "$syntax_errors" -eq 0 ]]; then
        echo "✓ Configuration file syntax appears valid"
        return 0
    else
        echo "⚠ Configuration file has potential syntax issues"
        return 1
    fi
}

# Get configuration value
get_hyss_config_value() {
    local section="$1"
    local key="$2"

    if [[ ! -f "$HYSS_CONFIG_FILE" ]]; then
        echo "Configuration file not found"
        return 1
    fi

    local value
    value=$(parse_toml_value "$HYSS_CONFIG_FILE" "$section" "$key" "")

    if [[ -n "$value" ]]; then
        echo "$value"
    else
        echo "Key '$section.$key' not found"
        return 1
    fi
}

# Set configuration value (simple implementation)
set_hyss_config_value() {
    local section="$1"
    local key="$2"
    local new_value="$3"

    if [[ ! -f "$HYSS_CONFIG_FILE" ]]; then
        create_default_config
    fi

    # Simple approach: use sed to update the value
    # This is basic but functional for our use case
    local temp_file
    temp_file=$(mktemp)

    awk -v section="$section" -v key="$key" -v new_value="$new_value" '
        BEGIN { in_section = 0; updated = 0 }
        /^\[.*\]$/ {
            current_section = substr($0, 2, length($0)-2)
            in_section = (current_section == section)
            print
            next
        }
        in_section && /^[[:space:]]*[^#]/ {
            if (match($0, "^[[:space:]]*" key "[[:space:]]*=")) {
                print key " = \"" new_value "\""
                updated = 1
                next
            }
        }
        { print }
        END {
            if (!updated) {
                print "# Warning: Could not update " section "." key
            }
        }
    ' "$HYSS_CONFIG_FILE" > "$temp_file"

    mv "$temp_file" "$HYSS_CONFIG_FILE"

    # Reload configuration
    load_hyss_config
    echo "✓ Updated $section.$key = $new_value"
}
