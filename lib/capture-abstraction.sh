#!/usr/bin/env bash
#
# Capture Abstraction Layer
# Handles different screenshot capture methods with version compatibility
#

# Capture area interactively
capture_area() {
    local output_file="$1"
    
    if [[ "${TOOL_CAPABILITIES[grim_available]:-false}" != "true" ]] || [[ "${TOOL_CAPABILITIES[slurp_available]:-false}" != "true" ]]; then
        echo "Error: grim and slurp are required for area capture" >&2
        return 1
    fi
    
    # Get geometry from slurp
    local geometry
    if ! geometry=$(slurp 2>/dev/null); then
        echo "Area selection cancelled" >&2
        return 1
    fi
    
    # Use grim to capture the selected area
    local grim_args=()
    
    # Add geometry if supported
    if [[ "${TOOL_CAPABILITIES[grim_geometry]:-false}" == "true" ]]; then
        grim_args+=("-g" "$geometry")
    fi
    
    # Add cursor if supported and not explicitly disabled
    if [[ "${TOOL_CAPABILITIES[grim_cursor]:-false}" == "true" ]] && [[ -z "${SCREENSHOT_NO_CURSOR:-}" ]]; then
        grim_args+=("-c")
    fi
    
    # Capture screenshot
    if ! grim "${grim_args[@]}" "$output_file"; then
        echo "Error: Failed to capture screenshot" >&2
        return 1
    fi
    
    return 0
}

# Capture area with frozen screen
capture_area_frozen() {
    local output_file="$1"
    local freeze_pid=""
    
    # Cleanup function for frozen screen
    cleanup_freeze() {
        if [[ -n "$freeze_pid" ]] && kill -0 "$freeze_pid" 2>/dev/null; then
            kill "$freeze_pid" 2>/dev/null || true
        fi
    }
    trap cleanup_freeze RETURN
    
    # Try to freeze screen if hyprpicker is available
    if [[ "${TOOL_CAPABILITIES[hyprpicker_available]:-false}" == "true" ]] && [[ "${TOOL_CAPABILITIES[hyprpicker_freeze]:-false}" == "true" ]]; then
        echo "Freezing screen..."
        hyprpicker -r -z &
        freeze_pid=$!
        sleep 0.2  # Allow hyprpicker to initialize
    else
        echo "Screen freeze not available, using regular selection..."
    fi
    
    # Perform area capture
    capture_area "$output_file"
    local result=$?
    
    # Cleanup freeze
    cleanup_freeze
    
    return $result
}

# Capture current monitor
capture_monitor() {
    local output_file="$1"
    
    if [[ "${TOOL_CAPABILITIES[grim_available]:-false}" != "true" ]]; then
        echo "Error: grim is required for monitor capture" >&2
        return 1
    fi
    
    local grim_args=()
    
    # Try to get current monitor if grim supports output selection
    if [[ "${TOOL_CAPABILITIES[grim_output]:-false}" == "true" ]]; then
        local current_output
        
        # Try different methods to get current output
        if command -v hyprctl >/dev/null 2>&1; then
            # Hyprland method
            current_output=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null || echo "")
        elif command -v wlr-randr >/dev/null 2>&1; then
            # wlr-randr method
            current_output=$(wlr-randr --json 2>/dev/null | jq -r '.[] | select(.enabled == true) | .name' 2>/dev/null | head -1 || echo "")
        elif command -v swaymsg >/dev/null 2>&1; then
            # Sway method
            current_output=$(swaymsg -t get_outputs 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null || echo "")
        fi
        
        if [[ -n "$current_output" ]]; then
            grim_args+=("-o" "$current_output")
        else
            echo "Warning: Could not determine current monitor, capturing all outputs" >&2
        fi
    fi
    
    # Add cursor if supported and not disabled
    if [[ "${TOOL_CAPABILITIES[grim_cursor]:-false}" == "true" ]] && [[ -z "${SCREENSHOT_NO_CURSOR:-}" ]]; then
        grim_args+=("-c")
    fi
    
    # Capture screenshot
    if ! grim "${grim_args[@]}" "$output_file"; then
        echo "Error: Failed to capture monitor screenshot" >&2
        return 1
    fi
    
    return 0
}

