#!/bin/sh
set -e

# Logging mechanism for debugging
LOG_FILE="/tmp/dev-tools-additions-install.log"
log_debug() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [DEBUG] $*" >> "$LOG_FILE"
}

# Initialize logging
log_debug "=== DEV-TOOLS-ADDITIONS INSTALL STARTED ==="
log_debug "Script path: $0"
log_debug "PWD: $(pwd)"
log_debug "Environment: USER=$USER HOME=$HOME"

# Set DEBIAN_FRONTEND to noninteractive to prevent prompts
export DEBIAN_FRONTEND=noninteractive

# Get username from environment or default to babaji
USERNAME=${USERNAME:-"babaji"}
USER_HOME="/home/${USERNAME}"

# Function to get system architecture
get_architecture() {
    local arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l) echo "armv7" ;;
        *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
    esac
}

apt-get update
apt-get install -y --no-install-recommends \
    cifs-utils \
    samba-common-bin \
    smbclient \
    sshfs \
    curlftpfs \
    davfs2 \
    fuse3 \
    tree \
    mc \
    pipx

# Install gum
export GUM_VERSION="0.14.1"
ARCH=$(get_architecture)
wget -qO gum.deb "https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_${ARCH}.deb"
dpkg -i gum.deb
rm gum.deb

# Install fx (JSON processor)
if command -v npm &> /dev/null; then
    npm install -g fx
else
    echo "Warning: npm not found, skipping fx installation"
fi

# 🧩 Create Self-Healing Environment Fragment
create_environment_fragment() {
    local feature_name="dev-tools"
    local fragment_file_skel="/etc/skel/.ohmyzsh_source_load_scripts/.${feature_name}.zshrc"
    local fragment_file_user="$USER_HOME/.ohmyzsh_source_load_scripts/.${feature_name}.zshrc"
    
    # Create fragment content with self-healing detection
    local fragment_content='# 🛠️ Development Tools Environment Fragment
# Self-healing detection and environment setup

# Check if development tools are available
tools_available=false

# Check for fx (JSON processor)
if command -v fx >/dev/null 2>&1; then
    tools_available=true
    alias json="fx"
fi

# Check for pipx
if command -v pipx >/dev/null 2>&1; then
    tools_available=true
    PIPX_BIN_DIR="$(pipx environment 2>/dev/null | grep PIPX_BIN_DIR | cut -d= -f2)"
    if [ -n "$PIPX_BIN_DIR" ] && [ -d "$PIPX_BIN_DIR" ] && [[ ":$PATH:" != *":$PIPX_BIN_DIR:"* ]]; then
        export PATH="$PIPX_BIN_DIR:$PATH"
    fi
fi

# Ensure /usr/local/bin is in PATH for global tools
if [ -d "/usr/local/bin" ] && [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
    export PATH="/usr/local/bin:$PATH"
fi

# If no tools are available, cleanup this fragment
if [ "$tools_available" = false ]; then
    echo "Development tools removed, cleaning up environment"
    rm -f "$HOME/.ohmyzsh_source_load_scripts/.dev-tools.zshrc"
fi'

    # Create fragment for /etc/skel
    if [ -d "/etc/skel/.ohmyzsh_source_load_scripts" ]; then
        echo "$fragment_content" > "$fragment_file_skel"
    fi

    # Create fragment for existing user
    if [ -d "$USER_HOME/.ohmyzsh_source_load_scripts" ]; then
        echo "$fragment_content" > "$fragment_file_user"
        if [ "$USER" != "$USERNAME" ]; then
            chown ${USERNAME}:${USERNAME} "$fragment_file_user" 2>/dev/null || chown ${USERNAME}:users "$fragment_file_user" 2>/dev/null || true
        fi
    elif [ -d "$USER_HOME" ]; then
        # Create the directory if it doesn't exist
        mkdir -p "$USER_HOME/.ohmyzsh_source_load_scripts"
        echo "$fragment_content" > "$fragment_file_user"
        if [ "$USER" != "$USERNAME" ]; then
            chown -R ${USERNAME}:${USERNAME} "$USER_HOME/.ohmyzsh_source_load_scripts" 2>/dev/null || chown -R ${USERNAME}:users "$USER_HOME/.ohmyzsh_source_load_scripts" 2>/dev/null || true
        fi
    fi
    
    echo "Self-healing environment fragment created: .dev-tools.zshrc"
}

# Call the fragment creation function
create_environment_fragment

log_debug "=== DEV-TOOLS-ADDITIONS INSTALL COMPLETED ==="
# Auto-trigger build Tue Sep 23 20:02:59 BST 2025
# Auto-trigger build Sun Sep 28 03:45:14 BST 2025
