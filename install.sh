#!/usr/bin/env bash
#
# HyprScreenShot Installation Script
# Provides plug-and-play installation for both system-wide and user-local setups
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation settings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_INSTALL=false
FORCE_INSTALL=false
CHECK_ONLY=false
IGNORE_DEPS=false

# Print colored output
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1" >&2; }

# Usage information
usage() {
    cat << 'EOF'
HyprScreenShot Installation Script

Usage: ./install.sh [OPTIONS]

OPTIONS:
    --user          Install for current user only (~/.local/bin)
    --force         Force installation (overwrite existing files)
    --check-only    Check dependencies without installing
    --ignore-deps   Skip dependency check (advanced users)
    --help, -h      Show this help message

EXAMPLES:
    sudo ./install.sh              # System-wide installation
    ./install.sh --user            # User-local installation  
    ./install.sh --check-only      # Check dependencies only
    ./install.sh --user --force    # Force user installation

NOTES:
    - System-wide installation requires sudo privileges
    - User installation may require adding ~/.local/bin to PATH
    - Use --force to overwrite existing installations
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user)
                USER_INSTALL=true
                shift
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --check-only)
                CHECK_ONLY=true
                shift
                ;;
            --ignore-deps)
                IGNORE_DEPS=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Check if running as root when needed
check_privileges() {
    if [[ "$USER_INSTALL" == "false" ]] && [[ $EUID -ne 0 ]]; then
        print_error "System-wide installation requires root privileges"
        print_info "Please run: sudo ./install.sh"
        print_info "Or use user installation: ./install.sh --user"
        exit 1
    fi
    
    if [[ "$USER_INSTALL" == "true" ]] && [[ $EUID -eq 0 ]]; then
        print_warning "Running user installation as root is not recommended"
        print_info "Consider running without sudo for user installation"
    fi
}

# Set installation paths
set_install_paths() {
    if [[ "$USER_INSTALL" == "true" ]]; then
        BIN_DIR="$HOME/.local/bin"
        LIB_DIR="$HOME/.local/share/hyss/lib"
        INSTALL_TYPE="user-local"
    else
        BIN_DIR="/usr/local/bin"
        LIB_DIR="/usr/local/share/hyss/lib"
        INSTALL_TYPE="system-wide"
    fi
}

