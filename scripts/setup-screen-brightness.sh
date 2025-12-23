#!/bin/bash

# setup-screen-brightness.sh
# This script sets up screen brightness control by:
# 1. Installing necessary packages
# 2. Setting up udev rules and permissions
# 3. Configuring Hyprland for brightness control
# 4. Supporting both ACPI and backlight interfaces
# 5. Handling multiple displays

set -e

# Text formatting
BOLD="\e[1m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${RESET} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

# Check if script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        echo "Please run with: sudo $0"
        exit 1
    fi
}

# Get the actual user who ran the script with sudo
get_actual_user() {
    if [ -n "$SUDO_USER" ]; then
        echo "$SUDO_USER"
    else
        echo "$USER"
    fi
}

# Detect package manager
detect_package_manager() {
    if command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# Install a package using the appropriate package manager
install_package() {
    local package="$1"
    local package_manager=$(detect_package_manager)
    
    log_info "Installing $package..."
    
    case "$package_manager" in
        pacman)
            pacman -S --noconfirm "$package"
            ;;
        apt)
            apt-get update && apt-get install -y "$package"
            ;;
        dnf)
            dnf install -y "$package"
            ;;
        zypper)
            zypper install -y "$package"
            ;;
        *)
            log_error "Unsupported package manager. Please install $package manually."
            exit 1
            ;;
    esac
    
    log_success "$package installed successfully."
}

# Check if a package is installed
is_package_installed() {
    local package="$1"
    local package_manager=$(detect_package_manager)
    
    case "$package_manager" in
        pacman)
            pacman -Qi "$package" >/dev/null 2>&1
            ;;
        apt)
            dpkg -l "$package" | grep -q '^ii' >/dev/null 2>&1
            ;;
        dnf)
            dnf list installed "$package" >/dev/null 2>&1
            ;;
        zypper)
            zypper search -i "$package" | grep -q "$package" >/dev/null 2>&1
            ;;
        *)
            command -v "$package" >/dev/null 2>&1
            ;;
    esac
}

