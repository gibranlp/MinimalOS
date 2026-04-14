#!/bin/bash
# ___  ____      _                _  ___  ____
#|  \/  (_)_ __ (_)_ __ ___   __ _| |/ _ \/ ___|
#| |\/| | | '_ \| | '_ ` _ \ / _` | | | | \___ \
#| |  | | | | | | | | | | | | (_| | | |_| |___) |
#|_|  |_|_|_| |_|_|_| |_| |_|\__,_|_|\___/|____/
#
# MinimalOS Installer
# Post-base-install script for Arch Linux.
# Assumes: base system installed, user exists, has sudo, internet is up.
# By: gibranlp <thisdoesnotwork@gibranlp.dev>
# MIT licence
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_CONF="$REPO_DIR/packages.conf"
LOG_FILE="/tmp/minimalos_install_$(date +%s).log"

# ── Colours ───────────────────────────────────────────────────────────────
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
B='\033[0;34m' C='\033[0;36m' N='\033[0m'

log()     { echo -e "${C}[INFO]${N}  $*" | tee -a "$LOG_FILE"; }
ok()      { echo -e "${G}[ OK ]${N}  $*" | tee -a "$LOG_FILE"; }
warn()    { echo -e "${Y}[WARN]${N}  $*" | tee -a "$LOG_FILE"; }
err()     { echo -e "${R}[ERR ]${N}  $*" | tee -a "$LOG_FILE"; }
section() { echo -e "\n${B}══════════════════════════════════════════${N}"; \
            echo -e "${B}  $*${N}"; \
            echo -e "${B}══════════════════════════════════════════${N}"; }
ask()     { echo -en "${Y}[ASK ]${N}  $* [y/N] "; read -r ans; [[ "$ans" =~ ^[Yy]$ ]]; }

