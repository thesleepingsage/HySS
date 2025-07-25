#!/usr/bin/env bash
#
# Clipboard Abstraction Layer
# Handles clipboard operations with different tools and methods
#

# Copy image file to clipboard
copy_to_clipboard() {
    local image_file="$1"
    
    if [[ ! -f "$image_file" ]]; then
        echo "Error: Image file '$image_file' not found" >&2
        return 1
    fi
    
    if [[ "${TOOL_CAPABILITIES[wl_copy_available]:-false}" == "true" ]]; then
        copy_image_wl_copy "$image_file"
    else
        echo "Error: No clipboard tool available" >&2
        return 1
    fi
}

# Copy raw image data to clipboard (from stdin)
copy_to_clipboard_raw() {
    if [[ "${TOOL_CAPABILITIES[wl_copy_available]:-false}" == "true" ]]; then
        copy_image_wl_copy_raw
    else
        echo "Error: No clipboard tool available" >&2
        return 1
    fi
}

# Copy text to clipboard
copy_text_to_clipboard() {
    if [[ "${TOOL_CAPABILITIES[wl_copy_available]:-false}" == "true" ]]; then
        copy_text_wl_copy
    else
        echo "Error: No clipboard tool available" >&2
        return 1
    fi
}

# Copy image to clipboard using wl-copy
copy_image_wl_copy() {
    local image_file="$1"
    
    # Check if wl-copy supports type specification
    if [[ "${TOOL_CAPABILITIES[wl_copy_type]:-false}" == "true" ]]; then
        if wl-copy --type image/png < "$image_file"; then
            echo "✓ Image copied to clipboard"
            return 0
        else
            echo "Error: Failed to copy image to clipboard" >&2
            return 1
        fi
    else
        # Fallback for older wl-copy versions
        if wl-copy < "$image_file"; then
            echo "✓ Image copied to clipboard (no type specification)"
            return 0
        else
            echo "Error: Failed to copy image to clipboard" >&2
            return 1
        fi
    fi
}

# Copy raw image data from stdin using wl-copy
copy_image_wl_copy_raw() {
    # Check if wl-copy supports type specification
    if [[ "${TOOL_CAPABILITIES[wl_copy_type]:-false}" == "true" ]]; then
        if wl-copy --type image/png; then
            return 0
        else
            echo "Error: Failed to copy image data to clipboard" >&2
            return 1
        fi
    else
        # Fallback for older wl-copy versions
        if wl-copy; then
            return 0
        else
            echo "Error: Failed to copy image data to clipboard" >&2
            return 1
        fi
    fi
}

# Copy text from stdin using wl-copy
copy_text_wl_copy() {
    if wl-copy; then
        return 0
    else
        echo "Error: Failed to copy text to clipboard" >&2
        return 1
    fi
}