# Capture all screens
capture_screen() {
    local output_file="$1"
    
    if [[ "${TOOL_CAPABILITIES[grim_available]:-false}" != "true" ]]; then
        echo "Error: grim is required for screen capture" >&2
        return 1
    fi
    
    local grim_args=()
    
    # Add cursor if supported and not disabled
    if [[ "${TOOL_CAPABILITIES[grim_cursor]:-false}" == "true" ]] && [[ -z "${SCREENSHOT_NO_CURSOR:-}" ]]; then
        grim_args+=("-c")
    fi
    
    # Add scale if specified
    if [[ -n "${SCREENSHOT_SCALE:-}" ]] && [[ "${TOOL_CAPABILITIES[grim_scale]:-false}" == "true" ]]; then
        grim_args+=("-s" "$SCREENSHOT_SCALE")
    fi
    
    # Capture all screens
    if ! grim "${grim_args[@]}" "$output_file"; then
        echo "Error: Failed to capture screen screenshot" >&2
        return 1
    fi
    
    return 0
}

# Enhanced capture with clipboard integration
capture_with_clipboard() {
    local mode="$1"
    local output_file="$2"
    
    # Check if we can use stdout and pipe to clipboard
    if [[ "${TOOL_CAPABILITIES[grim_stdout]:-false}" == "true" ]] && [[ "${TOOL_CAPABILITIES[wl_copy_available]:-false}" == "true" ]]; then
        # Use the efficient tee pipeline method (like HyDE's grimblast)
        case "$mode" in
            area)
                local geometry
                if ! geometry=$(slurp 2>/dev/null); then
                    echo "Area selection cancelled" >&2
                    return 1
                fi
                
                local grim_args=("-g" "$geometry")
                [[ "${TOOL_CAPABILITIES[grim_cursor]:-false}" == "true" ]] && [[ -z "${SCREENSHOT_NO_CURSOR:-}" ]] && grim_args+=("-c")
                
                grim "${grim_args[@]}" - | tee "$output_file" | copy_to_clipboard_raw
                ;;
            monitor)
                local current_output=""
                if [[ "${TOOL_CAPABILITIES[grim_output]:-false}" == "true" ]]; then
                    current_output=$(get_current_monitor)
                fi
                
                local grim_args=()
                [[ -n "$current_output" ]] && grim_args+=("-o" "$current_output")
                [[ "${TOOL_CAPABILITIES[grim_cursor]:-false}" == "true" ]] && [[ -z "${SCREENSHOT_NO_CURSOR:-}" ]] && grim_args+=("-c")
                
                grim "${grim_args[@]}" - | tee "$output_file" | copy_to_clipboard_raw
                ;;
            screen)
                local grim_args=()
                [[ "${TOOL_CAPABILITIES[grim_cursor]:-false}" == "true" ]] && [[ -z "${SCREENSHOT_NO_CURSOR:-}" ]] && grim_args+=("-c")
                [[ -n "${SCREENSHOT_SCALE:-}" ]] && [[ "${TOOL_CAPABILITIES[grim_scale]:-false}" == "true" ]] && grim_args+=("-s" "$SCREENSHOT_SCALE")
                
                grim "${grim_args[@]}" - | tee "$output_file" | copy_to_clipboard_raw
                ;;
        esac
    else
        # Fallback: capture to file then copy
        case "$mode" in
            area) capture_area "$output_file" ;;
            monitor) capture_monitor "$output_file" ;;
            screen) capture_screen "$output_file" ;;
        esac
        
        if [[ $? -eq 0 ]]; then
            copy_to_clipboard "$output_file"
        fi
    fi
}