# Check if files exist and handle force option
check_existing_installation() {
    local existing_files=()
    local conflicting_installs=()
    
    # Check for same-scope installation
    if [[ -f "$BIN_DIR/hyss" ]]; then
        existing_files+=("$BIN_DIR/hyss")
    fi
    
    if [[ -d "$LIB_DIR" ]]; then
        existing_files+=("$LIB_DIR")
    fi
    
    # Check for cross-scope conflicts
    if [[ "$USER_INSTALL" == "true" ]]; then
        # Installing user-local, check for system-wide
        [[ -f "/usr/local/bin/hyss" ]] && conflicting_installs+=("/usr/local/bin/hyss")
        [[ -f "/usr/bin/hyss" ]] && conflicting_installs+=("/usr/bin/hyss")
        [[ -d "/usr/local/share/hyss" ]] && conflicting_installs+=("/usr/local/share/hyss")
        [[ -d "/usr/share/hyss" ]] && conflicting_installs+=("/usr/share/hyss")
    else
        # Installing system-wide, check for user-local
        [[ -f "$HOME/.local/bin/hyss" ]] && conflicting_installs+=("$HOME/.local/bin/hyss")
        [[ -d "$HOME/.local/share/hyss" ]] && conflicting_installs+=("$HOME/.local/share/hyss")
    fi
    
    # Handle cross-scope conflicts
    if [[ ${#conflicting_installs[@]} -gt 0 ]] && [[ "$FORCE_INSTALL" == "false" ]]; then
        print_warning "Conflicting installation detected:"
        for file in "${conflicting_installs[@]}"; do
            echo "  - $file"
        done
        echo
        print_info "Having both user-local and system-wide installations can cause:"
        echo "  • PATH priority confusion (user-local takes precedence)"
        echo "  • Version mismatches between installations"
        echo "  • Configuration and library conflicts"
        echo "  • Update confusion"
        echo
        print_info "Recommendations:"
        if [[ "$USER_INSTALL" == "true" ]]; then
            echo "  • Remove system installation: sudo rm -rf /usr/local/bin/hyss /usr/local/share/hyss"
            echo "  • Or use system installation instead: sudo ./install.sh"
        else
            echo "  • Remove user installation: rm -rf ~/.local/bin/hyss ~/.local/share/hyss"
            echo "  • Or use user installation instead: ./install.sh --user"
        fi
        echo
        read -r -p "Continue anyway? [y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY])
                print_warning "Proceeding with potentially conflicting installation..."
                ;;
            *)
                print_info "Installation cancelled"
                exit 0
                ;;
        esac
    fi
    
    # Handle same-scope overwrite
    if [[ ${#existing_files[@]} -gt 0 ]] && [[ "$FORCE_INSTALL" == "false" ]]; then
        print_warning "Existing installation found:"
        for file in "${existing_files[@]}"; do
            echo "  - $file"
        done
        echo
        read -r -p "Overwrite existing installation? [y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY])
                print_info "Proceeding with overwrite..."
                ;;
            *)
                print_info "Installation cancelled"
                exit 0
                ;;
        esac
    fi
}

# Detect Arch Linux package manager and AUR helper availability
detect_package_manager() {
    # Check if we're on Arch Linux with pacman
    if ! command -v pacman >/dev/null 2>&1; then
        echo "non-arch"
        return
    fi
    
    # We have pacman, now detect available AUR helpers
    if command -v yay >/dev/null 2>&1; then
        echo "pacman-yay"
    elif command -v paru >/dev/null 2>&1; then
        echo "pacman-paru"
    else
        echo "pacman"
    fi
}

# Get appropriate installation command based on package type and available tools
get_install_command() {
    local pkg_manager="$1"
    local package_type="$2"  # "official" or "aur"
    shift 2
    local packages=("$@")
    
    case "$pkg_manager" in
        pacman-yay)
            if [[ "$package_type" == "aur" ]]; then
                echo "yay -S ${packages[*]}"
            else
                echo "sudo pacman -S ${packages[*]}"
            fi
            ;;
        pacman-paru)
            if [[ "$package_type" == "aur" ]]; then
                echo "paru -S ${packages[*]}"
            else
                echo "sudo pacman -S ${packages[*]}"
            fi
            ;;
        pacman)
            if [[ "$package_type" == "aur" ]]; then
                echo "# AUR package requires manual installation:"
                echo "# git clone https://aur.archlinux.org/${packages[0]}.git && cd ${packages[0]} && makepkg -si"
            else
                echo "sudo pacman -S ${packages[*]}"
            fi
            ;;
        non-arch)
            echo "# This tool is designed for Arch Linux only."
            echo "# Please install HySS manually or use an Arch-based distribution."
            ;;
        *)
            echo "# Unable to detect package manager - please install manually: ${packages[*]}"
            ;;
    esac
}

# Map tool names to Arch Linux package names and determine package type
get_package_info() {
    local tool="$1"
    
    case "$tool" in
        grim)
            echo "official:grim"
            ;;
        slurp)
            echo "official:slurp"
            ;;
        wl-copy)
            echo "official:wl-clipboard"
            ;;
        imagemagick)
            echo "official:imagemagick"
            ;;
        tesseract)
            echo "official:tesseract tesseract-data-eng"
            ;;
        jq)
            echo "official:jq"
            ;;
        notify-send)
            echo "official:libnotify"
            ;;
        satty)
            echo "aur:satty"
            ;;
        swappy)
            echo "official:swappy"
            ;;
        *)
            echo "official:$tool"
            ;;
    esac
}

# Extract package names from package info
get_package_names() {
    local package_info="$1"
    echo "${package_info#*:}"
}

# Extract package type from package info  
get_package_type() {
    local package_info="$1"
    echo "${package_info%%:*}"
}

