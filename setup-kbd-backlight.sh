#!/bin/bash

# setup-kbd-backlight.sh
# Script to set up keyboard backlight control with brightnessctl
# This script automates the process of setting up keyboard backlight controls
# including installation of dependencies, permission configuration, and udev rules.

set -e  # Exit immediately if a command exits with a non-zero status

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_msg() {
    echo -e "${2}${1}${NC}"
}

# Function to print error message and exit
error_exit() {
    print_msg "ERROR: $1" "$RED"
    exit 1
}

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "This operation requires root privileges. Please run with sudo or as root."
    fi
}

# Function to detect package manager
detect_package_manager() {
    if command_exists pacman; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="pacman -S --noconfirm"
    elif command_exists apt-get; then
        PKG_MANAGER="apt"
        INSTALL_CMD="apt-get install -y"
    elif command_exists dnf; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="dnf install -y"
    elif command_exists zypper; then
        PKG_MANAGER="zypper"
        INSTALL_CMD="zypper install -y"
    else
        error_exit "Could not detect package manager. Please install brightnessctl manually."
    fi
    print_msg "Detected package manager: $PKG_MANAGER" "$BLUE"
}

# Function to install brightnessctl
install_brightnessctl() {
    print_msg "Checking if brightnessctl is installed..." "$BLUE"
    
    if ! command_exists brightnessctl; then
        print_msg "brightnessctl not found. Installing..." "$YELLOW"
        detect_package_manager
        
        # Need root privileges to install packages
        if [ "$EUID" -ne 0 ]; then
            print_msg "Need root privileges to install packages." "$YELLOW"
            if sudo $INSTALL_CMD brightnessctl; then
                print_msg "brightnessctl installed successfully." "$GREEN"
            else
                error_exit "Failed to install brightnessctl."
            fi
        else
            if $INSTALL_CMD brightnessctl; then
                print_msg "brightnessctl installed successfully." "$GREEN"
            else
                error_exit "Failed to install brightnessctl."
            fi
        fi
    else
        print_msg "brightnessctl is already installed." "$GREEN"
    fi
}

# Function to find keyboard backlight path
find_kbd_backlight() {
    print_msg "Looking for keyboard backlight device..." "$BLUE"
    
    # Try to find the keyboard backlight path
    KBD_BACKLIGHT_PATH=$(find /sys/class/leds -name "*kbd_backlight*" -type d | head -n 1)
    
    if [ -z "$KBD_BACKLIGHT_PATH" ]; then
        print_msg "Warning: Keyboard backlight path not found." "$YELLOW"
        print_msg "Will continue with generic configuration." "$YELLOW"
        DEVICE_NAME="*kbd*"
    else
        print_msg "Found keyboard backlight at: $KBD_BACKLIGHT_PATH" "$GREEN"
        DEVICE_NAME=$(basename "$KBD_BACKLIGHT_PATH")
        print_msg "Device name: $DEVICE_NAME" "$GREEN"
    fi
}

# Function to check and add user to video group
setup_user_permissions() {
    print_msg "Setting up user permissions..." "$BLUE"
    
    # Get current user if running with sudo
    if [ -n "$SUDO_USER" ]; then
        CURRENT_USER="$SUDO_USER"
    else
        CURRENT_USER="$USER"
    fi
    
    print_msg "Setting up permissions for user: $CURRENT_USER" "$BLUE"
    
    # Check if user is already in video group
    if groups "$CURRENT_USER" | grep -q "\bvideo\b"; then
        print_msg "User $CURRENT_USER is already in the video group." "$GREEN"
    else
        print_msg "Adding user $CURRENT_USER to video group..." "$YELLOW"
        
        # Need root privileges to add user to group
        if [ "$EUID" -ne 0 ]; then
            if sudo gpasswd -a "$CURRENT_USER" video; then
                print_msg "Added $CURRENT_USER to video group." "$GREEN"
            else
                error_exit "Failed to add user to video group."
            fi
        else
            if gpasswd -a "$CURRENT_USER" video; then
                print_msg "Added $CURRENT_USER to video group." "$GREEN"
            else
                error_exit "Failed to add user to video group."
            fi
        fi
    fi
}

