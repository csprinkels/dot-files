# dot-files

![macOS Setup](https://img.shields.io/badge/macOS-Setup-Success-brightgreen)

> Repository containing my personal shell configuration and macOS automation scripts to streamline the setup of a new machine.

## Table of Contents

- [Overview](#overview)
- [Directory Structure](#directory-structure)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration Files](#configuration-files)
- [Contributing](#contributing)
- [Author](#author)
- [License](#license)

## Overview

This repository stores all my dotfiles, config files, and a setup script to configure a brand-new macOS environment in minutes. It includes:

- Shell (bash/zsh) settings
- Git configuration
- Vim/Neovim setup
- Tmux preferences
- And more...

## Directory Structure

```bash
.
├── config-files/         # Individual configuration directories
│   ├── bash/             # Bashrc, profile, aliases
│   ├── git/              # .gitconfig, .gitignore
│   └── vim/              # vimrc, plugin configs
├── new-mac-setup.sh      # Automated Homebrew and app installer
└── README.md             # This documentation
```

## Installation

1. Clone this repository:
```bash
git clone https://github.com/sprinkels/dot-files.git ~/.dotfiles
cd ~/.dotfiles
```
2. Run the macOS setup script:
```bash
bash new-mac-setup.sh
```

## Usage

- To update your dotfiles locally, modify the files under `config-files/` and re-run your symlinking tool.
- To apply changes to a remote machine, pull the latest repo and re-execute `new-mac-setup.sh`.

## Configuration Files

| Directory     | Description                         |
|---------------|-------------------------------------|
| `bash/`       | Shell aliases, environment exports  |
| `git/`        | Global Git settings                 |
| `vim/`        | Vim/Neovim configuration            |
| `tmux/`       | Tmux sessions and key bindings      |

## Contributing

Contributions welcome! Feel free to open issues or submit pull requests.

## Author

Maintained by [sprinkels](https://github.com/sprinkels).

## License

This repository is licensed under the [MIT License](LICENSE).