# Check dependencies before installation
check_dependencies() {
    if [[ "$IGNORE_DEPS" == "true" ]]; then
        print_info "Skipping dependency check (--ignore-deps)"
        return 0
    fi
    
    print_info "Checking dependencies..."
    echo
    
    # Source the tool detection library to reuse logic
    if [[ ! -f "$SCRIPT_DIR/lib/tool-detection.sh" ]]; then
        print_error "Cannot find lib/tool-detection.sh - dependency check failed"
        return 1
    fi
    
    # Set up temporary environment for tool detection
    local temp_data_dir
    temp_data_dir=$(mktemp -d)
    export DATA_DIR="$temp_data_dir"
    
    # Source tool detection with error handling
    if ! source "$SCRIPT_DIR/lib/tool-detection.sh" 2>/dev/null; then
        print_error "Failed to load tool detection library"
        rm -rf "$temp_data_dir"
        return 1
    fi
    
    # Run capability detection
    detect_all_capabilities 2>/dev/null
    
    # Check core requirements
    local missing_tools=()
    local missing_descriptions=()
    
    # Essential tools
    [[ "${TOOL_CAPABILITIES[grim_available]:-false}" != "true" ]] && missing_tools+=("grim") && missing_descriptions+=("Wayland screenshot utility")
    [[ "${TOOL_CAPABILITIES[slurp_available]:-false}" != "true" ]] && missing_tools+=("slurp") && missing_descriptions+=("Interactive area selection")
    [[ "${TOOL_CAPABILITIES[wl_copy_available]:-false}" != "true" ]] && missing_tools+=("wl-copy") && missing_descriptions+=("Clipboard integration")
    [[ "${TOOL_CAPABILITIES[imagemagick_available]:-false}" != "true" ]] && missing_tools+=("imagemagick") && missing_descriptions+=("Image processing")
    [[ "${TOOL_CAPABILITIES[tesseract_available]:-false}" != "true" ]] && missing_tools+=("tesseract") && missing_descriptions+=("OCR text extraction")
    [[ "${TOOL_CAPABILITIES[jq_available]:-false}" != "true" ]] && missing_tools+=("jq") && missing_descriptions+=("JSON processing")
    [[ "${TOOL_CAPABILITIES[notify_send_available]:-false}" != "true" ]] && missing_tools+=("notify-send") && missing_descriptions+=("Desktop notifications")
    
    # At least one annotation tool
    local has_annotation=false
    [[ "${TOOL_CAPABILITIES[satty_available]:-false}" == "true" ]] && has_annotation=true
    [[ "${TOOL_CAPABILITIES[swappy_available]:-false}" == "true" ]] && has_annotation=true
    
    if [[ "$has_annotation" == "false" ]]; then
        missing_tools+=("satty or swappy")
        missing_descriptions+=("Annotation tool")
    fi
    
    # Show results
    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        print_success "All core dependencies are available!"
        echo
        echo "Available tools:"
        [[ "${TOOL_CAPABILITIES[grim_available]:-false}" == "true" ]] && echo "  ✓ grim - Wayland screenshot utility"
        [[ "${TOOL_CAPABILITIES[slurp_available]:-false}" == "true" ]] && echo "  ✓ slurp - Interactive area selection"  
        [[ "${TOOL_CAPABILITIES[wl_copy_available]:-false}" == "true" ]] && echo "  ✓ wl-copy - Clipboard integration"
        [[ "${TOOL_CAPABILITIES[imagemagick_available]:-false}" == "true" ]] && echo "  ✓ imagemagick - Image processing"
        [[ "${TOOL_CAPABILITIES[tesseract_available]:-false}" == "true" ]] && echo "  ✓ tesseract - OCR text extraction"
        [[ "${TOOL_CAPABILITIES[jq_available]:-false}" == "true" ]] && echo "  ✓ jq - JSON processing"
        [[ "${TOOL_CAPABILITIES[notify_send_available]:-false}" == "true" ]] && echo "  ✓ notify-send - Desktop notifications"
        [[ "${TOOL_CAPABILITIES[satty_available]:-false}" == "true" ]] && echo "  ✓ satty - Modern annotation tool"
        [[ "${TOOL_CAPABILITIES[swappy_available]:-false}" == "true" ]] && echo "  ✓ swappy - Traditional annotation tool"
        echo
        rm -rf "$temp_data_dir"
        return 0
    else
        print_warning "Missing required dependencies:"
        echo
        for i in "${!missing_tools[@]}"; do
            echo "  ✗ ${missing_tools[$i]} - ${missing_descriptions[$i]}"
        done
        echo
        
        # Provide installation guidance
        local pkg_manager
        pkg_manager=$(detect_package_manager)
        
        if [[ "$pkg_manager" == "non-arch" ]]; then
            print_warning "This tool is designed for Arch Linux only."
            echo "Please install HySS manually or use an Arch-based distribution."
            echo
        else
            print_info "Installation guidance for Arch Linux ($pkg_manager):"
            echo
            
            # Generate package lists by type
            local official_packages=()
            local aur_packages=()
            
            for tool in grim slurp wl-copy imagemagick tesseract jq notify-send; do
                if [[ " ${missing_tools[*]} " =~ " ${tool} " ]]; then
                    local package_info package_names package_type
                    package_info=$(get_package_info "$tool")
                    package_names=$(get_package_names "$package_info")
                    package_type=$(get_package_type "$package_info")
                    
                    if [[ "$package_type" == "official" ]]; then
                        official_packages+=($package_names)
                    else
                        aur_packages+=($package_names)
                    fi
                fi
            done
            
            # Handle annotation tools separately
            local annotation_official=()
            local annotation_aur=()
            if [[ " ${missing_tools[*]} " =~ " satty or swappy " ]]; then
                local satty_info swappy_info
                satty_info=$(get_package_info "satty")
                swappy_info=$(get_package_info "swappy")
                
                if [[ "$(get_package_type "$satty_info")" == "official" ]]; then
                    annotation_official+=($(get_package_names "$satty_info"))
                else
                    annotation_aur+=($(get_package_names "$satty_info"))
                fi
                
                if [[ "$(get_package_type "$swappy_info")" == "official" ]]; then
                    annotation_official+=($(get_package_names "$swappy_info"))
                else
                    annotation_aur+=($(get_package_names "$swappy_info"))
                fi
            fi
            
            # Show installation commands
            if [[ ${#official_packages[@]} -gt 0 ]]; then
                echo "Core dependencies (official repos):"
                echo "  $(get_install_command "$pkg_manager" "official" "${official_packages[@]}")"
                echo
            fi
            
            if [[ ${#aur_packages[@]} -gt 0 ]]; then
                echo "Core dependencies (AUR):"
                echo "  $(get_install_command "$pkg_manager" "aur" "${aur_packages[@]}")"
                echo
            fi
            
            if [[ ${#annotation_official[@]} -gt 0 ]] || [[ ${#annotation_aur[@]} -gt 0 ]]; then
                echo "Annotation tools (choose at least one):"
                if [[ ${#annotation_official[@]} -gt 0 ]]; then
                    echo "  $(get_install_command "$pkg_manager" "official" "${annotation_official[@]}")"
                fi
                if [[ ${#annotation_aur[@]} -gt 0 ]]; then
                    echo "  $(get_install_command "$pkg_manager" "aur" "${annotation_aur[@]}")"
                fi
                echo
            fi
        fi
        
        rm -rf "$temp_data_dir"
        
        if [[ "$CHECK_ONLY" == "true" ]]; then
            return 1
        fi
        
        echo
        read -r -p "Continue installation without all dependencies? [y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY])
                print_warning "Proceeding with incomplete dependencies - HyprScreenShot may not work properly"
                return 0
                ;;
            *)
                print_info "Installation cancelled - please install missing dependencies first"
                return 1
                ;;
        esac
    fi
}

# Verify source files exist
verify_source_files() {
    local missing_files=()
    
    if [[ ! -f "$SCRIPT_DIR/hyss" ]]; then
        missing_files+=("hyss")
    fi
    
    if [[ ! -d "$SCRIPT_DIR/lib" ]]; then
        missing_files+=("lib/")
    fi
    
    # Check essential library files
    local required_libs=(
        "tool-detection.sh"
        "capture-abstraction.sh"
        "annotation-abstraction.sh"
        "clipboard-abstraction.sh"
        "config-system.sh"
        "migration-system.sh"
        "compatibility-testing.sh"
    )
    
    for lib in "${required_libs[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/lib/$lib" ]]; then
            missing_files+=("lib/$lib")
        fi
    done
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        print_error "Missing required source files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        print_error "Please run this script from the HyprScreenShot source directory"
        exit 1
    fi
}

# Create installation directories
create_directories() {
    print_info "Creating installation directories..."
    
    mkdir -p "$BIN_DIR" || {
        print_error "Failed to create directory: $BIN_DIR"
        exit 1
    }
    
    mkdir -p "$LIB_DIR" || {
        print_error "Failed to create directory: $LIB_DIR"
        exit 1
    }
    
    print_success "Directories created"
}

# Install files
install_files() {
    print_info "Installing HyprScreenShot files..."
    
    # Install main executable
    cp "$SCRIPT_DIR/hyss" "$BIN_DIR/hyss" || {
        print_error "Failed to install main executable"
        exit 1
    }
    
    # Make executable
    chmod +x "$BIN_DIR/hyss" || {
        print_error "Failed to set executable permissions"
        exit 1
    }
    
    # Install library files
    cp -r "$SCRIPT_DIR/lib"/* "$LIB_DIR/" || {
        print_error "Failed to install library files"
        exit 1
    }
    
    # Set appropriate permissions for library files
    find "$LIB_DIR" -type f -name "*.sh" -exec chmod +x {} \; || {
        print_error "Failed to set library permissions"
        exit 1
    }
    
    print_success "Files installed successfully"
}

# Check PATH configuration
check_path_configuration() {
    if [[ "$USER_INSTALL" == "true" ]]; then
        if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
            print_warning "~/.local/bin is not in your PATH"
            print_info "Add the following to your shell configuration (~/.bashrc, ~/.zshrc, etc.):"
            echo
            echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
            echo
            print_info "Then reload your shell or run: source ~/.bashrc"
            print_info "After that, you can use 'hyss' from anywhere"
        else
            print_success "~/.local/bin is already in your PATH"
        fi
    fi
}

# Test installation
test_installation() {
    print_info "Testing installation..."
    
    # Test that the command exists and is executable
    if ! command -v hyss >/dev/null 2>&1; then
        if [[ "$USER_INSTALL" == "true" ]] && ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
            # Expected for user install without PATH setup
            print_warning "hyss not found in PATH (this is expected for user installation)"
            print_info "Testing with absolute path..."
            test_command="$BIN_DIR/hyss"
        else
            print_error "hyss command not found after installation"
            return 1
        fi
    else
        test_command="hyss"
    fi
    
    # Test basic functionality
    if ! "$test_command" version >/dev/null 2>&1; then
        print_error "Installation test failed - hyss version command failed"
        return 1
    fi
    
    print_success "Installation test passed"
    return 0
}

# Show installation summary
show_summary() {
    echo
    print_success "HyprScreenShot installation complete!"
    echo
    echo "Installation details:"
    echo "  Type: $INSTALL_TYPE"
    echo "  Executable: $BIN_DIR/hyss"
    echo "  Libraries: $LIB_DIR"
    echo
    
    if [[ "$USER_INSTALL" == "true" ]] && ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
        print_info "Usage (until PATH is configured):"
        echo "  $BIN_DIR/hyss area           # Interactive area selection"
        echo "  $BIN_DIR/hyss config show    # Show configuration"
        echo
    else
        print_info "Usage:"
        echo "  hyss area                    # Interactive area selection"
        echo "  hyss freeze                  # Frozen screen selection"
        echo "  hyss config show             # Show configuration"
        echo "  hyss update check            # Check system status"
        echo
    fi
    
    print_info "For keybind integration, use absolute path:"
    echo "  Super+P    exec $BIN_DIR/hyss area"
    echo "  Print      exec $BIN_DIR/hyss screen"
    echo
    
    print_info "Run 'hyss help' for complete usage information"
}

# Main installation function
main() {
    echo "HyprScreenShot Installation Script"
    echo "=================================="
    echo
    
    parse_args "$@"
    
    # Handle check-only mode
    if [[ "$CHECK_ONLY" == "true" ]]; then
        print_info "Dependency check mode"
        echo
        if check_dependencies; then
            print_success "All dependencies satisfied - ready for installation"
            exit 0
        else
            print_error "Missing dependencies - please install them first"
            exit 1
        fi
    fi
    
    check_privileges
    set_install_paths
    
    print_info "Installing HyprScreenShot ($INSTALL_TYPE)"
    print_info "Target directories:"
    echo "  Executable: $BIN_DIR"
    echo "  Libraries:  $LIB_DIR"
    echo
    
    verify_source_files
    
    # Check dependencies before proceeding with installation
    if ! check_dependencies; then
        print_error "Dependency check failed - installation cancelled"
        exit 1
    fi
    
    check_existing_installation
    create_directories
    install_files
    
    if test_installation; then
        check_path_configuration
        show_summary
    else
        print_error "Installation completed but tests failed"
        print_error "Please check the installation manually"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"