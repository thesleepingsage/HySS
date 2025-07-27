#!/usr/bin/env bash
#
# Configuration Migration System
# Handles updates and migrations between tool versions
#

# Enable strict error handling
set -euo pipefail

# Migration metadata file
MIGRATION_DATA_FILE="$DATA_DIR/migration-metadata.json"

# Initialize migration system
init_migration_system() {
    mkdir -p "$DATA_DIR"
    
    # Create migration metadata if it doesn't exist
    if [[ ! -f "$MIGRATION_DATA_FILE" ]]; then
        create_initial_migration_metadata
    fi
}

# Create initial migration metadata
create_initial_migration_metadata() {
    local current_timestamp
    current_timestamp=$(date +%s)
    
    if command -v jq >/dev/null 2>&1; then
        # Use jq for proper JSON formatting
        jq -n \
            --arg timestamp "$current_timestamp" \
            --arg schema_version "1.0" \
            '{
                schema_version: $schema_version,
                created: $timestamp,
                last_check: $timestamp,
                tool_versions: {},
                migration_history: []
            }' > "$MIGRATION_DATA_FILE"
    else
        # Fallback: create simple JSON manually
        cat > "$MIGRATION_DATA_FILE" << EOF
{
    "schema_version": "1.0",
    "created": "$current_timestamp",
    "last_check": "$current_timestamp",
    "tool_versions": {},
    "migration_history": []
}
EOF
    fi
}

# Check for tool version changes
check_for_version_changes() {
    echo "🔍 Checking for tool version changes..."
    
    local changes_detected=false
    local migration_needed=false
    
    # Load current stored versions
    local stored_versions
    if command -v jq >/dev/null 2>&1 && [[ -f "$MIGRATION_DATA_FILE" ]]; then
        stored_versions=$(jq -r '.tool_versions' "$MIGRATION_DATA_FILE" 2>/dev/null || echo "{}")
    else
        stored_versions="{}"
    fi
    
    # Check each tool for version changes
    for tool in "${!TOOL_VERSIONS[@]}"; do
        local current_version="${TOOL_VERSIONS[$tool]}"
        local stored_version
        
        if command -v jq >/dev/null 2>&1; then
            stored_version=$(echo "$stored_versions" | jq -r --arg tool "$tool" '.[$tool] // ""' 2>/dev/null || echo "")
        else
            stored_version=""
        fi
        
        if [[ "$current_version" != "$stored_version" ]]; then
            echo "📦 $tool: $stored_version → $current_version"
            changes_detected=true
            
            # Check if this change requires migration
            if requires_migration "$tool" "$stored_version" "$current_version"; then
                echo "⚠️  Migration needed for $tool"
                migration_needed=true
            fi
        fi
    done
    
    if [[ "$changes_detected" == "false" ]]; then
        echo "✓ No tool version changes detected"
        return 0
    fi
    
    # Update stored versions
    update_stored_versions
    
    if [[ "$migration_needed" == "true" ]]; then
        echo "🔄 Running migrations..."
        run_migrations
        return $?
    else
        echo "✓ Tool versions updated, no migrations needed"
        return 0
    fi
}

# Check if a tool version change requires migration
requires_migration() {
    local tool="$1"
    local old_version="$2"
    local new_version="$3"
    
    # If this is the first time we see this tool, no migration needed
    if [[ -z "$old_version" ]]; then
        return 1
    fi
    
    case "$tool" in
        satty)
            requires_satty_migration "$old_version" "$new_version"
            ;;
        swappy)
            requires_swappy_migration "$old_version" "$new_version"
            ;;
        grim)
            requires_grim_migration "$old_version" "$new_version"
            ;;
        slurp)
            requires_slurp_migration "$old_version" "$new_version"
            ;;
        *)
            # Unknown tool, assume no migration needed
            return 1
            ;;
    esac
}