# Function to set up udev rules
setup_udev_rules() {
    print_msg "Setting up udev rules..." "$BLUE"
    
    UDEV_RULE="KERNEL==\"*kbd_backlight*\", MODE=\"0664\", GROUP=\"video\""
    UDEV_FILE="/etc/udev/rules.d/90-kbd-backlight.rules"
    
    # Need root privileges to create udev rules
    if [ "$EUID" -ne 0 ]; then
        print_msg "Creating udev rule file with sudo..." "$YELLOW"
        echo "$UDEV_RULE" | sudo tee "$UDEV_FILE" > /dev/null
    else
        print_msg "Creating udev rule file..." "$YELLOW"
        echo "$UDEV_RULE" > "$UDEV_FILE"
    fi
    
    print_msg "Created udev rule: $UDEV_FILE" "$GREEN"
    
    # Reload udev rules
    print_msg "Reloading udev rules..." "$BLUE"
    
    if [ "$EUID" -ne 0 ]; then
        if sudo udevadm control --reload-rules && sudo udevadm trigger; then
            print_msg "Udev rules reloaded." "$GREEN"
        else
            error_exit "Failed to reload udev rules."
        fi
    else
        if udevadm control --reload-rules && udevadm trigger; then
            print_msg "Udev rules reloaded." "$GREEN"
        else
            error_exit "Failed to reload udev rules."
        fi
    fi
}

# Function to test brightness access
test_brightness_access() {
    print_msg "Testing brightness access..." "$BLUE"
    
    if brightnessctl -d "$DEVICE_NAME" get &> /dev/null; then
        BRIGHTNESS=$(brightnessctl -d "$DEVICE_NAME" get)
        print_msg "Successfully read brightness: $BRIGHTNESS" "$GREEN"
    else
        print_msg "Warning: Could not read brightness. You may need to log out and log back in for group changes to take effect." "$YELLOW"
    fi
}

# Function to set up Hyprland configuration
setup_hyprland() {
    print_msg "Setting up Hyprland integration..." "$BLUE"
    
    # Create Hyprland scripts directory if it doesn't exist
    HYPR_CONFIG_DIR="$HOME/.config/hypr"
    SCRIPTS_DIR="$HYPR_CONFIG_DIR/scripts"
    
    if [ ! -d "$SCRIPTS_DIR" ]; then
        print_msg "Creating Hyprland scripts directory: $SCRIPTS_DIR" "$YELLOW"
        mkdir -p "$SCRIPTS_DIR"
    fi
    
    # Create BrightnessKbd.sh script
    BRIGHTNESS_SCRIPT="$SCRIPTS_DIR/BrightnessKbd.sh"
    
    if [ ! -f "$BRIGHTNESS_SCRIPT" ]; then
        print_msg "Creating keyboard brightness script: $BRIGHTNESS_SCRIPT" "$YELLOW"
        
        cat > "$BRIGHTNESS_SCRIPT" << 'EOL'
#!/bin/bash

# Script to control keyboard backlight brightness
# This script uses brightnessctl to adjust the keyboard backlight brightness

# Find keyboard backlight device
KBD_DEVICE=$(brightnessctl -l | grep kbd | head -n1 | cut -d"'" -f2)

# If no device found, try with a wildcard
if [ -z "$KBD_DEVICE" ]; then
    KBD_DEVICE="*kbd*"
fi

case $1 in
    --inc)
        brightnessctl -d "$KBD_DEVICE" set +1
        ;;
    --dec)
        brightnessctl -d "$KBD_DEVICE" set 1-
        ;;
    *)
        echo "Usage: $0 [--inc|--dec]"
        exit 1
        ;;
esac

# Get current brightness percentage for notification
BRIGHTNESS=$(brightnessctl -d "$KBD_DEVICE" get)
MAX_BRIGHTNESS=$(brightnessctl -d "$KBD_DEVICE" max)
PERCENT=$((BRIGHTNESS * 100 / MAX_BRIGHTNESS))

# Send notification if notify-send is available
if command -v notify-send &> /dev/null; then
    notify-send -t 1000 "Keyboard Brightness: $PERCENT%"
fi