# OCR text extraction workflow
extract_text_ocr() {
    if [[ "${TOOL_CAPABILITIES[tesseract_available]:-false}" != "true" ]]; then
        echo "Error: tesseract is required for OCR functionality" >&2
        echo "Please install tesseract and tesseract-data-eng packages" >&2
        return 1
    fi
    
    if [[ "${TOOL_CAPABILITIES[tesseract_eng]:-false}" != "true" ]]; then
        echo "Error: tesseract English language data not found" >&2
        echo "Please install tesseract-data-eng package" >&2
        return 1
    fi
    
    # Get area selection for OCR
    local geometry
    if ! geometry=$(slurp 2>/dev/null); then
        echo "OCR area selection cancelled" >&2
        return 1
    fi
    
    # Create temporary file for OCR image
    local ocr_temp
    ocr_temp=$(mktemp -t ocr_screenshot_XXXXXX.png)
    
    # Cleanup function
    cleanup_ocr() {
        [[ -f "$ocr_temp" ]] && rm -f "$ocr_temp"
    }
    trap cleanup_ocr RETURN
    
    # Capture the selected area
    local grim_args=("-g" "$geometry")
    if ! grim "${grim_args[@]}" "$ocr_temp"; then
        echo "Error: Failed to capture OCR area" >&2
        return 1
    fi
    
    # Enhance image for better OCR if ImageMagick is available
    if [[ "${TOOL_CAPABILITIES[imagemagick_available]:-false}" == "true" ]]; then
        local magick_cmd="${TOOL_CAPABILITIES[imagemagick_command]:-magick}"
        
        # Apply contrast enhancement for better OCR
        if "$magick_cmd" "$ocr_temp" -sigmoidal-contrast 10,50% "$ocr_temp" 2>/dev/null; then
            echo "Image enhanced for OCR"
        fi
    fi
    
    # Extract text with tesseract
    local extracted_text
    if [[ "${TOOL_CAPABILITIES[tesseract_stdout]:-false}" == "true" ]]; then
        # Use stdout method
        extracted_text=$(tesseract "$ocr_temp" - 2>/dev/null)
    else
        # Use temporary output file method
        local ocr_output
        ocr_output=$(mktemp -t ocr_output_XXXXXX.txt)
        
        if tesseract "$ocr_temp" "${ocr_output%.txt}" 2>/dev/null; then
            extracted_text=$(cat "$ocr_output" 2>/dev/null || echo "")
        fi
        
        [[ -f "$ocr_output" ]] && rm -f "$ocr_output"
    fi
    
    # Copy extracted text to clipboard
    if [[ -n "$extracted_text" ]]; then
        echo "$extracted_text" | copy_text_to_clipboard
        
        # Show notification with preview
        if [[ "${TOOL_CAPABILITIES[notify_send_available]:-false}" == "true" ]]; then
            local preview
            preview=$(echo "$extracted_text" | head -c 100)
            [[ ${#extracted_text} -gt 100 ]] && preview="$preview..."
            
            if [[ "${TOOL_CAPABILITIES[notify_images]:-false}" == "true" ]]; then
                notify-send -a "Screenshot Tool" "OCR Text Extracted" "$preview" -i "$ocr_temp"
            else
                notify-send -a "Screenshot Tool" "OCR Text Extracted" "$preview"
            fi
        fi
        
        echo "Text extracted and copied to clipboard:"
        echo "$extracted_text"
    else
        echo "Error: No text could be extracted from the selected area" >&2
        return 1
    fi
    
    return 0
}

# Get current monitor (utility function)
get_current_monitor() {
    local current_output=""
    
    # Try different methods to get current output
    if command -v hyprctl >/dev/null 2>&1; then
        # Hyprland method
        current_output=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null || echo "")
    elif command -v wlr-randr >/dev/null 2>&1; then
        # wlr-randr method  
        current_output=$(wlr-randr --json 2>/dev/null | jq -r '.[] | select(.enabled == true) | .name' 2>/dev/null | head -1 || echo "")
    elif command -v swaymsg >/dev/null 2>&1; then
        # Sway method
        current_output=$(swaymsg -t get_outputs 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null || echo "")
    fi
    
    echo "$current_output"
}

# Test capture functionality
test_capture_functionality() {
    echo "Testing capture functionality..."
    
    local test_file
    test_file=$(mktemp -t capture_test_XXXXXX.png)
    
    # Cleanup function
    cleanup_test() {
        [[ -f "$test_file" ]] && rm -f "$test_file"
    }
    trap cleanup_test RETURN
    
    # Test screen capture (least interactive)
    if capture_screen "$test_file"; then
        if [[ -f "$test_file" ]] && [[ -s "$test_file" ]]; then
            echo "✓ Screen capture test passed"
            return 0
        else
            echo "✗ Screen capture test failed: empty or missing file"
            return 1
        fi
    else
        echo "✗ Screen capture test failed"
        return 1
    fi
}