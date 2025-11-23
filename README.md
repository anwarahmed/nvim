# neovim 0.11\*

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
brew install nvm
echo "lts/*" > ~/.nvmrc
brew install neovim
brew install fd
brew install ripgrep
brew install luarocks
brew install wget
brew install lazygit
brew install television
```

## ArchLinux / Omarchy

Install the following packages:

```shell
sudo pacman -S nvm # alternatively, run: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
echo "lts/*" > ~/.nvmrc
sudo pacman -S fd
sudo pacman -S ripgrep
sudo pacman -S luarocks
sudo pacman -S wget
sudo pacman -S lazygit
sudo pacman -S television
```