exit 0
EOL
        
        # Make the script executable
        chmod +x "$BRIGHTNESS_SCRIPT"
        print_msg "Created and made executable: $BRIGHTNESS_SCRIPT" "$GREEN"
    else
        print_msg "Keyboard brightness script already exists: $BRIGHTNESS_SCRIPT" "$GREEN"
    fi
    
    # Check/create Laptops.conf for keybindings
    LAPTOPS_CONF="$HYPR_CONFIG_DIR/UserConfigs/Laptops.conf"
    
    if [ ! -d "$(dirname "$LAPTOPS_CONF")" ]; then
        print_msg "Creating directory: $(dirname "$LAPTOPS_CONF")" "$YELLOW"
        mkdir -p "$(dirname "$LAPTOPS_CONF")"
    fi
    
    if [ ! -f "$LAPTOPS_CONF" ] || ! grep -q "xf86KbdBrightness" "$LAPTOPS_CONF"; then
        print_msg "Adding keyboard backlight keybindings to: $LAPTOPS_CONF" "$YELLOW"
        
        # Append keybindings to Laptops.conf
        cat >> "$LAPTOPS_CONF" << EOL

# Keyboard backlight control
binde = , xf86KbdBrightnessDown, exec, $SCRIPTS_DIR/BrightnessKbd.sh --dec
binde = , xf86KbdBrightnessUp, exec, $SCRIPTS_DIR/BrightnessKbd.sh --inc
EOL
        
        print_msg "Added keyboard backlight keybindings to $LAPTOPS_CONF" "$GREEN"
    else
        print_msg "Keyboard backlight keybindings already exist in $LAPTOPS_CONF" "$GREEN"
    fi
    
    # Check if Laptops.conf is included in hyprland.conf
    HYPRLAND_CONF="$HYPR_CONFIG_DIR/hyprland.conf"
    
    if [ -f "$HYPRLAND_CONF" ]; then
        if ! grep -q "UserConfigs/Laptops.conf" "$HYPRLAND_CONF"; then
            print_msg "Adding Laptops.conf to hyprland.conf" "$YELLOW"
            echo "source = $LAPTOPS_CONF" >> "$HYPRLAND_CONF"
            print_msg "Added Laptops.conf to hyprland.conf" "$GREEN"
        else
            print_msg "Laptops.conf is already included in hyprland.conf" "$GREEN"
        fi
    else
        print_msg "Warning: hyprland.conf not found. You may need to create it and include Laptops.conf" "$YELLOW"
    fi
}

# Function to provide final instructions
final_instructions() {
    print_msg "\n===== SETUP COMPLETE =====" "$GREEN"
    print_msg "\nKeyboard backlight control has been set up successfully!" "$GREEN"
    print_msg "\nNotes:" "$BLUE"
    print_msg "1. If you were added to the video group, you may need to log out and log back in for changes to take effect." "$YELLOW"
    print_msg "2. Test keyboard backlight control using:" "$YELLOW"
    print_msg "   brightnessctl -d '$DEVICE_NAME' set +1  # increase" "$BLUE"
    print_msg "   brightnessctl -d '$DEVICE_NAME' set 1-  # decrease" "$BLUE"
    print_msg "3. In Hyprland, use your keyboard's Fn keys to control backlight brightness." "$YELLOW"
    print_msg "\nIf you encounter any issues, please check the following:" "$YELLOW"
    print_msg "- Verify you're in the video group: 'groups \$USER'" "$BLUE"
    print_msg "- Check udev rules: 'cat $UDEV_FILE'" "$BLUE"
    print_msg "- Ensure script is executable: 'ls -l $SCRIPTS_DIR/BrightnessKbd.sh'" "$BLUE"
    print_msg "- Check Hyprland configuration for proper keybindings" "$BLUE"
}

# Main script execution
main() {
    print_msg "Starting keyboard backlight setup..." "$GREEN"
    
    # Step 1: Install brightnessctl
    install_brightnessctl
    
    # Step 2: Find keyboard backlight device
    find_kbd_backlight
    
    # Step 3: Setup user permissions
    setup_user_permissions
    
    # Step 4: Setup udev rules
    setup_udev_rules
    
    # Step 5: Test brightness access
    test_brightness_access
    
    # Step 6: Setup Hyprland configuration
    setup_hyprland
    
    # Step 7: Final instructions
    final_instructions
}

# Run the main function
main