# Check if Satty migration is needed
requires_satty_migration() {
    local old_version="$1"
    local new_version="$2"
    
    # Define version ranges that require migration
    case "$old_version -> $new_version" in
        "1.0."*" -> 1.1."*|"1.0."*" -> 1.2."*|"1.0."*" -> 1.3."*)
            # Config format changed between 1.0 and 1.1+
            return 0
            ;;
        "1.1."*" -> 1.2."*|"1.1."*" -> 1.3."*)
            # New features added that might affect config
            return 0
            ;;
        *)
            # No migration needed for other version changes
            return 1
            ;;
    esac
}

# Check if other tools need migration
requires_swappy_migration() {
    # Swappy config is generated dynamically, so rarely needs migration
    return 1
}

requires_grim_migration() {
    # Grim is command-line only, no config migration needed
    return 1
}

requires_slurp_migration() {
    # Slurp is command-line only, no config migration needed
    return 1
}

# Run all necessary migrations
run_migrations() {
    local migration_success=true
    
    # Get current stored versions for migration comparison
    local stored_versions
    if command -v jq >/dev/null 2>&1 && [[ -f "$MIGRATION_DATA_FILE" ]]; then
        stored_versions=$(jq -r '.tool_versions' "$MIGRATION_DATA_FILE" 2>/dev/null || echo "{}")
    else
        stored_versions="{}"
    fi
    
    # Run migrations for each tool that needs it
    for tool in "${!TOOL_VERSIONS[@]}"; do
        local current_version="${TOOL_VERSIONS[$tool]}"
        local stored_version
        
        if command -v jq >/dev/null 2>&1; then
            stored_version=$(echo "$stored_versions" | jq -r --arg tool "$tool" '.[$tool] // ""' 2>/dev/null || echo "")
        else
            stored_version=""
        fi
        
        if requires_migration "$tool" "$stored_version" "$current_version"; then
            echo "🔄 Migrating $tool configuration..."
            
            if migrate_tool_config "$tool" "$stored_version" "$current_version"; then
                record_migration_success "$tool" "$stored_version" "$current_version"
                echo "✓ $tool migration completed successfully"
            else
                record_migration_failure "$tool" "$stored_version" "$current_version"
                echo "✗ $tool migration failed"
                migration_success=false
            fi
        fi
    done
    
    if [[ "$migration_success" == "true" ]]; then
        echo "✓ All migrations completed successfully"
        return 0
    else
        echo "⚠️ Some migrations failed, but the tool should still work"
        return 1
    fi
}

# Migrate configuration for a specific tool
migrate_tool_config() {
    local tool="$1"
    local old_version="$2"
    local new_version="$3"
    
    case "$tool" in
        satty)
            migrate_satty_config "$old_version" "$new_version"
            ;;
        swappy)
            migrate_swappy_config "$old_version" "$new_version"
            ;;
        *)
            echo "No migration handler for $tool"
            return 1
            ;;
    esac
}

# Migrate Satty configuration
migrate_satty_config() {
    local old_version="$1"
    local new_version="$2"
    local config_file="$CONFIG_DIR/satty/config.toml"
    
    # Backup existing config
    if [[ -f "$config_file" ]]; then
        local backup_file="$config_file.backup.$(date +%s)"
        cp "$config_file" "$backup_file"
        echo "📋 Backed up satty config to $backup_file"
    fi
    
    # Apply specific migrations based on version changes
    case "$old_version -> $new_version" in
        "1.0."*" -> 1.1."*)
            migrate_satty_1_0_to_1_1 "$config_file"
            ;;
        "1.0."*" -> 1.2."*|"1.1."*" -> 1.2."*)
            migrate_satty_to_1_2 "$config_file"
            ;;
        *)
            # General migration: regenerate config for new version
            echo "Regenerating satty config for version $new_version"
            generate_satty_config "$new_version" "$config_file"
            ;;
    esac
}

