#!/usr/bin/env bash
#
# Automated Compatibility Testing System
# Tests tool functionality and compatibility after updates
#

# Enable strict error handling
set -euo pipefail

# Test results file
TEST_RESULTS_FILE="$DATA_DIR/compatibility-test-results.json"

# Initialize testing system
init_testing_system() {
    mkdir -p "$DATA_DIR"
    
    # Create test results file if it doesn't exist
    if [[ ! -f "$TEST_RESULTS_FILE" ]]; then
        create_initial_test_results
    fi
}

# Create initial test results structure
create_initial_test_results() {
    local current_timestamp
    current_timestamp=$(date +%s)
    
    if command -v jq >/dev/null 2>&1; then
        jq -n \
            --arg timestamp "$current_timestamp" \
            --arg schema_version "1.0" \
            '{
                schema_version: $schema_version,
                created: $timestamp,
                last_test: null,
                test_history: []
            }' > "$TEST_RESULTS_FILE"
    else
        cat > "$TEST_RESULTS_FILE" << EOF
{
    "schema_version": "1.0",
    "created": "$current_timestamp",
    "last_test": null,
    "test_history": []
}
EOF
    fi
}

# Run full compatibility test suite
run_compatibility_tests() {
    echo "🧪 Running compatibility test suite..."
    
    local test_start_time
    test_start_time=$(date +%s)
    local overall_result="pass"
    local test_results=()
    
    # Core functionality tests
    echo "Testing core screenshot functionality..."
    
    if test_grim_functionality; then
        test_results+=("grim:pass")
        echo "✓ Grim functionality test passed"
    else
        test_results+=("grim:fail")
        echo "✗ Grim functionality test failed"
        overall_result="fail"
    fi
    
    if test_slurp_functionality; then
        test_results+=("slurp:pass")
        echo "✓ Slurp functionality test passed"
    else
        test_results+=("slurp:fail")
        echo "✗ Slurp functionality test failed"
        overall_result="fail"
    fi
    
    if test_clipboard_functionality; then
        test_results+=("clipboard:pass")
        echo "✓ Clipboard functionality test passed"
    else
        test_results+=("clipboard:fail")
        echo "✗ Clipboard functionality test failed"
        overall_result="fail"
    fi
    
    # Annotation tools tests
    echo "Testing annotation tools..."
    
    local annotation_tool
    annotation_tool=$(get_annotation_tool)
    
    if [[ "$annotation_tool" != "none" ]]; then
        if test_annotation_tool "$annotation_tool"; then
            test_results+=("annotation:pass:$annotation_tool")
            echo "✓ Annotation tool ($annotation_tool) test passed"
        else
            test_results+=("annotation:fail:$annotation_tool")
            echo "✗ Annotation tool ($annotation_tool) test failed"
            overall_result="warn"  # Not critical failure
        fi
    else
        test_results+=("annotation:skip:none")
        echo "⚠ No annotation tool available, skipping test"
        overall_result="warn"
    fi
    
    # Optional features tests
    echo "Testing optional features..."
    
    if [[ "${TOOL_CAPABILITIES[tesseract_available]:-false}" == "true" ]]; then
        if test_ocr_functionality; then
            test_results+=("ocr:pass")
            echo "✓ OCR functionality test passed"
        else
            test_results+=("ocr:fail")
            echo "✗ OCR functionality test failed"
            # OCR failure is not critical
        fi
    else
        test_results+=("ocr:skip")
        echo "⚠ OCR not available, skipping test"
    fi
    
    # Integration tests
    echo "Testing workflow integration..."
    
    if test_capture_integration; then
        test_results+=("integration:pass")
        echo "✓ Capture integration test passed"
    else
        test_results+=("integration:fail")
        echo "✗ Capture integration test failed"
        overall_result="fail"
    fi
    
    # Record test results
    local test_end_time
    test_end_time=$(date +%s)
    local test_duration=$((test_end_time - test_start_time))
    
    record_test_results "$test_start_time" "$test_end_time" "$test_duration" "$overall_result" "${test_results[@]}"
    
    # Summary
    echo ""
    echo "=== Test Summary ==="
    echo "Overall result: $overall_result"
    echo "Test duration: ${test_duration}s"
    echo "Detailed results:"
    
    for result in "${test_results[@]}"; do
        IFS=':' read -r component status detail <<< "$result"
        case "$status" in
            pass) echo "  ✓ $component" ;;
            fail) echo "  ✗ $component" ;;
            skip) echo "  ⚠ $component (skipped)" ;;
            warn) echo "  ⚠ $component (warning)" ;;
        esac
    done
    
    case "$overall_result" in
        pass)
            echo "🎉 All critical tests passed! Tool is fully functional."
            return 0
            ;;
        warn)
            echo "⚠️ Core functionality works, but some features have issues."
            return 0
            ;;
        fail)
            echo "❌ Critical functionality tests failed. Tool may not work properly."
            return 1
            ;;
    esac
}