# Detect backlight interfaces
detect_backlight_interfaces() {
    local interfaces=()
    
    # Check for ACPI backlight interface
    if [ -d "/sys/class/backlight" ]; then
        for device in /sys/class/backlight/*; do
            if [ -d "$device" ]; then
                interfaces+=("$device")
            fi
        done
    fi
    
    # Check for DDC/CI capable monitors
    if command -v ddcutil >/dev/null 2>&1; then
        if ddcutil detect >/dev/null 2>&1; then
            interfaces+=("ddcutil")
        fi
    fi
    
    echo "${interfaces[@]}"
}

# Create udev rules for backlight control
create_udev_rules() {
    log_info "Setting up udev rules for backlight control..."
    
    # Create udev rule file
    cat > /etc/udev/rules.d/90-backlight.rules << EOF
# Allow users in video group to change backlight brightness
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chmod 666 /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power"
SUBSYSTEM=="backlight", ACTION=="add", KERNEL=="*", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"
SUBSYSTEM=="backlight", ACTION=="add", KERNEL=="*", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
EOF
    
    log_info "Reloading udev rules..."
    udevadm control --reload-rules
    udevadm trigger
    
    log_success "Udev rules created and applied."
}

# Add user to video group
add_user_to_video_group() {
    local username="$1"
    
    if groups "$username" | grep -q "\bvideo\b"; then
        log_info "User $username is already in the video group."
    else
        log_info "Adding user $username to video group..."
        usermod -a -G video "$username"
        log_success "User $username added to video group."
        log_warning "You may need to log out and log back in for group changes to take effect."
    fi
}

# Create Hyprland brightness script
create_brightness_script() {
    local username="$1"
    local user_home="/home/$username"
    local scripts_dir="$user_home/.config/hypr/scripts"
    
    # Create scripts directory if it doesn't exist
    if [ ! -d "$scripts_dir" ]; then
        log_info "Creating Hyprland scripts directory..."
        mkdir -p "$scripts_dir"
        chown -R "$username:$username" "$user_home/.config/hypr"
    fi
    
    # Create the brightness script
    log_info "Creating brightness control script..."
    cat > "$scripts_dir/Brightness.sh" << 'EOF'
#!/bin/bash

# Brightness control script for Hyprland

STEP=5  # Brightness step in percentage

function get_brightness {
    brightnessctl -m | grep -oP "(?<=,)([0-9]+)(?=%)" | head -n 1
}

function send_notification {
    brightness=$(get_brightness)
    
    # Create the brightness bar
    bar=$(seq -s "█" $((brightness / 5 + 1)) | sed 's/[0-9]//g')
    spaces=$(seq -s " " $((20 - brightness / 5 + 1)) | sed 's/[0-9]//g')
    
    notify-send -t 1000 -r 9999 -u low "Brightness: $brightness%" "$bar$spaces"
}

case $1 in
    "--inc")
        # Increase brightness
        brightnessctl set "${STEP}%+" -q 
        send_notification
        ;;
    "--dec")
        # Decrease brightness
        brightnessctl set "${STEP}%-" -q
        send_notification
        ;;
    "--set")
        # Set absolute brightness
        if [ -n "$2" ]; then
            brightnessctl set "$2%" -q
            send_notification
        fi
        ;;
    "--get")
        # Get current brightness
        get_brightness
        ;;
    *)
        echo "Usage: $0 [--inc|--dec|--set VALUE|--get]"
        exit 1
        ;;
esac

exit 0
EOF
    
    # Make the script executable
    chmod +x "$scripts_dir/Brightness.sh"
    chown "$username:$username" "$scripts_dir/Brightness.sh"
    
    log_success "Brightness control script created at $scripts_dir/Brightness.sh"
}

# Create/update Hyprland config for brightness
configure_hyprland() {
    local username="$1"
    local user_home="/home/$username"
    local hypr_config_dir="$user_home/.config/hypr"
    local hypr_config_file="$hypr_config_dir/hyprland.conf"
    local keybinds_file="$hypr_config_dir/keybinds.conf"
    
    # Ensure the Hyprland config directory exists
    if [ ! -d "$hypr_config_dir" ]; then
        log_info "Creating Hyprland config directory..."
        mkdir -p "$hypr_config_dir"
        chown -R "$username:$username" "$hypr_config_dir"
    fi
    
    # Define our brightness keybinds
    log_info "Setting up Hyprland brightness keybinds..."
    
    # Check if we should append to a separate keybinds file or the main config
    if [ -f "$keybinds_file" ]; then
        config_target="$keybinds_file"
    else
        config_target="$hypr_config_file"
    fi
    
    # Check if brightness keybinds already exist
    if ! grep -q "XF86MonBrightness" "$config_target" 2>/dev/null; then
        # Add keybinds to the configuration
        cat >> "$config_target" << 'EOF'

# Screen brightness controls
bind = , XF86MonBrightnessUp, exec, ~/.config/hypr/scripts/Brightness.sh --inc
bind = , XF86MonBrightnessDown, exec, ~/.config/hypr/scripts/Brightness.sh --dec

EOF
        log_success "Brightness keybinds added to Hyprland configuration."
    else
        log_info "Brightness keybinds already exist in Hyprland configuration."
    fi
    
    # Ensure proper ownership
    chown -R "$username:$username" "$hypr_config_dir"
}

# Main script execution
main() {
    clear
    echo -e "${BOLD}Screen Brightness Setup Script${RESET}"
    echo "This script will set up screen brightness control for your system."
    echo "--------------------------------------------------------"
    
    # Check for root privileges
    check_root
    
    # Get actual user
    ACTUAL_USER=$(get_actual_user)
    log_info "Setting up brightness control for user: $ACTUAL_USER"
    
    # Check and install dependencies
    log_info "Checking dependencies..."
    
    # Check for brightnessctl
    if ! is_package_installed "brightnessctl"; then
        install_package "brightnessctl"
    else
        log_success "brightnessctl is already installed."
    fi
    
    # Optional: Check for ddcutil (for external monitors)
    if ! is_package_installed "ddcutil"; then
        log_info "ddcutil is not installed. This is optional but recommended for external monitor brightness control."
        read -p "Do you want to install ddcutil? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_package "ddcutil"
            
            # Additional setup for i2c devices
            if [ -d "/dev/i2c" ]; then
                log_info "Setting up i2c devices for ddcutil..."
                if ! grep -q "^i2c-dev" /etc/modules 2>/dev/null; then
                    echo "i2c-dev" >> /etc/modules
                    log_info "Added i2c-dev to /etc/modules"
                fi
                
                if ! grep -q "KERNEL==\"i2c-[0-9]*\"" /etc/udev/rules.d/90-i2c.rules 2>/dev/null; then
                    cat > /etc/udev/rules.d/90-i2c.rules << EOF
# Give everyone read and write access to i2c devices
KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
EOF
                    log_info "Created i2c udev rules"
                    
                    if ! getent group i2c > /dev/null; then
                        groupadd i2c
                        log_info "Created i2c group"
                    fi
                    
                    usermod -a -G i2c "$ACTUAL_USER"
                    log_info "Added user $ACTUAL_USER to i2c group"
                fi
            fi
        fi
    else
        log_success "ddcutil is already installed."
    fi
    
    # Check for notify-send for notifications
    if ! command -v notify-send >/dev/null 2>&1; then
        log_info "libnotify is required for brightness notifications."
        install_package "libnotify"
    fi
    
    # Detect backlight interfaces
    log_info "Detecting backlight interfaces..."
    INTERFACES=$(detect_backlight_interfaces)
    
    if [ -z "$INTERFACES" ]; then
        log_warning "No backlight interfaces detected."
        log_info "Proceeding with generic setup. Brightness control may still work with brightnessctl."
    else
        for interface in $INTERFACES; do
            log_info "Detected backlight interface: $interface"
        done
    fi
    
    # Create udev rules
    create_udev_rules
    
    # Add user to video group
    add_user_to_video_group "$ACTUAL_USER"
    
    # Create Hyprland brightness script
    create_brightness_script "$ACTUAL_USER"
    
    # Configure Hyprland
    configure_hyprland "$ACTUAL_USER"
    
    # Final instructions
    echo
    log_success "Screen brightness setup completed!"
    echo
    echo -e "${BOLD}Next steps:${RESET}"
    echo "1. You may need to log out and log back in for group changes to take effect."
    echo "2. Test brightness control with: brightnessctl set +5%"
    echo "3. In Hyprland, use the function keys for brightness control."
    echo
    echo -e "${BOLD}Troubleshooting:${RESET}"
    echo "- If brightness control doesn't work, try rebooting your system."
    echo "- For external monitors, you may need additional ddcutil configuration."
    echo "- Check the Hyprland configuration if keybinds don't work."
    echo
    echo "For more information, see: https://wiki.archlinux.org/title/Backlight"
}

# Run the main function
main

