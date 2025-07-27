#!/usr/bin/env bash
#
# Tool Detection and Capability Management
# Handles version detection and feature capability mapping
#

# Global capability flags
declare -A TOOL_CAPABILITIES
declare -A TOOL_VERSIONS

# Tool availability cache
TOOL_CACHE_FILE="$DATA_DIR/tool-capabilities.json"

# Initialize tool capabilities
init_tool_capabilities() {
    if [[ -f "$TOOL_CACHE_FILE" ]] && [[ $(find "$TOOL_CACHE_FILE" -mtime -1 2>/dev/null) ]]; then
        # Use cached capabilities if less than 1 day old
        load_cached_capabilities
    else
        # Detect capabilities fresh
        detect_all_capabilities
        cache_capabilities
    fi
}

# Detect all tool capabilities
detect_all_capabilities() {
    echo "🔍 Detecting tool capabilities..."
    
    # Core screenshot tools
    detect_grim_capabilities
    detect_slurp_capabilities
    detect_clipboard_capabilities
    
    # Annotation tools
    detect_satty_capabilities
    detect_swappy_capabilities
    
    # Optional tools
    detect_ocr_capabilities
    detect_imagemagick_capabilities
    detect_notification_capabilities
    detect_jq_capabilities
    
    # Screen manipulation tools
    detect_screen_freeze_capabilities
}

# Grim (screenshot tool) detection
detect_grim_capabilities() {
    if ! command -v grim >/dev/null 2>&1; then
        TOOL_CAPABILITIES[grim_available]=false
        return 1
    fi
    
    TOOL_CAPABILITIES[grim_available]=true
    
    # Get version (grim doesn't provide version info easily)
    local version=""
    TOOL_VERSIONS[grim]="$version"
    
    # Test capabilities
    TOOL_CAPABILITIES[grim_geometry]=$(grim -h 2>/dev/null | grep -q -- "-g" && echo true || echo false)
    TOOL_CAPABILITIES[grim_output]=$(grim -h 2>/dev/null | grep -q -- "-o" && echo true || echo false)
    TOOL_CAPABILITIES[grim_cursor]=$(grim -h 2>/dev/null | grep -q -- "-c" && echo true || echo false)
    TOOL_CAPABILITIES[grim_scale]=$(grim -h 2>/dev/null | grep -q -- "-s" && echo true || echo false)
    TOOL_CAPABILITIES[grim_stdout]=$(grim -h 2>/dev/null | grep -q -- "'-'" && echo true || echo false)
}

# Slurp (area selection) detection
detect_slurp_capabilities() {
    if ! command -v slurp >/dev/null 2>&1; then
        TOOL_CAPABILITIES[slurp_available]=false
        return 1
    fi
    
    TOOL_CAPABILITIES[slurp_available]=true
    
    # Get version (slurp doesn't provide version info easily)
    local version=""
    TOOL_VERSIONS[slurp]="$version"
    
    # Test capabilities
    TOOL_CAPABILITIES[slurp_display]=$(slurp -h 2>/dev/null | grep -q -- "-d" && echo true || echo false)
    TOOL_CAPABILITIES[slurp_border]=$(slurp -h 2>/dev/null | grep -q -- "-b" && echo true || echo false)
    TOOL_CAPABILITIES[slurp_aspect]=$(slurp -h 2>/dev/null | grep -q -- "-a" && echo true || echo false)
}