# ── Parse packages.conf ───────────────────────────────────────────────────
# Usage: parse_packages pacman|aur
parse_packages() {
    local section="$1"
    awk -v sec="[$section]" '
        /^\[/ { found = ($0 == sec) }
        found && !/^\[/ && !/^#/ && !/^[[:space:]]*$/ {
            sub(/#.*/, ""); gsub(/^[[:space:]]+|[[:space:]]+$/, ""); print
        }
    ' "$PACKAGES_CONF"
}

# ── Pre-flight ─────────────────────────────────────────────────────────────
preflight() {
    section "Pre-flight Checks"

    if [ "$EUID" -eq 0 ]; then
        err "Do not run as root. Run as a regular user with sudo access."
        exit 1
    fi
    ok "Running as $USER"

    if ! grep -qi 'arch linux' /etc/os-release 2>/dev/null; then
        err "This installer is for Arch Linux only."
        exit 1
    fi
    ok "Arch Linux detected"

    if ! ping -c 1 archlinux.org &>/dev/null; then
        err "No internet connection. Check your network."
        exit 1
    fi
    ok "Internet connection active"

    sudo -v
    ok "sudo access confirmed"

    log "Log file: $LOG_FILE"
}

# ── Phase 1: System Update ─────────────────────────────────────────────────
system_update() {
    section "Phase 1: System Update"
    log "Updating keyring and base system…"
    sudo pacman -Sy --noconfirm archlinux-keyring 2>&1 | tee -a "$LOG_FILE"
    sudo pacman -Syu --noconfirm 2>&1 | tee -a "$LOG_FILE"
    ok "System updated"
}

# ── Phase 2: Install paru ─────────────────────────────────────────────────
install_paru() {
    section "Phase 2: AUR Helper (paru)"
    if command -v paru &>/dev/null; then
        ok "paru already installed"
        return
    fi
    log "Installing paru…"
    sudo pacman -S --needed --noconfirm git base-devel 2>&1 | tee -a "$LOG_FILE"
    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone --depth 1 https://aur.archlinux.org/paru.git "$tmp_dir/paru" 2>&1 | tee -a "$LOG_FILE"
    (cd "$tmp_dir/paru" && makepkg -si --noconfirm) 2>&1 | tee -a "$LOG_FILE"
    rm -rf "$tmp_dir"
    ok "paru installed"
}

# ── Phase 3: Zen Kernel ───────────────────────────────────────────────────
install_zen_kernel() {
    section "Phase 3: Zen Kernel"
    if pacman -Qi linux-zen &>/dev/null; then
        ok "linux-zen already installed"
        return
    fi
    log "Installing linux-zen and headers…"
    paru -S --needed --noconfirm linux-zen linux-zen-headers 2>&1 | tee -a "$LOG_FILE"
    ok "Zen kernel installed"
    warn "You will need to update your bootloader to add the zen kernel entry."
}

# ── Phase 4: Pacman Packages ──────────────────────────────────────────────
install_pacman_packages() {
    section "Phase 4: Pacman Packages"
    local pkgs
    pkgs=$(parse_packages "pacman" | tr '\n' ' ')
    if [ -z "$pkgs" ]; then
        warn "No pacman packages found in packages.conf"
        return
    fi
    log "Installing pacman packages…"
    # shellcheck disable=SC2086
    sudo pacman -S --needed --noconfirm $pkgs 2>&1 | tee -a "$LOG_FILE"
    ok "Pacman packages installed"
}

# ── Phase 5: AUR Packages ─────────────────────────────────────────────────
install_aur_packages() {
    section "Phase 5: AUR Packages"
    # cwal is handled separately (Phase 7), skip here to control build order
    local pkgs
    pkgs=$(parse_packages "aur" | grep -v '^cwal$' | tr '\n' ' ')
    if [ -z "$pkgs" ]; then
        warn "No AUR packages found in packages.conf"
        return
    fi
    log "Installing AUR packages (this may take a while)…"
    # shellcheck disable=SC2086
    paru -S --needed --noconfirm $pkgs 2>&1 | tee -a "$LOG_FILE"
    ok "AUR packages installed"
}

# ── Phase 6: Rust + broot ─────────────────────────────────────────────────
install_broot() {
    section "Phase 6: broot (file manager)"

    # Ensure cargo is available
    if ! command -v cargo &>/dev/null; then
        log "Installing Rust via rustup…"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
            2>&1 | tee -a "$LOG_FILE"
        # shellcheck disable=SC1091
        source "$HOME/.cargo/env"
    fi

    if command -v broot &>/dev/null; then
        ok "broot already installed"
        return
    fi

    log "Building broot with clipboard support…"
    cargo install --locked --features clipboard broot 2>&1 | tee -a "$LOG_FILE"
    ok "broot installed"
}

# ── Phase 7: cwal ─────────────────────────────────────────────────────────
install_cwal() {
    section "Phase 7: cwal (color theming)"
    if command -v cwal &>/dev/null; then
        ok "cwal already installed"
        return
    fi

    log "Installing cwal from AUR…"
    if paru -S --needed --noconfirm cwal 2>&1 | tee -a "$LOG_FILE"; then
        ok "cwal installed via AUR"
        return
    fi

    warn "AUR install failed — building cwal from source…"
    sudo pacman -S --needed --noconfirm cmake luajit imagemagick 2>&1 | tee -a "$LOG_FILE"
    local tmp_dir
    tmp_dir=$(mktemp -d)
    git clone --depth 1 https://github.com/nitinbhat972/cwal.git "$tmp_dir/cwal" \
        2>&1 | tee -a "$LOG_FILE"
    (
        mkdir -p "$tmp_dir/cwal/build"
        cd "$tmp_dir/cwal/build"
        cmake -DCMAKE_INSTALL_PREFIX="$HOME/.local" .. 2>&1 | tee -a "$LOG_FILE"
        make -j"$(nproc)" 2>&1 | tee -a "$LOG_FILE"
        make install 2>&1 | tee -a "$LOG_FILE"
    )
    rm -rf "$tmp_dir"
    ok "cwal built and installed from source"
}

# ── Phase 8: GPU Drivers ──────────────────────────────────────────────────
install_gpu_drivers() {
    section "Phase 8: GPU Driver Detection"

    local gpu_info
    gpu_info=$(lspci 2>/dev/null | grep -i "vga\|3d\|display")
    log "Detected GPU(s):"
    echo "$gpu_info" | while IFS= read -r line; do log "  $line"; done

    if echo "$gpu_info" | grep -iq nvidia; then
        log "NVIDIA GPU detected"
        if ask "Install NVIDIA DKMS drivers (nvidia-dkms)?"; then
            paru -S --needed --noconfirm \
                nvidia-dkms nvidia-utils lib32-nvidia-utils \
                nvidia-settings \
                2>&1 | tee -a "$LOG_FILE"
            # Blacklist nouveau
            echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
            ok "NVIDIA drivers installed"
        fi
    fi

    if echo "$gpu_info" | grep -iq "amd\|radeon"; then
        log "AMD GPU detected"
        if ask "Install AMD open-source drivers (xf86-video-amdgpu + Vulkan)?"; then
            sudo pacman -S --needed --noconfirm \
                xf86-video-amdgpu mesa lib32-mesa \
                vulkan-radeon lib32-vulkan-radeon \
                libva-mesa-driver lib32-libva-mesa-driver \
                mesa-vdpau lib32-mesa-vdpau \
                2>&1 | tee -a "$LOG_FILE"
            ok "AMD drivers installed"
        fi
    fi

    if echo "$gpu_info" | grep -iq intel; then
        log "Intel GPU detected"
        if ask "Install Intel drivers (xf86-video-intel + Vulkan)?"; then
            sudo pacman -S --needed --noconfirm \
                xf86-video-intel mesa lib32-mesa \
                vulkan-intel lib32-vulkan-intel \
                2>&1 | tee -a "$LOG_FILE"
            ok "Intel drivers installed"
        fi
    fi
}

# ── Phase 9: AwesomeWM + Auto-login ──────────────────────────────────────
setup_awesome_autologin() {
    section "Phase 9: AwesomeWM + Auto-login (no display manager)"

    # .xinitrc — start AwesomeWM
    cat > "$HOME/.xinitrc" << 'EOF'
#!/bin/sh
# MinimalOS .xinitrc
# Load Xresources
[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources

# Keyboard repeat rate
xset r rate 300 50

# Disable screen blanking (good for gaming)
xset s off
xset -dpms

# Set cursor
xsetroot -cursor_name left_ptr

# Start AwesomeWM
exec awesome
EOF
    ok ".xinitrc created"

    # .zprofile — auto-start X on TTY1
    cat >> "$HOME/.zprofile" << 'ZPROFILE'

# MinimalOS: auto-start X on TTY1
if [[ -z "$DISPLAY" ]] && [[ "$(tty)" == "/dev/tty1" ]]; then
    exec startx
fi
ZPROFILE
    ok ".zprofile updated for auto-login"

    # systemd getty override for autologin
    sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
    sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null << EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin ${USER} --noclear %I \$TERM
EOF
    sudo systemctl daemon-reload
    ok "Auto-login on TTY1 configured"

    # Disable any existing display manager
    for dm in sddm gdm lightdm lxdm; do
        if systemctl is-enabled "$dm" &>/dev/null 2>&1; then
            sudo systemctl disable "$dm" 2>/dev/null
            warn "Disabled display manager: $dm"
        fi
    done

    # Enable NetworkManager
    sudo systemctl enable NetworkManager 2>&1 | tee -a "$LOG_FILE"
    ok "NetworkManager enabled"

    # Enable Bluetooth
    sudo systemctl enable bluetooth 2>&1 | tee -a "$LOG_FILE"
    ok "Bluetooth service enabled"

    # Enable PipeWire
    systemctl --user enable pipewire pipewire-pulse wireplumber 2>&1 | tee -a "$LOG_FILE" || true
    ok "PipeWire audio services enabled"
}

# ── Phase 10: Fonts ───────────────────────────────────────────────────────
install_fonts() {
    section "Phase 10: Fonts"
    log "Checking for Courier Prime…"
    if fc-list | grep -qi "Courier Prime"; then
        ok "Courier Prime already installed"
    else
        paru -S --needed --noconfirm ttf-courier-prime 2>&1 | tee -a "$LOG_FILE" || \
            warn "ttf-courier-prime not found in AUR — install manually from https://fonts.google.com/specimen/Courier+Prime"
    fi
    fc-cache -fv 2>&1 | tee -a "$LOG_FILE"
    ok "Font cache refreshed"
}

# ── Phase 11: ZSH as Default Shell ────────────────────────────────────────
setup_zsh() {
    section "Phase 11: ZSH Default Shell"
    local zsh_path
    zsh_path=$(which zsh)
    if [ "$SHELL" = "$zsh_path" ]; then
        ok "zsh is already the default shell"
        return
    fi
    sudo chsh -s "$zsh_path" "$USER"
    ok "Default shell set to zsh"
}

# ── Phase 12: Deploy Configs ──────────────────────────────────────────────
deploy_configs() {
    section "Phase 12: Deploying Configs"

    # System data dirs
    sudo mkdir -p /etc/minimalos /var/lib/minimalos
    if [ ! -f /etc/minimalos/minimalos.conf ]; then
        sudo cp "$REPO_DIR/minimalos.conf.template" /etc/minimalos/minimalos.conf
        # Expand $HOME in the config
        sudo sed -i "s|\$HOME|$HOME|g" /etc/minimalos/minimalos.conf
        ok "System config installed to /etc/minimalos/minimalos.conf"
    else
        ok "System config already exists, skipping"
    fi

    # Wallpaper directory
    mkdir -p "$HOME/Pictures/Wallpapers"
    ok "Wallpaper directory created: ~/Pictures/Wallpapers"

    # Screenshots directory
    mkdir -p "$HOME/Pictures/Screenshots"

    # Deploy per-app configs
    declare -A config_map=(
        ["$REPO_DIR/configs/cwal"]="$HOME/.config/cwal"
        ["$REPO_DIR/configs/alacritty"]="$HOME/.config/alacritty"
        ["$REPO_DIR/configs/dunst"]="$HOME/.config/dunst"
        ["$REPO_DIR/configs/awesome"]="$HOME/.config/awesome"
        ["$REPO_DIR/configs/picom"]="$HOME/.config/picom"
        ["$REPO_DIR/configs/rofi"]="$HOME/.config/rofi"
    )

    for src in "${!config_map[@]}"; do
        local dst="${config_map[$src]}"
        mkdir -p "$dst"
        cp -rn "$src/." "$dst/" 2>/dev/null || true
        ok "Config deployed: $src → $dst"
    done

    # ZSH config
    if [ ! -f "$HOME/.zshrc" ]; then
        cp "$REPO_DIR/configs/zsh/.zshrc" "$HOME/.zshrc"
        ok ".zshrc installed"
    else
        warn ".zshrc already exists — manual merge may be needed"
        log "Reference config: $REPO_DIR/configs/zsh/.zshrc"
    fi

    # Deploy bin scripts to ~/.local/bin
    mkdir -p "$HOME/.local/bin"
    cp "$REPO_DIR/bin/"*.sh "$HOME/.local/bin/"
    cp "$REPO_DIR/bin/"*.py "$HOME/.local/bin/" 2>/dev/null || true
    chmod +x "$HOME/.local/bin/"SOS_*.sh
    chmod +x "$HOME/.local/bin/"SOS_*.py 2>/dev/null || true
    ok "Scripts installed to ~/.local/bin/"
}

# ── Phase 13: Initialize cwal ─────────────────────────────────────────────
init_cwal() {
    section "Phase 13: Initialize cwal"

    # Ensure cwal config dir exists
    mkdir -p "$HOME/.config/cwal" "$HOME/.cache/cwal"

    # Check for a default wallpaper to seed the color scheme
    local wall
    wall=$(find "$HOME/Pictures/Wallpapers" -type f \( -iname "*.png" -o -iname "*.jpg" \) | head -1)

    if [ -n "$wall" ]; then
        log "Initializing cwal with: $wall"
        cp "$wall" /var/lib/minimalos/current.png 2>/dev/null || sudo cp "$wall" /var/lib/minimalos/current.png
        echo "/var/lib/minimalos/current.png" | sudo tee /var/lib/minimalos/current_wallpaper > /dev/null
        cwal --img "$wall" --quiet 2>&1 | tee -a "$LOG_FILE" || \
            warn "cwal initialization failed — run manually after first login"
    else
        warn "No wallpaper found in ~/Pictures/Wallpapers"
        warn "Add wallpapers and run: cwal --img <wallpaper>"
    fi
}

# ── Phase 14: Limine Bootloader (optional) ────────────────────────────────
setup_limine() {
    section "Phase 14: Limine Bootloader (optional)"
    warn "Limine replaces your current bootloader. This is destructive if misconfigured."
    if ! ask "Install and configure Limine?"; then
        log "Skipping Limine — keeping current bootloader"
        return
    fi

    paru -S --needed --noconfirm limine 2>&1 | tee -a "$LOG_FILE"

    # Detect EFI or BIOS
    if [ -d /sys/firmware/efi ]; then
        log "UEFI system detected"
        local esp
        esp=$(findmnt -n -o TARGET /boot/efi 2>/dev/null || findmnt -n -o TARGET /boot 2>/dev/null || echo "/boot")
        log "ESP detected at: $esp"

        sudo limine bios-install "$esp" 2>/dev/null || true
        sudo cp /usr/share/limine/BOOTX64.EFI "$esp/EFI/BOOT/BOOTX64.EFI" 2>/dev/null || true

        # Get root partition UUID
        local root_uuid
        root_uuid=$(findmnt -n -o UUID / 2>/dev/null)
        local zen_vmlinuz
        zen_vmlinuz=$(ls /boot/vmlinuz-linux-zen 2>/dev/null | head -1)
        local zen_initrd
        zen_initrd=$(ls /boot/initramfs-linux-zen.img 2>/dev/null | head -1)

        cat > /tmp/limine.conf << EOF
timeout: 5

/MinimalOS (Zen Kernel)
    protocol: linux
    kernel_path: boot():/$(basename "$zen_vmlinuz")
    cmdline: root=UUID=${root_uuid} rw quiet splash loglevel=3
    module_path: boot():/$(basename "$zen_initrd")

/MinimalOS Fallback
    protocol: linux
    kernel_path: boot():/vmlinuz-linux
    cmdline: root=UUID=${root_uuid} rw
    module_path: boot():/initramfs-linux.img
EOF
        sudo cp /tmp/limine.conf "$esp/limine.conf"
        ok "Limine config written to $esp/limine.conf"
    else
        warn "BIOS system — Limine BIOS install requires knowing your disk."
        local disk
        echo -en "${Y}[ASK ]${N}  Enter your disk (e.g. /dev/sda): "
        read -r disk
        if [ -b "$disk" ]; then
            sudo limine bios-install "$disk" 2>&1 | tee -a "$LOG_FILE"
            ok "Limine BIOS installed to $disk"
        else
            err "Invalid disk: $disk — skipping Limine"
        fi
    fi

    warn "Review $esp/limine.conf before rebooting!"
}

# ── Phase 15: GameMode & Steam tweaks ─────────────────────────────────────
setup_gaming() {
    section "Phase 15: Gaming Setup"

    # Enable GameMode service
    systemctl --user enable gamemoded 2>/dev/null || true
    ok "GameMode service enabled"

    # Enable multilib if not already (needed for 32-bit gaming libs)
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        log "Enabling multilib repository…"
        sudo tee -a /etc/pacman.conf > /dev/null << 'MULTILIB'

[multilib]
Include = /etc/pacman.d/mirrorlist
MULTILIB
        sudo pacman -Sy 2>&1 | tee -a "$LOG_FILE"
        ok "multilib enabled"
    else
        ok "multilib already enabled"
    fi

    # Steam native runtime
    if ask "Configure Steam for native Linux runtime?"; then
        mkdir -p "$HOME/.steam/steam"
        ok "Steam directory created — configure runtime in Steam settings"
    fi

    # vm.max_map_count for some Windows games via Wine/Proton
    if ! grep -q "vm.max_map_count" /etc/sysctl.d/99-gaming.conf 2>/dev/null; then
        echo "vm.max_map_count = 2147483642" | sudo tee /etc/sysctl.d/99-gaming.conf
        sudo sysctl -p /etc/sysctl.d/99-gaming.conf 2>&1 | tee -a "$LOG_FILE"
        ok "vm.max_map_count configured for gaming"
    fi
}

# ── Sync Packages Only ────────────────────────────────────────────────────
sync_packages() {
    section "Syncing Packages from packages.conf"
    install_paru
    install_pacman_packages
    install_aur_packages
    ok "Package sync complete"
}

# ── Full Install ──────────────────────────────────────────────────────────
full_install() {
    preflight
    system_update
    install_paru
    install_zen_kernel
    install_pacman_packages
    install_aur_packages
    install_broot
    install_cwal
    install_gpu_drivers
    setup_awesome_autologin
    install_fonts
    setup_zsh
    deploy_configs
    init_cwal
    setup_gaming
    setup_limine

    section "Installation Complete"
    ok "MinimalOS installed successfully!"
    echo ""
    log "Next steps:"
    log "  1. Add wallpapers to ~/Pictures/Wallpapers"
    log "  2. Review /etc/minimalos/minimalos.conf"
    log "  3. Reboot — you will auto-login to AwesomeWM on TTY1"
    log "  4. Keybindings: Mod = Super (Windows key)"
    log "     Mod+Enter  → Alacritty terminal"
    log "     Mod+D      → App launcher"
    log "     Mod+P      → Control panel"
    log "     Mod+R      → Random wallpaper + cwal"
    log "     Mod+W      → Select wallpaper + cwal"
    log "     Mod+X      → Session menu"
    log ""
    log "Full log saved to: $LOG_FILE"
}

# ── Entry Point ───────────────────────────────────────────────────────────
case "${1:-}" in
    --sync-packages)
        sync_packages
        ;;
    --phase)
        case "${2:-}" in
            paru)       install_paru ;;
            zen)        install_zen_kernel ;;
            pacman)     install_pacman_packages ;;
            aur)        install_aur_packages ;;
            broot)      install_broot ;;
            cwal)       install_cwal ;;
            gpu)        install_gpu_drivers ;;
            awesome)    setup_awesome_autologin ;;
            fonts)      install_fonts ;;
            zsh)        setup_zsh ;;
            configs)    deploy_configs ;;
            gaming)     setup_gaming ;;
            limine)     setup_limine ;;
            *) err "Unknown phase: ${2:-}"; exit 1 ;;
        esac
        ;;
    --help|-h)
        echo "Usage: $0 [option]"
        echo ""
        echo "  (no args)         Full installation"
        echo "  --sync-packages   Install/update packages from packages.conf only"
        echo "  --phase <name>    Run a single phase:"
        echo "    paru zen pacman aur broot cwal gpu awesome fonts zsh configs gaming limine"
        ;;
    *)
        full_install
        ;;
esac
