# dot-files

> Shell, prompt, and terminal setup for a headless Mac that's mostly used from the terminal.

## Quick start

```bash
git clone https://github.com/csprinkels/dot-files.git ~/dot-files
cd ~/dot-files
bash dev-setup.sh
```

### Preview first (dry run)

```bash
DRY_RUN=1 bash dev-setup.sh
```

Nothing is installed or moved. The script prints every action it *would* take.

## What `dev-setup.sh` does

- **Config files**: `.gitconfig`, the Oh My Posh theme, and the terminal config (below), each backed up with a timestamp before it's replaced
- **Homebrew** + update/upgrade, and **Xcode CLI Tools**
- **Everything in the [`Brewfile`](Brewfile)** via `brew bundle`:
  - **Terminal**: cmux, Nerd Fonts (JetBrains Mono, Meslo, Fira Code), oh-my-posh
  - **Shell tools**: fzf, ripgrep, fd, bat, jq, htop, gh, gitui, lazygit
  - **Dev**: git, yarn, pnpm, OrbStack (containers), GitHub Desktop
- **NVM** + Node LTS + global npm packages (typescript, next, eslint, prettier, nodemon, ts-node, Claude Code)
- **Oh My Zsh** + zsh-autosuggestions + zsh-syntax-highlighting, then the custom `.zshrc`

To add or remove an app or tool, edit the `Brewfile`. Run `brew bundle --file=Brewfile` on its own to install just those.

## Config files

| File | Destination |
|---|---|
| `config-files/.zshrc` | `~/.zshrc` (deployed after Oh My Zsh): aliases, NVM, Oh My Posh prompt, and tool caches on the Extended drive when it's plugged in |
| `config-files/.gitconfig` | `~/.gitconfig` |
| `config-files/sprinks.omp.json` | `~/.config/ohmyposh/sprinks.omp.json` |
| `config-files/terminal.conf` | `~/.config/ghostty/config`: font, colors, padding. cmux runs on Ghostty's engine and reads its config from there. |

Over SSH, the font and colors come from the terminal on the Mac you're typing on, so put the same `terminal.conf` there too. The prompt comes from this Mac's `.zshrc`.

## Other scripts

| Script | Purpose |
|---|---|
| `config-files/config.sh` | Copy `.gitconfig` and `.zshrc` back from `~/dotfiles` |
| `scripts/uninstall-nix.sh` | Fully remove the Nix package manager from macOS |

## Author

Maintained by [csprinkels](https://github.com/csprinkels).

## License

[MIT License](LICENSE)
