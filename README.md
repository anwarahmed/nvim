# neovim 0.12\*

https://neovim.io/

My NeoVim setup

The same config runs on both macOS and [Omarchy](https://omarchy.org/) (Arch
Linux); it detects which at startup. On Omarchy the colorscheme follows the
system theme, and everywhere else it uses a self-contained one — no per-machine
edits and no separate branch. Install the packages for your platform below.

Copy the contents of this repository to `~/.config/nvim`.
The following files can be ignored:

- `README.md`
- `.git`
- `.gitignore`
- `CLAUDE.md` (notes for AI coding agents)

## macOS Homebrew

Install the following packages:

```shell
brew install rust
cargo install tree-sitter-cli # make sure to add cargo's bin directory to your PATH, e.g., export PATH="$HOME/.cargo/bin:$PATH"
brew install nvm
echo "lts/*" > ~/.nvmrc
brew install neovim
brew install fd
brew install ripgrep
brew install luarocks
brew install wget
brew install lazygit
brew install television
brew install tree-sitter
```

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

On Omarchy the colorscheme follows whichever theme the system is set to. That
works out of the box on startup, but picking up a theme change in an *already
running* Neovim needs a one-time hook install:

```shell
omarchy hook install theme-set ~/.config/nvim/hooks/reload-neovim
```

`omarchy theme set <name>` then reloads every open Neovim. Without the hook you
can still reload by hand with `:OmarchyReloadTheme`.

None of this loads on macOS. If detection ever guesses wrong on a machine, pin
it with `NVIM_FORCE_OMARCHY=1` (or `=0`) in the environment.

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
