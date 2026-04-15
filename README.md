# MinimalOS
Minimal OS for Gaming and Working — built on Arch Linux + AwesomeWM.

---

## Requirements

- Arch Linux base install
- Regular user with `sudo` access
- Active internet connection

---

## Install Script

```
./install.sh [option]
```

### Full installation (no arguments)

```bash
./install.sh
```

Runs every phase in order:

| Phase | What it does |
|-------|-------------|
| Pre-flight | Checks for Arch Linux, non-root user, sudo, internet |
| 1 – System update | Updates keyring and full system, enables multilib |
| 2 – paru | Installs the AUR helper |
| 3 – Zen kernel | Installs `linux-zen` and headers |
| 4 – Pacman packages | Installs all packages from `[pacman]` in `packages.conf` |
| 5 – AUR packages | Installs all packages from `[aur]` in `packages.conf` |
| 6 – broot | Builds broot with clipboard support via Cargo |
| 7 – cwal | Installs the color theming tool |
| 8 – GPU drivers | Detects GPU and asks whether to install NVIDIA / AMD / Intel drivers |
| 9 – AwesomeWM + auto-login | Creates `.xinitrc`, configures TTY1 auto-login, enables services |
| 10 – Fonts | Installs Courier Prime and refreshes font cache |
| 11 – ZSH | Sets ZSH as the default shell |
| 12 – Configs | Deploys all dotfiles to `~/.config/` and scripts to `~/.local/bin/` |
| 13 – cwal init | Generates color scheme from the first wallpaper found in `~/Pictures/Wallpapers` |
| 14 – Gaming | Enables GameMode, tunes `vm.max_map_count` for Wine/Proton |

---

### Sync packages only

```bash
./install.sh --sync-packages
```

Installs or updates packages from `packages.conf` without touching any other configuration. Useful after adding new packages to the list.

---

### Run a single phase

```bash
./install.sh --phase <name>
```

Available phase names:

| Name | What it runs |
|------|-------------|
| `paru` | Install paru AUR helper |
| `zen` | Install Zen kernel |
| `pacman` | Enable multilib + install pacman packages |
| `aur` | Install AUR packages |
| `broot` | Build and install broot |
| `cwal` | Install cwal |
| `gpu` | GPU driver detection and install |
| `awesome` | AwesomeWM + auto-login setup |
| `fonts` | Font install and cache refresh |
| `zsh` | Set ZSH as default shell |
| `configs` | Deploy dotfiles and scripts |
| `gaming` | Gaming tweaks (GameMode, vm.max_map_count) |

Example — redeploy configs after a change:

```bash
./install.sh --phase configs
```

Example — reinstall GPU drivers:

```bash
./install.sh --phase gpu
```

---

### Help

```bash
./install.sh --help
```

---

## Post-install

1. Add wallpapers to `~/Pictures/Wallpapers`
2. Review `/etc/minimalos/minimalos.conf`
3. Reboot — you will auto-login to AwesomeWM on TTY1

### Keybindings

| Shortcut | Action |
|----------|--------|
| `Mod + Enter` | Alacritty terminal |
| `Mod + D` | App launcher |
| `Mod + P` | Control panel |
| `Mod + R` | Random wallpaper + cwal |
| `Mod + W` | Select wallpaper + cwal |
| `Mod + X` | Session menu |

> `Mod` = Super (Windows key)

---

## Customising packages

Edit `packages.conf` and add package names under the `[pacman]` or `[aur]` sections, then run:

```bash
./install.sh --sync-packages
```

Lines beginning with `#` are treated as comments and ignored.
