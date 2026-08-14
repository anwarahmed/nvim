# neovim 0.12\*

https://neovim.io/

My NeoVim setup

> **This branch (`nvim-omarchy`) targets [Omarchy](https://omarchy.org/) on Arch Linux only.**
> It replaces the standalone colorscheme config with a theme pipeline driven by
> the active Omarchy theme, so it is not portable to other systems.
> For macOS or plain Linux, use the `main` branch instead.

Copy the contents of this repository to `~/.config/nvim`.
The following files can be ignored:

- `README.md`
- `.git`
- `.gitignore`
- `CLAUDE.md` and `.claude/` (notes and settings for AI coding agents)

## ArchLinux / Omarchy

Install the following packages:

```shell
sudo pacman -S rustup
rustup default stable
cargo install tree-sitter-cli
sudo pacman -S nvm # alternatively, run: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
echo "lts/*" > ~/.nvmrc
sudo pacman -S fd
sudo pacman -S ripgrep
sudo pacman -S luarocks
sudo pacman -S wget
sudo pacman -S lazygit
sudo pacman -S television
sudo pacman -S tree-sitter
```

## Omarchy theme integration

The colorscheme follows whichever theme Omarchy is set to. That works out of the
box on startup, but picking up a theme change in an *already running* Neovim
needs a one-time hook install:

```shell
omarchy hook install theme-set ~/.config/nvim/hooks/reload-neovim
```

`omarchy theme set <name>` then reloads every open Neovim. Without the hook you
can still reload by hand with `:OmarchyReloadTheme`.

## Upgrading from NeoVim 0.11

When upgrading from NeoVim 0.11, you may encounter issues with the `nvim-treesitter` plugin. To resolve this, follow these steps:

1. Remove the existing `tree-sitter` parser files:
   ```shell
   rm -rf ~/.config/local/share/nvim/tree-sitter-*-tmp
   ```
2. Open NeoVim and run the following commands to update the plugins and the `nvim-treesitter` parsers:
   ```vim
   :Lazy update all
   :TSUpdate
   ```
