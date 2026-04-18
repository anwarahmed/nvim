# neovim 0.12\*

https://neovim.io/

My NeoVim setup

Copy the contents of this repository to `~/.config/nvim`.
The following files can be ignored:

- `README.md`
- `.git`
- `.gitignore`

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
