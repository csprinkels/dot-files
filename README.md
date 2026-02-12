# dot-files

> Personal shell configuration and macOS bootstrap scripts — external-first workflow on a Thunderbolt NVMe drive named **WorkFlow**.

## Quick start

1. Plug in your external drive (default name: `WorkFlow`).
2. Clone this repo:

```bash
git clone https://github.com/sprinkels/dot-files.git ~/.dotfiles
cd ~/.dotfiles
```

3. Run the setup:

```bash
bash dev-setup.sh
```

### Preview first (dry run)

```bash
DRY_RUN=1 bash dev-setup.sh
```

Nothing is installed or moved — the script prints every action it *would* take.

## What lives where

| Location | Contents |
|---|---|
| **Internal SSD** | macOS, Homebrew (`/opt/homebrew`), Docker disk images |
| **External (`/Volumes/WorkFlow`)** | `Code/`, `Downloads/` (optional), `DevCache/`, `Apps/` (manual) |

The script creates `~/Code` as a symlink to the external drive and redirects npm, pnpm, yarn, pip, Cargo, Go, and XDG caches to `DevCache/`.

## Configuration

The script reads **`/Volumes/WorkFlow/workflow.env`** (created automatically on first run). Edit it to change behavior without touching the script:

```bash
CODE_DIR_NAME=Code        # name of the code folder on the external drive
MOVE_DOWNLOADS=0          # set to 1 to symlink ~/Downloads to external
INSTALL_SYNCTHING=0       # set to 1 to install Syncthing + GUI
```

Environment variables also work: `EXTERNAL_VOL_NAME=OtherDrive bash dev-setup.sh`

### Other flags (set as env vars)

| Variable | Default | Effect |
|---|---|---|
| `DRY_RUN` | `0` | Preview only, no changes |
| `INSTALL_WARP` | `0` | Install Warp AI terminal |
| `SET_MACOS_DEFAULTS` | `0` | Set default browser (Dia) + Dock prefs |

## What the script installs

- **Homebrew** + update/upgrade
- **Xcode CLI Tools**
- **Git** (configures if no `.gitconfig`)
- **Dev tools**: Cursor, Docker, GitHub Desktop
- **Package managers**: yarn, pnpm
- **NVM** (latest) + Node LTS + global npm packages
- **Nerd Fonts**: Meslo, JetBrains Mono, Fira Code
- **Shell tools**: fzf, ripgrep, fd, bat, jq, htop, gh, oh-my-posh, gitui, lazygit
- **Databases**: MySQL, PostgreSQL 15
- **Apps**: Raycast, Chrome, Spotify, CleanShot, Keka, AltTab, Bartender, etc.
- **Oh My Zsh** + custom `.zshrc` with aliases, NVM, Oh My Posh prompt
- **Syncthing** (optional) with `.stignore.template` for the Code folder

## Config files

| File | Destination |
|---|---|
| `config-files/.zshrc` | `~/.zshrc` (deployed after Oh My Zsh) |
| `config-files/.gitconfig` | `~/.gitconfig` |
| `config-files/sprinks.omp.json` | `~/.config/ohmyposh/sprinks.omp.json` |
| `config-files/cursor profile.code-profile` | Cursor settings, keybindings, extensions |

Existing files are backed up with a timestamp (e.g. `.zshrc.backup.20260211-143000`) before overwriting.

## Other scripts

| Script | Purpose |
|---|---|
| `scripts/uninstall-nix.sh` | Fully remove Nix package manager from macOS |

## Author

Maintained by [sprinkels](https://github.com/csprinkels).

## License

[MIT License](LICENSE)