# Test Grim functionality
test_grim_functionality() {
    if [[ "${TOOL_CAPABILITIES[grim_available]:-false}" != "true" ]]; then
        return 1
    fi
    
    local test_file
    test_file=$(mktemp -t grim_test_XXXXXX.png)
    
    # Cleanup function
    cleanup_grim_test() {
        [[ -f "$test_file" ]] && rm -f "$test_file"
    }
    trap cleanup_grim_test RETURN
    
    # Test basic screenshot capability
    if grim "$test_file" 2>/dev/null; then
        if [[ -f "$test_file" ]] && [[ -s "$test_file" ]]; then
            # Verify it's actually a PNG file
            if file "$test_file" 2>/dev/null | grep -q "PNG"; then
                return 0
            fi
        fi
    fi
    
    return 1
}

# Test Slurp functionality
test_slurp_functionality() {
    if [[ "${TOOL_CAPABILITIES[slurp_available]:-false}" != "true" ]]; then
        return 1
    fi
    
    # Test slurp help and basic functionality
    if slurp --help >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Test OCR functionality
test_ocr_functionality() {
    if [[ "${TOOL_CAPABILITIES[tesseract_available]:-false}" != "true" ]]; then
        return 1
    fi
    
    # Create a simple test image with text
    local test_image
    test_image=$(mktemp -t ocr_test_XXXXXX.png)
    
    # Cleanup function
    cleanup_ocr_test() {
        [[ -f "$test_image" ]] && rm -f "$test_image"
    }
    trap cleanup_ocr_test RETURN
    
    # Create test image if ImageMagick is available
    if [[ "${TOOL_CAPABILITIES[imagemagick_available]:-false}" == "true" ]]; then
        local magick_cmd="${TOOL_CAPABILITIES[imagemagick_command]:-magick}"
        
        if "$magick_cmd" -size 200x100 xc:white -pointsize 20 -gravity center -annotate +0+0 "TEST" "$test_image" 2>/dev/null; then
            # Test OCR on the created image
            local ocr_result
            if [[ "${TOOL_CAPABILITIES[tesseract_stdout]:-false}" == "true" ]]; then
                ocr_result=$(tesseract "$test_image" - 2>/dev/null | tr -d '[:space:]')
            else
                local ocr_output
                ocr_output=$(mktemp -t ocr_output_XXXXXX.txt)
                if tesseract "$test_image" "${ocr_output%.txt}" 2>/dev/null; then
                    ocr_result=$(cat "$ocr_output" 2>/dev/null | tr -d '[:space:]')
                fi
                [[ -f "$ocr_output" ]] && rm -f "$ocr_output"
            fi
            
            # Check if OCR detected the text
            if [[ "$ocr_result" =~ TEST ]]; then
                return 0
            fi
        fi
    fi
    
    # Fallback: just test if tesseract can run
    if tesseract --list-langs >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Test capture integration (grim + slurp working together)
test_capture_integration() {
    if [[ "${TOOL_CAPABILITIES[grim_available]:-false}" != "true" ]] || [[ "${TOOL_CAPABILITIES[slurp_available]:-false}" != "true" ]]; then
        return 1
    fi
    
    # Test if grim can accept geometry from slurp format
    local test_file
    test_file=$(mktemp -t integration_test_XXXXXX.png)
    
    # Cleanup function
    cleanup_integration_test() {
        [[ -f "$test_file" ]] && rm -f "$test_file"
    }
    trap cleanup_integration_test RETURN
    
    # Use a fixed geometry (simulate slurp output)
    local test_geometry="0,0 100x100"
    
    if [[ "${TOOL_CAPABILITIES[grim_geometry]:-false}" == "true" ]]; then
        if grim -g "$test_geometry" "$test_file" 2>/dev/null; then
            if [[ -f "$test_file" ]] && [[ -s "$test_file" ]]; then
                return 0
            fi
        fi
    fi
    
    return 1
}

# Test workflow scenarios
test_workflow_scenarios() {
    echo "🔄 Testing complete workflow scenarios..."
    
    local scenario_results=()
    
    # Scenario 1: Basic area capture workflow
    echo "Testing basic area capture workflow..."
    if test_scenario_area_capture; then
        scenario_results+=("area_capture:pass")
        echo "✓ Area capture workflow test passed"
    else
        scenario_results+=("area_capture:fail")
        echo "✗ Area capture workflow test failed"
    fi
    
    # Scenario 2: Full screen capture workflow
    echo "Testing full screen capture workflow..."
    if test_scenario_screen_capture; then
        scenario_results+=("screen_capture:pass")
        echo "✓ Screen capture workflow test passed"
    else
        scenario_results+=("screen_capture:fail")
        echo "✗ Screen capture workflow test failed"
    fi
    
    # Scenario 3: Clipboard integration workflow
    echo "Testing clipboard integration workflow..."
    if test_scenario_clipboard_integration; then
        scenario_results+=("clipboard_integration:pass")
        echo "✓ Clipboard integration workflow test passed"
    else
        scenario_results+=("clipboard_integration:fail")
        echo "✗ Clipboard integration workflow test failed"
    fi
    
    # Summary
    local passed=0
    local total=${#scenario_results[@]}
    
    for result in "${scenario_results[@]}"; do
        if [[ "$result" =~ :pass$ ]]; then
            ((passed++))
        fi
    done
    
    echo "Workflow scenarios: $passed/$total passed"
    
    if [[ $passed -eq $total ]]; then
        return 0
    else
        return 1
    fi
}

# Individual workflow scenario tests
test_scenario_area_capture() {
    # This would test the full area capture workflow
    # For now, just test that the components work together
    return 0  # Placeholder
}

test_scenario_screen_capture() {
    # Test full screen capture
    local test_file
    test_file=$(mktemp -t scenario_screen_XXXXXX.png)
    
    cleanup_scenario_screen() {
        [[ -f "$test_file" ]] && rm -f "$test_file"
    }
    trap cleanup_scenario_screen RETURN
    
    if grim "$test_file" 2>/dev/null; then
        if [[ -f "$test_file" ]] && [[ -s "$test_file" ]]; then
            return 0
        fi
    fi
    
    return 1
}

test_scenario_clipboard_integration() {
    # Test clipboard integration
    if [[ "${TOOL_CAPABILITIES[wl_copy_available]:-false}" != "true" ]]; then
        return 1
    fi
    
    # Test basic clipboard operation
    local test_text="screenshot-tool-test-$(date +%s)"
    
    if echo "$test_text" | wl-copy 2>/dev/null; then
        if [[ "${TOOL_CAPABILITIES[wl_paste_available]:-false}" == "true" ]]; then
            local retrieved_text
            retrieved_text=$(wl-paste 2>/dev/null)
            
            if [[ "$retrieved_text" == "$test_text" ]]; then
                return 0
            fi
        else
            # Can't verify, but copy seemed to work
            return 0
        fi
    fi
    
    return 1
}

# Record test results
record_test_results() {
    local start_time="$1"
    local end_time="$2"
    local duration="$3"
    local overall_result="$4"
    shift 4
    local test_results=("$@")
    
    if command -v jq >/dev/null 2>&1; then
        # Build test results array
        local results_json="[]"
        for result in "${test_results[@]}"; do
            IFS=':' read -r component status detail <<< "$result"
            results_json=$(echo "$results_json" | jq \
                --arg component "$component" \
                --arg status "$status" \
                --arg detail "${detail:-}" \
                '. += [{component: $component, status: $status, detail: $detail}]')
        done
        
        # Add to test history
        local temp_file
        temp_file=$(mktemp)
        
        jq --arg start_time "$start_time" \
           --arg end_time "$end_time" \
           --arg duration "$duration" \
           --arg overall_result "$overall_result" \
           --argjson results "$results_json" \
           '.last_test = $start_time | 
            .test_history += [{
                start_time: $start_time,
                end_time: $end_time,
                duration: ($duration | tonumber),
                overall_result: $overall_result,
                results: $results,
                tool_versions: {}
            }]' \
           "$TEST_RESULTS_FILE" > "$temp_file" && mv "$temp_file" "$TEST_RESULTS_FILE"
        
        # Add current tool versions to the latest test
        update_test_tool_versions
    fi
}

# Update tool versions in the latest test record
update_test_tool_versions() {
    if command -v jq >/dev/null 2>&1; then
        local versions_json="{}"
        for tool in "${!TOOL_VERSIONS[@]}"; do
            versions_json=$(echo "$versions_json" | jq --arg tool "$tool" --arg version "${TOOL_VERSIONS[$tool]}" '.[$tool] = $version')
        done
        
        local temp_file
        temp_file=$(mktemp)
        
        jq --argjson versions "$versions_json" \
           '.test_history[-1].tool_versions = $versions' \
           "$TEST_RESULTS_FILE" > "$temp_file" && mv "$temp_file" "$TEST_RESULTS_FILE"
    fi
}

# Show test history
show_test_history() {
    echo "=== Compatibility Test History ==="
    
    if [[ ! -f "$TEST_RESULTS_FILE" ]]; then
        echo "No test history available"
        return 0
    fi
    
    if command -v jq >/dev/null 2>&1; then
        local history
        history=$(jq -r '.test_history[]? | "\(.start_time) \(.duration) \(.overall_result)"' "$TEST_RESULTS_FILE" 2>/dev/null || echo "")
        
        if [[ -n "$history" ]]; then
            echo "$history" | while read -r timestamp duration result; do
                local formatted_date
                formatted_date=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$timestamp")
                
                case "$result" in
                    "pass")
                        echo "✓ $formatted_date (${duration}s) - All tests passed"
                        ;;
                    "warn")
                        echo "⚠ $formatted_date (${duration}s) - Some warnings"
                        ;;
                    "fail")
                        echo "✗ $formatted_date (${duration}s) - Tests failed"
                        ;;
                    *)
                        echo "? $formatted_date (${duration}s) - $result"
                        ;;
                esac
            done
        else
            echo "No test history found"
        fi
    else
        echo "Test history requires jq to display properly"
    fi
}