# Get clipboard contents (if supported)
get_clipboard_contents() {
    if [[ "${TOOL_CAPABILITIES[wl_paste_available]:-false}" == "true" ]]; then
        wl-paste 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Check if clipboard has image data
clipboard_has_image() {
    if [[ "${TOOL_CAPABILITIES[wl_paste_available]:-false}" == "true" ]]; then
        # Check if clipboard has image MIME type
        local mime_types
        mime_types=$(wl-paste --list-types 2>/dev/null || echo "")
        
        if echo "$mime_types" | grep -q "image/"; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi
}

# Save clipboard image to file
save_clipboard_image() {
    local output_file="$1"
    
    if [[ "${TOOL_CAPABILITIES[wl_paste_available]:-false}" != "true" ]]; then
        echo "Error: wl-paste is not available" >&2
        return 1
    fi
    
    if ! clipboard_has_image; then
        echo "Error: No image data in clipboard" >&2
        return 1
    fi
    
    # Try to get image data
    if wl-paste --type image/png > "$output_file" 2>/dev/null; then
        echo "✓ Clipboard image saved to $output_file"
        return 0
    elif wl-paste > "$output_file" 2>/dev/null; then
        echo "✓ Clipboard contents saved to $output_file (type unknown)"
        return 0
    else
        echo "Error: Failed to save clipboard image" >&2
        return 1
    fi
}

# Clear clipboard
clear_clipboard() {
    if [[ "${TOOL_CAPABILITIES[wl_copy_available]:-false}" == "true" ]]; then
        if wl-copy --clear 2>/dev/null; then
            echo "✓ Clipboard cleared"
            return 0
        else
            # Fallback: copy empty string
            echo -n "" | wl-copy
            echo "✓ Clipboard cleared (fallback method)"
            return 0
        fi
    else
        echo "Error: No clipboard tool available to clear clipboard" >&2
        return 1
    fi
}

# Test clipboard functionality
test_clipboard_functionality() {
    echo "Testing clipboard functionality..."
    
    if [[ "${TOOL_CAPABILITIES[wl_copy_available]:-false}" != "true" ]]; then
        echo "✗ wl-copy not available"
        return 1
    fi
    
    # Test text copying
    local test_text="Screenshot tool clipboard test"
    if echo "$test_text" | copy_text_to_clipboard; then
        echo "✓ Text copy test passed"
        
        # Test reading back if wl-paste is available
        if [[ "${TOOL_CAPABILITIES[wl_paste_available]:-false}" == "true" ]]; then
            local retrieved_text
            retrieved_text=$(get_clipboard_contents)
            
            if [[ "$retrieved_text" == "$test_text" ]]; then
                echo "✓ Text retrieval test passed"
            else
                echo "⚠ Text retrieval test failed (copied: '$test_text', retrieved: '$retrieved_text')"
            fi
        fi
    else
        echo "✗ Text copy test failed"
        return 1
    fi
    
    # Test image copying if we have a test image
    local test_image
    test_image=$(mktemp -t clipboard_test_XXXXXX.png)
    
    # Cleanup function
    cleanup_clipboard_test() {
        [[ -f "$test_image" ]] && rm -f "$test_image"
    }
    trap cleanup_clipboard_test RETURN
    
    # Create a minimal test image if ImageMagick is available
    if [[ "${TOOL_CAPABILITIES[imagemagick_available]:-false}" == "true" ]]; then
        local magick_cmd="${TOOL_CAPABILITIES[imagemagick_command]:-magick}"
        
        if "$magick_cmd" -size 10x10 xc:red "$test_image" 2>/dev/null; then
            if copy_to_clipboard "$test_image"; then
                echo "✓ Image copy test passed"
                
                # Test image detection
                if clipboard_has_image; then
                    echo "✓ Image detection test passed"
                else
                    echo "⚠ Image detection test failed"
                fi
            else
                echo "✗ Image copy test failed"
                return 1
            fi
        else
            echo "⚠ Could not create test image, skipping image tests"
        fi
    else
        echo "⚠ ImageMagick not available, skipping image tests"
    fi
    
    # Clean up by clearing clipboard
    clear_clipboard
    
    echo "✓ Clipboard functionality tests completed"
    return 0
}

# Get clipboard statistics
get_clipboard_stats() {
    echo "=== Clipboard Status ==="
    
    if [[ "${TOOL_CAPABILITIES[wl_paste_available]:-false}" == "true" ]]; then
        # Check available MIME types
        local mime_types
        mime_types=$(wl-paste --list-types 2>/dev/null || echo "")
        
        if [[ -n "$mime_types" ]]; then
            echo "Available clipboard types:"
            echo "$mime_types" | sed 's/^/  /'
            
            # Check for specific content types
            if echo "$mime_types" | grep -q "image/"; then
                echo "Status: Contains image data"
            elif echo "$mime_types" | grep -q "text/"; then
                echo "Status: Contains text data"
            else
                echo "Status: Contains data (type unknown)"
            fi
        else
            echo "Status: Clipboard is empty"
        fi
    else
        echo "Status: Cannot check clipboard (wl-paste not available)"
    fi
    
    echo ""
    echo "Clipboard capabilities:"
    echo "  wl-copy:  ${TOOL_CAPABILITIES[wl_copy_available]:-false}"
    echo "  wl-paste: ${TOOL_CAPABILITIES[wl_paste_available]:-false}"
    echo "  Type specification: ${TOOL_CAPABILITIES[wl_copy_type]:-false}"
}

# Monitor clipboard changes (if supported)
monitor_clipboard() {
    if [[ "${TOOL_CAPABILITIES[wl_paste_available]:-false}" != "true" ]]; then
        echo "Error: Clipboard monitoring requires wl-paste" >&2
        return 1
    fi
    
    echo "Monitoring clipboard changes (Ctrl+C to stop)..."
    
    local last_hash=""
    
    while true; do
        # Get current clipboard hash
        local current_hash
        current_hash=$(wl-paste --list-types 2>/dev/null | md5sum | cut -d' ' -f1 2>/dev/null || echo "")
        
        if [[ "$current_hash" != "$last_hash" ]]; then
            echo "Clipboard changed at $(date '+%H:%M:%S')"
            
            # Show available types
            local mime_types
            mime_types=$(wl-paste --list-types 2>/dev/null || echo "")
            if [[ -n "$mime_types" ]]; then
                echo "  Types: $(echo "$mime_types" | tr '\n' ', ' | sed 's/,$//')"
            fi
            
            last_hash="$current_hash"
        fi
        
        sleep 1
    done
}

# Advanced clipboard operations
save_clipboard_history() {
    local history_file="$DATA_DIR/clipboard-history.txt"
    
    if [[ "${TOOL_CAPABILITIES[wl_paste_available]:-false}" != "true" ]]; then
        echo "Error: Clipboard history requires wl-paste" >&2
        return 1
    fi
    
    # Create history directory
    mkdir -p "$(dirname "$history_file")"
    
    # Save current clipboard text (if any)
    local clipboard_text
    clipboard_text=$(get_clipboard_contents)
    
    if [[ -n "$clipboard_text" ]]; then
        local timestamp
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        echo "[$timestamp] $clipboard_text" >> "$history_file"
        echo "✓ Clipboard content saved to history"
    else
        echo "No text content in clipboard to save"
    fi
}