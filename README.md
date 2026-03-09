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
| **Internal SSD** | macOS, Homebrew (`/opt/homebrew`), Docker disk images, all apps |
| **External (`/Volumes/WorkFlow`)** | `Developer/`, `Assets/`, `Creative/`, `Documents/`, `Downloads/` (backup), `Hardware/`, `DevCache/` |

The script creates `~/Developer` as a symlink to the external drive and redirects npm, pnpm, yarn, pip, Cargo, Go, and XDG caches to `DevCache/`.

## Configuration

The script reads **`/Volumes/WorkFlow/workflow.env`** (created automatically on first run). Edit it to change behavior without touching the script:

```bash
CODE_DIR_NAME=Developer   # name of the code folder on the external drive
```

Environment variables also work: `EXTERNAL_VOL_NAME=OtherDrive bash dev-setup.sh`

### Other flags (set as env vars)

| Variable | Default | Effect |
|---|---|---|
| `DRY_RUN` | `0` | Preview only, no changes |
| `SET_MACOS_DEFAULTS` | `0` | Set default browser (Dia) + Dock prefs |

## What the script installs

- **Homebrew** + update/upgrade
- **Xcode CLI Tools**
- **Git** (configures if no `.gitconfig`)
- **Dev tools**: VS Code, Docker, GitHub Desktop, Warp
- **Package managers**: yarn, pnpm
- **NVM** (latest) + Node LTS + global npm packages
- **Nerd Fonts**: Meslo, JetBrains Mono, Fira Code
- **Shell tools**: fzf, ripgrep, fd, bat, jq, htop, gh, oh-my-posh, gitui, lazygit
- **Databases**: MySQL, PostgreSQL 15
- **Oh My Zsh** + custom `.zshrc` with aliases, NVM, Oh My Posh prompt
- **Downloads sync**: weekly Friday backup of `~/Downloads` to external with auto file-type sorting

## VS Code setup

The script installs a custom **One Dark Catppuccin** theme (One Dark Pro UI + Catppuccin Frappe syntax + blue `#8caaee` accent), the Symbols icon theme, and these extensions:

| Extension | Purpose |
|---|---|
| `anthropic.claude-code` | Claude Code |
| `miguelsolorio.symbols` | Symbols icon theme |
| `esbenp.prettier-vscode` | Prettier formatter |
| `dbaeumer.vscode-eslint` | ESLint |
| `eamodio.gitlens` | Git history/blame |
| `usernamehw.errorlens` | Inline errors/warnings |
| `christian-kohler.path-intellisense` | Path autocomplete |
| `bradlc.vscode-tailwindcss` | Tailwind CSS IntelliSense |
| `ms-azuretools.vscode-docker` | Docker |
| `swiftlang.swift-vscode` | Swift |
| `angular.ng-template` | Angular template IntelliSense |
| `formulahendry.auto-rename-tag` | Auto-rename HTML/JSX tags |
| `meganrogge.template-string-converter` | Auto template literal conversion |
| `streetsidesoftware.code-spell-checker` | Spell checker |

## Config files

| File | Destination |
|---|---|
| `config-files/.zshrc` | `~/.zshrc` (deployed after Oh My Zsh) |
| `config-files/.gitconfig` | `~/.gitconfig` |
| `config-files/sprinks.omp.json` | `~/.config/ohmyposh/sprinks.omp.json` |
| `config-files/vscode/settings.json` | VS Code user settings |
| `config-files/vscode/extensions.json` | VS Code extension list |
| `config-files/vscode/themes/onedark-catppuccin/` | Custom VS Code color theme |

Existing files are backed up with a timestamp (e.g. `.zshrc.backup.20260211-143000`) before overwriting.

## Other scripts

| Script | Purpose |
|---|---|
| `scripts/downloads-sync.sh` | Rsync `~/Downloads` to external + sort by file type (Images, Documents, Videos, Audio, Archives, Code, 3D_Printing, Game_Assets, Game_ROMs, Hardware, Installers) |
| `scripts/com.sprinkels.downloads-sync.plist` | launchd plist — runs downloads sync every Friday at noon |
| `scripts/uninstall-nix.sh` | Fully remove Nix package manager from macOS |

## Author

Maintained by [sprinkels](https://github.com/csprinkels).

## License

[MIT License](LICENSE)