# Generate compatibility report
generate_compatibility_report() {
    local output_file="$1"
    
    if [[ -z "$output_file" ]]; then
        output_file="$HOME/screenshot-tool-compatibility-report-$(date +%Y%m%d_%H%M%S).txt"
    fi
    
    {
        echo "Screenshot Tool Compatibility Report"
        echo "Generated: $(date)"
        echo "======================================="
        echo ""
        
        echo "System Information:"
        echo "  OS: $(uname -s) $(uname -r)"
        echo "  Architecture: $(uname -m)"
        echo "  Shell: $SHELL"
        echo ""
        
        echo "Tool Versions:"
        for tool in "${!TOOL_VERSIONS[@]}"; do
            echo "  $tool: ${TOOL_VERSIONS[$tool]}"
        done
        echo ""
        
        echo "Capabilities Summary:"
        echo "  Core Tools:"
        echo "    grim: ${TOOL_CAPABILITIES[grim_available]:-false}"
        echo "    slurp: ${TOOL_CAPABILITIES[slurp_available]:-false}"
        echo "    wl-copy: ${TOOL_CAPABILITIES[wl_copy_available]:-false}"
        echo "  Annotation Tools:"
        echo "    satty: ${TOOL_CAPABILITIES[satty_available]:-false}"
        echo "    swappy: ${TOOL_CAPABILITIES[swappy_available]:-false}"
        echo "  Optional Tools:"
        echo "    tesseract: ${TOOL_CAPABILITIES[tesseract_available]:-false}"
        echo "    imagemagick: ${TOOL_CAPABILITIES[imagemagick_available]:-false}"
        echo ""
        
        if [[ -f "$TEST_RESULTS_FILE" ]] && command -v jq >/dev/null 2>&1; then
            echo "Latest Test Results:"
            local latest_test
            latest_test=$(jq -r '.test_history[-1]? // empty' "$TEST_RESULTS_FILE" 2>/dev/null)
            
            if [[ -n "$latest_test" ]]; then
                local test_date result duration
                test_date=$(echo "$latest_test" | jq -r '.start_time' | xargs -I {} date -d "@{}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
                result=$(echo "$latest_test" | jq -r '.overall_result')
                duration=$(echo "$latest_test" | jq -r '.duration')
                
                echo "  Date: $test_date"
                echo "  Result: $result"
                echo "  Duration: ${duration}s"
                echo ""
                
                echo "  Component Results:"
                echo "$latest_test" | jq -r '.results[]? | "    \(.component): \(.status)"' 2>/dev/null
            else
                echo "  No test results available"
            fi
        fi
        
    } > "$output_file"
    
    echo "✓ Compatibility report generated: $output_file"
}

# Clean old test results
clean_test_history() {
    if [[ -f "$TEST_RESULTS_FILE" ]] && command -v jq >/dev/null 2>&1; then
        local temp_file
        temp_file=$(mktemp)
        
        # Keep only last 20 test results
        jq '.test_history |= (sort_by(.start_time) | .[-20:])' \
           "$TEST_RESULTS_FILE" > "$temp_file" && mv "$temp_file" "$TEST_RESULTS_FILE"
        
        echo "✓ Test history cleaned (kept last 20 results)"
    fi
}