# Clipboard capabilities
detect_clipboard_capabilities() {
    TOOL_CAPABILITIES[wl_copy_available]=$(command -v wl-copy >/dev/null 2>&1 && echo true || echo false)
    TOOL_CAPABILITIES[wl_paste_available]=$(command -v wl-paste >/dev/null 2>&1 && echo true || echo false)
    
    if [[ "${TOOL_CAPABILITIES[wl_copy_available]}" == "true" ]]; then
        local version
        version=$(wl-copy --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        TOOL_VERSIONS[wl-copy]="$version"
        
        TOOL_CAPABILITIES[wl_copy_type]=$(wl-copy --help 2>/dev/null | grep -q -- "--type" && echo true || echo false)
    fi
}

# Satty (annotation tool) detection
detect_satty_capabilities() {
    if ! command -v satty >/dev/null 2>&1; then
        TOOL_CAPABILITIES[satty_available]=false
        return 1
    fi
    
    TOOL_CAPABILITIES[satty_available]=true
    
    # Get version
    local version
    version=$(satty --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    TOOL_VERSIONS[satty]="$version"
    
    # Test capabilities based on help output
    local help_output
    help_output=$(satty --help 2>/dev/null || echo "")
    
    TOOL_CAPABILITIES[satty_copy_command]=$(echo "$help_output" | grep -q -- "--copy-command" && echo true || echo false)
    TOOL_CAPABILITIES[satty_early_exit]=$(echo "$help_output" | grep -q -- "--early-exit" && echo true || echo false)
    TOOL_CAPABILITIES[satty_fullscreen]=$(echo "$help_output" | grep -q -- "--fullscreen" && echo true || echo false)
    TOOL_CAPABILITIES[satty_config]=$(echo "$help_output" | grep -q -- "--config" && echo true || echo false)
    TOOL_CAPABILITIES[satty_output_filename]=$(echo "$help_output" | grep -q -- "--output-filename\|--output\|-o" && echo true || echo false)
    TOOL_CAPABILITIES[satty_filename]=$(echo "$help_output" | grep -q -- "--filename\|-f" && echo true || echo false)
}

# Swappy (annotation tool) detection
detect_swappy_capabilities() {
    if ! command -v swappy >/dev/null 2>&1; then
        TOOL_CAPABILITIES[swappy_available]=false
        return 1
    fi
    
    TOOL_CAPABILITIES[swappy_available]=true
    
    # Get version
    local version
    version=$(swappy --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    TOOL_VERSIONS[swappy]="$version"
    
    # Test capabilities
    local help_output
    help_output=$(swappy --help 2>/dev/null || echo "")
    
    TOOL_CAPABILITIES[swappy_file]=$(echo "$help_output" | grep -q -- "-f\|--file" && echo true || echo false)
    TOOL_CAPABILITIES[swappy_output]=$(echo "$help_output" | grep -q -- "-o\|--output-file" && echo true || echo false)
    TOOL_CAPABILITIES[swappy_config]=$(echo "$help_output" | grep -q -- "-c\|--config" && echo true || echo false)
}

# OCR capabilities
detect_ocr_capabilities() {
    TOOL_CAPABILITIES[tesseract_available]=$(command -v tesseract >/dev/null 2>&1 && echo true || echo false)
    
    if [[ "${TOOL_CAPABILITIES[tesseract_available]}" == "true" ]]; then
        local version
        version=$(tesseract --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        TOOL_VERSIONS[tesseract]="$version"
        
        # Check for English data
        TOOL_CAPABILITIES[tesseract_eng]=$(tesseract --list-langs 2>/dev/null | grep -q "eng" && echo true || echo false)
        
        # Check for stdout support
        TOOL_CAPABILITIES[tesseract_stdout]=$(tesseract --help 2>&1 | grep -q "stdout" && echo true || echo false)
    fi
}

# ImageMagick capabilities
detect_imagemagick_capabilities() {
    # Check for ImageMagick (newer versions use 'magick')
    if command -v magick >/dev/null 2>&1; then
        TOOL_CAPABILITIES[imagemagick_available]=true
        TOOL_CAPABILITIES[imagemagick_command]="magick"
        local version
        version=$(magick --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        TOOL_VERSIONS[imagemagick]="$version"
    elif command -v convert >/dev/null 2>&1; then
        TOOL_CAPABILITIES[imagemagick_available]=true
        TOOL_CAPABILITIES[imagemagick_command]="convert"
        local version
        version=$(convert --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        TOOL_VERSIONS[imagemagick]="$version"
    else
        TOOL_CAPABILITIES[imagemagick_available]=false
    fi
}

# Notification capabilities
detect_notification_capabilities() {
    TOOL_CAPABILITIES[notify_send_available]=$(command -v notify-send >/dev/null 2>&1 && echo true || echo false)
    
    if [[ "${TOOL_CAPABILITIES[notify_send_available]}" == "true" ]]; then
        # Test notification features
        TOOL_CAPABILITIES[notify_images]=$(notify-send --help 2>/dev/null | grep -q -- "-i\|--icon" && echo true || echo false)
        TOOL_CAPABILITIES[notify_urgency]=$(notify-send --help 2>/dev/null | grep -q -- "-u\|--urgency" && echo true || echo false)
        TOOL_CAPABILITIES[notify_timeout]=$(notify-send --help 2>/dev/null | grep -q -- "-t\|--timeout" && echo true || echo false)
    fi
}

# jq capabilities
detect_jq_capabilities() {
    TOOL_CAPABILITIES[jq_available]=$(command -v jq >/dev/null 2>&1 && echo true || echo false)
    
    if [[ "${TOOL_CAPABILITIES[jq_available]}" == "true" ]]; then
        # Get version
        local version
        version=$(jq --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
        TOOL_VERSIONS[jq]="$version"
        
        # Test basic jq functionality
        TOOL_CAPABILITIES[jq_basic]=$(echo '{"test": "value"}' | jq -r '.test' 2>/dev/null | grep -q "value" && echo true || echo false)
    fi
}

# Screen freeze capabilities
detect_screen_freeze_capabilities() {
    TOOL_CAPABILITIES[hyprpicker_available]=$(command -v hyprpicker >/dev/null 2>&1 && echo true || echo false)
    
    if [[ "${TOOL_CAPABILITIES[hyprpicker_available]}" == "true" ]]; then
        local help_output
        help_output=$(hyprpicker --help 2>/dev/null || echo "")
        
        TOOL_CAPABILITIES[hyprpicker_freeze]=$(echo "$help_output" | grep -q -- "-z\|--freeze" && echo true || echo false)
        TOOL_CAPABILITIES[hyprpicker_raw]=$(echo "$help_output" | grep -q -- "-r\|--raw" && echo true || echo false)
    fi
}

# Check required tools
check_required_tools() {
    local missing_tools=()
    
    # Essential tools
    [[ "${TOOL_CAPABILITIES[grim_available]:-false}" != "true" ]] && missing_tools+=("grim")
    [[ "${TOOL_CAPABILITIES[slurp_available]:-false}" != "true" ]] && missing_tools+=("slurp")
    [[ "${TOOL_CAPABILITIES[wl_copy_available]:-false}" != "true" ]] && missing_tools+=("wl-copy")
    [[ "${TOOL_CAPABILITIES[imagemagick_available]:-false}" != "true" ]] && missing_tools+=("imagemagick")
    [[ "${TOOL_CAPABILITIES[tesseract_available]:-false}" != "true" ]] && missing_tools+=("tesseract")
    [[ "${TOOL_CAPABILITIES[jq_available]:-false}" != "true" ]] && missing_tools+=("jq")
    [[ "${TOOL_CAPABILITIES[notify_send_available]:-false}" != "true" ]] && missing_tools+=("notify-send")
    
    # At least one annotation tool
    if [[ "${TOOL_CAPABILITIES[satty_available]:-false}" != "true" ]] && [[ "${TOOL_CAPABILITIES[swappy_available]:-false}" != "true" ]]; then
        missing_tools+=("satty or swappy")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo "Missing required tools: ${missing_tools[*]}" >&2
        echo "Please install the missing tools and try again." >&2
        return 1
    fi
    
    return 0
}

# Get preferred annotation tool
get_annotation_tool() {
    if [[ -n "${SCREENSHOT_ANNOTATION_TOOL:-}" ]]; then
        echo "$SCREENSHOT_ANNOTATION_TOOL"
        return 0
    fi
    
    # Prefer satty over swappy
    if [[ "${TOOL_CAPABILITIES[satty_available]:-false}" == "true" ]]; then
        echo "satty"
    elif [[ "${TOOL_CAPABILITIES[swappy_available]:-false}" == "true" ]]; then
        echo "swappy"
    else
        echo "none"
    fi
}

# Cache capabilities to file
cache_capabilities() {
    if command -v jq >/dev/null 2>&1; then
        # Use jq for proper JSON formatting
        {
            echo "{"
            echo "  \"timestamp\": $(date +%s),"
            echo "  \"capabilities\": {"
            local first=true
            for key in "${!TOOL_CAPABILITIES[@]}"; do
                [[ "$first" == "false" ]] && echo ","
                local value="${TOOL_CAPABILITIES[$key]}"
                # Quote non-boolean values
                if [[ "$value" == "true" ]] || [[ "$value" == "false" ]]; then
                    printf "    \"%s\": %s" "$key" "$value"
                else
                    printf "    \"%s\": \"%s\"" "$key" "$value"
                fi
                first=false
            done
            echo ""
            echo "  },"
            echo "  \"versions\": {"
            first=true
            for key in "${!TOOL_VERSIONS[@]}"; do
                [[ "$first" == "false" ]] && echo ","
                printf "    \"%s\": \"%s\"" "$key" "${TOOL_VERSIONS[$key]}"
                first=false
            done
            echo ""
            echo "  }"
            echo "}"
        } > "$TOOL_CACHE_FILE"
    else
        # Fallback: simple format
        {
            echo "# Tool capabilities cache - generated $(date)"
            for key in "${!TOOL_CAPABILITIES[@]}"; do
                echo "CAPABILITY_${key}=${TOOL_CAPABILITIES[$key]}"
            done
            for key in "${!TOOL_VERSIONS[@]}"; do
                echo "VERSION_${key}=${TOOL_VERSIONS[$key]}"
            done
        } > "$TOOL_CACHE_FILE"
    fi
}

# Load cached capabilities
load_cached_capabilities() {
    if [[ -f "$TOOL_CACHE_FILE" ]] && command -v jq >/dev/null 2>&1; then
        # Load from JSON cache
        while IFS='=' read -r key value; do
            [[ -n "$key" ]] && TOOL_CAPABILITIES[$key]="$value"
        done < <(jq -r '.capabilities | to_entries[] | "\(.key)=\(.value)"' "$TOOL_CACHE_FILE" 2>/dev/null || echo "")
        
        while IFS='=' read -r key value; do
            [[ -n "$key" ]] && TOOL_VERSIONS[$key]="$value"
        done < <(jq -r '.versions | to_entries[] | "\(.key)=\(.value)"' "$TOOL_CACHE_FILE" 2>/dev/null || echo "")
    else
        # Load from simple format
        if [[ -f "$TOOL_CACHE_FILE" ]]; then
            while IFS='=' read -r key value; do
                if [[ -n "$key" ]] && [[ "$key" =~ ^CAPABILITY_ ]]; then
                    TOOL_CAPABILITIES[${key#CAPABILITY_}]="$value"
                elif [[ -n "$key" ]] && [[ "$key" =~ ^VERSION_ ]]; then
                    TOOL_VERSIONS[${key#VERSION_}]="$value"
                fi
            done < "$TOOL_CACHE_FILE"
        fi
    fi
}

# Print capability report
print_capability_report() {
    echo "=== Tool Capability Report ==="
    echo ""
    
    echo "Core Tools:"
    printf "  grim:     %s" "${TOOL_CAPABILITIES[grim_available]:-false}"
    [[ -n "${TOOL_VERSIONS[grim]:-}" ]] && printf " (v%s)" "${TOOL_VERSIONS[grim]}"
    echo ""
    
    printf "  slurp:    %s" "${TOOL_CAPABILITIES[slurp_available]:-false}"
    [[ -n "${TOOL_VERSIONS[slurp]:-}" ]] && printf " (v%s)" "${TOOL_VERSIONS[slurp]}"
    echo ""
    
    printf "  wl-copy:  %s" "${TOOL_CAPABILITIES[wl_copy_available]:-false}"
    [[ -n "${TOOL_VERSIONS[wl-copy]:-}" ]] && printf " (v%s)" "${TOOL_VERSIONS[wl-copy]}"
    echo ""
    
    printf "  imagemagick: %s" "${TOOL_CAPABILITIES[imagemagick_available]:-false}"
    [[ -n "${TOOL_VERSIONS[imagemagick]:-}" ]] && printf " (v%s)" "${TOOL_VERSIONS[imagemagick]}"
    echo ""
    
    printf "  tesseract: %s" "${TOOL_CAPABILITIES[tesseract_available]:-false}"
    [[ -n "${TOOL_VERSIONS[tesseract]:-}" ]] && printf " (v%s)" "${TOOL_VERSIONS[tesseract]}"
    echo ""
    
    printf "  jq:       %s" "${TOOL_CAPABILITIES[jq_available]:-false}"
    [[ -n "${TOOL_VERSIONS[jq]:-}" ]] && printf " (v%s)" "${TOOL_VERSIONS[jq]}"
    echo ""
    
    printf "  notify-send: %s" "${TOOL_CAPABILITIES[notify_send_available]:-false}"
    [[ -n "${TOOL_VERSIONS[notify-send]:-}" ]] && printf " (v%s)" "${TOOL_VERSIONS[notify-send]}"
    echo ""
    
    echo ""
    echo "Annotation Tools:"
    printf "  satty:    %s" "${TOOL_CAPABILITIES[satty_available]:-false}"
    [[ -n "${TOOL_VERSIONS[satty]:-}" ]] && printf " (v%s)" "${TOOL_VERSIONS[satty]}"
    echo ""
    
    printf "  swappy:   %s" "${TOOL_CAPABILITIES[swappy_available]:-false}"
    [[ -n "${TOOL_VERSIONS[swappy]:-}" ]] && printf " (v%s)" "${TOOL_VERSIONS[swappy]}"
    echo ""
    
    echo ""
    echo "Selected annotation tool: $(get_annotation_tool)"
}