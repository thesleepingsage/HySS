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
    --help, -h      Show this help message

EXAMPLES:
    sudo ./install.sh              # System-wide installation
    ./install.sh --user            # User-local installation
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
    
    if [[ -f "$BIN_DIR/hyss" ]]; then
        existing_files+=("$BIN_DIR/hyss")
    fi
    
    if [[ -d "$LIB_DIR" ]]; then
        existing_files+=("$LIB_DIR")
    fi
    
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
    check_privileges
    set_install_paths
    
    print_info "Installing HyprScreenShot ($INSTALL_TYPE)"
    print_info "Target directories:"
    echo "  Executable: $BIN_DIR"
    echo "  Libraries:  $LIB_DIR"
    echo
    
    verify_source_files
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