# Specific Satty migration functions
migrate_satty_1_0_to_1_1() {
    local config_file="$1"
    
    if [[ -f "$config_file" ]]; then
        # Version 1.1 added early-exit option
        if ! grep -q "early-exit" "$config_file"; then
            sed -i '/\[general\]/a early-exit = true' "$config_file"
        fi
        
        # Version 1.1 changed some option names
        sed -i 's/save_on_copy/save-after-copy/g' "$config_file"
    else
        # Generate new config
        generate_satty_config "1.1" "$config_file"
    fi
}

migrate_satty_to_1_2() {
    local config_file="$1"
    
    if [[ -f "$config_file" ]]; then
        # Version 1.2+ added more color palette options
        if ! grep -q "color-palette" "$config_file"; then
            cat >> "$config_file" << 'EOF'

# Custom colours for the colour palette
[color-palette]
palette = [
    "#dc143c",
    "#00bfff",
    "#32cd32",
    "#ffd700",
    "#ff69b4",
]
EOF
        fi
        
        # Update any deprecated options
        sed -i 's/highlight_style/primary-highlighter/g' "$config_file"
    else
        # Generate new config
        generate_satty_config "1.2" "$config_file"
    fi
}

# Migrate Swappy configuration (rarely needed)
migrate_swappy_config() {
    local old_version="$1"
    local new_version="$2"
    
    # Swappy config is generated dynamically per session
    # Usually no migration needed
    echo "Swappy config is generated dynamically, no migration needed"
    return 0
}

# Update stored tool versions
update_stored_versions() {
    local current_timestamp
    current_timestamp=$(date +%s)
    
    if command -v jq >/dev/null 2>&1; then
        # Build new versions object
        local versions_json="{}"
        for tool in "${!TOOL_VERSIONS[@]}"; do
            versions_json=$(echo "$versions_json" | jq --arg tool "$tool" --arg version "${TOOL_VERSIONS[$tool]}" '.[$tool] = $version')
        done
        
        # Update migration metadata file
        local temp_file
        temp_file=$(mktemp)
        
        jq --arg timestamp "$current_timestamp" --argjson versions "$versions_json" \
           '.last_check = $timestamp | .tool_versions = $versions' \
           "$MIGRATION_DATA_FILE" > "$temp_file" && mv "$temp_file" "$MIGRATION_DATA_FILE"
    else
        echo "Warning: Cannot update stored versions without jq" >&2
    fi
}

# Record successful migration
record_migration_success() {
    local tool="$1"
    local old_version="$2"
    local new_version="$3"
    local timestamp
    timestamp=$(date +%s)
    
    if command -v jq >/dev/null 2>&1; then
        local temp_file
        temp_file=$(mktemp)
        
        jq --arg tool "$tool" \
           --arg old_version "$old_version" \
           --arg new_version "$new_version" \
           --arg timestamp "$timestamp" \
           --arg status "success" \
           '.migration_history += [{
               tool: $tool,
               old_version: $old_version,
               new_version: $new_version,
               timestamp: $timestamp,
               status: $status
           }]' \
           "$MIGRATION_DATA_FILE" > "$temp_file" && mv "$temp_file" "$MIGRATION_DATA_FILE"
    fi
}

# Record failed migration
record_migration_failure() {
    local tool="$1"
    local old_version="$2"
    local new_version="$3"
    local timestamp
    timestamp=$(date +%s)
    
    if command -v jq >/dev/null 2>&1; then
        local temp_file
        temp_file=$(mktemp)
        
        jq --arg tool "$tool" \
           --arg old_version "$old_version" \
           --arg new_version "$new_version" \
           --arg timestamp "$timestamp" \
           --arg status "failed" \
           '.migration_history += [{
               tool: $tool,
               old_version: $old_version,
               new_version: $new_version,
               timestamp: $timestamp,
               status: $status
           }]' \
           "$MIGRATION_DATA_FILE" > "$temp_file" && mv "$temp_file" "$MIGRATION_DATA_FILE"
    fi
}

# Show migration history
show_migration_history() {
    echo "=== Migration History ==="
    
    if [[ ! -f "$MIGRATION_DATA_FILE" ]]; then
        echo "No migration history available"
        return 0
    fi
    
    if command -v jq >/dev/null 2>&1; then
        # Format migration history nicely
        local history
        history=$(jq -r '.migration_history[]? | "\(.timestamp) \(.tool) \(.old_version) → \(.new_version) [\(.status)]"' "$MIGRATION_DATA_FILE" 2>/dev/null || echo "")
        
        if [[ -n "$history" ]]; then
            echo "$history" | while read -r timestamp tool old_version arrow new_version status; do
                local formatted_date
                formatted_date=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$timestamp")
                
                case "$status" in
                    "[success]")
                        echo "✓ $formatted_date $tool $old_version $arrow $new_version"
                        ;;
                    "[failed]")
                        echo "✗ $formatted_date $tool $old_version $arrow $new_version"
                        ;;
                    *)
                        echo "? $formatted_date $tool $old_version $arrow $new_version $status"
                        ;;
                esac
            done
        else
            echo "No migrations have been performed yet"
        fi
    else
        echo "Migration history requires jq to display properly"
    fi
}

# Force regenerate all configurations
force_regenerate_configs() {
    echo "🔄 Force regenerating all tool configurations..."
    
    # Backup existing configs
    local backup_dir="$CONFIG_DIR/backup-$(date +%s)"
    mkdir -p "$backup_dir"
    
    if [[ -d "$CONFIG_DIR/satty" ]]; then
        cp -r "$CONFIG_DIR/satty" "$backup_dir/" 2>/dev/null || true
    fi
    
    if [[ -d "$CONFIG_DIR/swappy" ]]; then
        cp -r "$CONFIG_DIR/swappy" "$backup_dir/" 2>/dev/null || true
    fi
    
    echo "📋 Configs backed up to $backup_dir"
    
    # Regenerate Satty config
    if [[ "${TOOL_CAPABILITIES[satty_available]:-false}" == "true" ]]; then
        local satty_version="${TOOL_VERSIONS[satty]:-unknown}"
        local satty_config="$CONFIG_DIR/satty/config.toml"
        
        mkdir -p "$(dirname "$satty_config")"
        generate_satty_config "$satty_version" "$satty_config"
        echo "✓ Satty configuration regenerated"
    fi
    
    # Swappy config is generated dynamically, so no action needed
    
    echo "✓ Configuration regeneration completed"
}

# Clean old migration data
clean_migration_data() {
    echo "🧹 Cleaning old migration data..."
    
    if [[ -f "$MIGRATION_DATA_FILE" ]] && command -v jq >/dev/null 2>&1; then
        # Keep only last 50 migration entries
        local temp_file
        temp_file=$(mktemp)
        
        jq '.migration_history |= (sort_by(.timestamp) | .[-50:])' \
           "$MIGRATION_DATA_FILE" > "$temp_file" && mv "$temp_file" "$MIGRATION_DATA_FILE"
        
        echo "✓ Migration history cleaned (kept last 50 entries)"
    fi
    
    # Clean old backup configs (older than 30 days)
    find "$CONFIG_DIR" -name "*.backup.*" -mtime +30 -delete 2>/dev/null || true
    echo "✓ Old backup configurations cleaned"
}

# Export migration data
export_migration_data() {
    local output_file="$1"
    
    if [[ -z "$output_file" ]]; then
        output_file="$HOME/screenshot-tool-migration-export-$(date +%Y%m%d_%H%M%S).json"
    fi
    
    if [[ -f "$MIGRATION_DATA_FILE" ]]; then
        cp "$MIGRATION_DATA_FILE" "$output_file"
        echo "✓ Migration data exported to $output_file"
    else
        echo "No migration data to export"
        return 1
    fi
}