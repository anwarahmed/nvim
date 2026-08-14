# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Keeping this file current — do this every time

**This file is part of the change, not a document written after it.** Before finishing any task in this repo, re-read the sections below and update whatever your change invalidated. A stale CLAUDE.md is worse than none, because the next agent will trust it.

Update it in the *same* commit as the code change. Specifically:

| If you changed... | Update |
| --- | --- |
| the Omarchy theme pipeline, the `theme.lua` symlink target, or `hooks/` | **Architecture → The Omarchy theme pipeline**, including any path that moved |
| `all-themes.lua`, or how theme plugins are discovered | **The Omarchy theme pipeline** — re-check every search path it scans |
| which directories `lazy.lua` imports, or added/removed a spec subdirectory | **How specs are discovered** |
| anything platform-specific, or the `is_omarchy()` guards | **Platform detection** — and re-test both paths with `NVIM_FORCE_OMARCHY` |
| how a change gets verified, or added a real linter/test runner | **Verifying changes** |
| formatter/linter/leader/branch conventions | **Conventions** |
| wired up, deleted, or committed anything under **Loose ends** | that entry — delete it once resolved |

Also correct any comment elsewhere in the repo that your change made untrue (e.g. `omarchy-loader.lua`'s header describes what `auto-theme.lua` sets up). Grep for the thing you removed before you finish.

If a change makes an instruction here wrong and you cannot fix it properly, say so explicitly in your final report rather than leaving it silently stale.

A `Stop` hook in `.claude/settings.json` backs this up: if `lua/` or `hooks/` is dirty while `CLAUDE.md` is untouched, it prints a reminder when the turn ends. It is a nudge, not a gate — a change that genuinely invalidates nothing here needs no edit, so judge rather than editing to silence it. It resolves its path via `$CLAUDE_PROJECT_DIR` and exits quietly if that is missing; the file is committed to a public repo, so keep hardcoded home directories out of it.

## What this is

A personal Neovim 0.12 configuration that lives at `~/.config/nvim` — the repo root *is* the runtime config directory, so every edit takes effect on the next `nvim` launch. There is no build step, no test suite, and no CI. "Testing a change" means starting Neovim and seeing whether it errors.

**One branch serves every machine.** The author runs a mix of Omarchy (Arch) and macOS boxes, so the config detects the platform at runtime rather than keeping a branch per platform — see **Platform detection** below. Do not reintroduce a platform branch; put the difference behind `is_omarchy()` instead.

See `README.md` for the external tool prerequisites (ripgrep, fd, tree-sitter-cli, lazygit, television, luarocks).

## Verifying changes

There is no test runner. Use headless Neovim to check that a change loads cleanly before declaring it done:

```bash
# Does the config start without errors? (exit non-zero / stderr output = broken)
nvim --headless -c 'qa!'

# Run something after full startup, including VimEnter autocmds
nvim --headless -c 'autocmd VimEnter * ++nested lua vim.defer_fn(function()
  print(vim.g.colors_name) vim.cmd("qa!") end, 1500)'

# Inspect a resolved highlight (useful for theme work)
nvim --headless -c 'lua print(vim.inspect(vim.api.nvim_get_hl(0, {name="Normal"})))' -c 'qa!'
```

Startup is slow (plugins install/update on first run), so give headless invocations a generous timeout.

Lua is formatted with stylua, configured by `lua/anwar/.stylua.toml` (2-space indent). stylua is not currently installed on this machine; match surrounding style by hand.

## Architecture

`init.lua` requires exactly two things: `anwar.core` (options then keymaps) and `anwar.lazy` (lazy.nvim bootstrap + setup). Everything else is reached through lazy.nvim's spec import.

### How specs are discovered — the part that trips people up

`lua/anwar/lazy.lua` imports **only** two modules:

```lua
{ import = "anwar.plugins" },
{ import = "anwar.plugins.lsp" }
```

lazy.nvim's `import` is **not recursive**. It picks up the `.lua` files sitting directly in `lua/anwar/plugins/`, plus those in `lua/anwar/plugins/lsp/` because that directory is named explicitly. Consequences:

- `lua/anwar/plugins/archive/` is **dead code** — never imported. It is a parking lot for specs that are kept for reference but not loaded. Moving a file there disables it; moving it back up one level re-enables it.
- `lua/anwar/plugins/omarchy/` is **not** imported either. It holds helper modules that are `require`d by hand.
- Adding a new plugin = drop a file returning a spec table into `lua/anwar/plugins/`. No registration step.
- Adding a new *subdirectory* of specs requires a matching `import` line in `lazy.lua`, or a top-level loader file that requires into it.

`lazy-lock.json` is gitignored, so plugin versions are deliberately not pinned across machines.

### Platform detection

`lua/anwar/platform.lua` exposes one function, `is_omarchy()`. It reports whether `~/.local/state/omarchy/current/theme` exists — deliberately the *precondition the theme pipeline needs*, not "is this Linux". A machine without it falls back to the portable colorscheme instead of failing at `VimEnter`.

Exactly two specs consult it, and each returns `{}` on the platform it does not serve:

| File | Active when | Provides |
| --- | --- | --- |
| `plugins/omarchy-loader.lua` | `is_omarchy()` | colorscheme follows the Omarchy system theme |
| `plugins/colorscheme.lua` | not `is_omarchy()` | self-contained onedark colorscheme |

The guard in `omarchy-loader.lua` sits **before** its `require` of `auto-theme`, so on a Mac none of the Omarchy machinery loads at all — no autocmds, no `:OmarchyReloadTheme`, no reads of the theme symlink. Keep it that way: anything with a side effect must stay below the guard.

Two overrides. `NVIM_FORCE_OMARCHY=1`/`=0` is the per-machine one — it needs no edit to a file shared with every other machine. `vim.g.force_omarchy = true/false` also works but **must be set before lazy.nvim collects specs**: `core/options.lua` is early enough, a `-c` argument is not. Set it later and `is_omarchy()` reports the new value while the specs were already chosen from the old one, which reads as the guards silently failing.

The env var is also how you test the other platform's path from either machine:

```bash
NVIM_FORCE_OMARCHY=0 nvim --headless -c 'autocmd VimEnter * ++nested lua vim.defer_fn(function()
  print(vim.g.colors_name) vim.cmd("qa!") end, 2000)'
```

Platform-specific leftovers on the other OS are inert by design: on a Mac `plugins/omarchy/theme.lua` is a dangling symlink that nothing requires, and `lua/config/remote_clipboard.lua` is unwired everywhere (see **Loose ends**).

### The Omarchy theme pipeline

This is the most involved part of the config and spans several files plus state outside the repo. **All of it is Omarchy-only** — everything below runs solely when `is_omarchy()` is true.

`lua/anwar/plugins/omarchy-loader.lua` is the single top-level entry point (hence the name — it sits at the importable level while its helpers live in the non-imported `omarchy/` subdirectory). It does two things: requires `omarchy/auto-theme.lua` for its side effects, and returns every colorscheme in `omarchy/all-themes.lua` as an eager spec (`lazy = false`, `priority = 1000`). They load eagerly so any theme can be swapped to at runtime without a plugin install.

`lua/anwar/plugins/omarchy/theme.lua` is a **symlink**, not a real file:

```
theme.lua -> ~/.local/state/omarchy/current/theme/neovim.lua
```

Omarchy owns the target. `omarchy theme set <name>` materializes the chosen theme into `~/.local/state/omarchy/current/theme/` by doing `rm -rf` + `mv`, so the target file gets a **new inode on every theme switch**. The symlink path stays stable; the file behind it does not. This is why the config does not watch the file — see below.

**Every theme names the colorscheme plugin it needs, and `omarchy/all-themes.lua` derives the install list from those declarations.** Omarchy themes are not self-contained: `solitude` asks for `ficcdaf/ashen.nvim`, `nord` for `EdenEast/nightfox.nvim`. Nothing else installs those, so a theme whose plugin is absent cannot be applied at all — the switch fails with `E185`.

`all-themes.lua` therefore reads each installed theme's `neovim.lua` at startup and collects the plugin it names, instead of carrying a hand-written list that went stale on every Omarchy upgrade. **Do not convert it back to a literal list.** Three subtleties it exists to handle:

- **Themes with no `neovim.lua` of their own.** Seven stock ones ship none; Omarchy renders `default/themed/neovim.lua.tpl` for them, which names `bjarneo/aether.nvim` on **branch `v3`**. No theme directory mentions that plugin, so the template is scanned as a source too — and `branch` is carried through, since aether's default branch is effectively a different plugin.
- **Near-misses.** The old hand list carried `sainnhe/everforest` and `shaunsingh/nord.nvim` while those themes actually want `neanias/everforest-nvim` and `EdenEast/nightfox.nvim`. A plausible-looking entry was never proof the theme worked.
- **`~/.local/share/omarchy` is a symlink to `/usr/share/omarchy`**, so those two search paths collapse to the same files. Harmless — results are deduplicated by repo.

Known gap: the derived specs deliberately carry no `opts`, and `apply_theme` only reads `opts.colorscheme`. For template-rendered themes the palette Omarchy injected into `opts` is therefore never applied, so all seven render in aether's default colors rather than their own.

Only a theme installed *after* Neovim started is still a problem — lazy.nvim resolves plugins at startup — and that case warns with the plugin name and resolves on restart.

`omarchy/auto-theme.lua` applies the theme on `VimEnter`/`ColorScheme`, re-applies transparency (`omarchy/transparency.lua`) and the alpha-nvim dashboard colors, and exposes `:OmarchyReloadTheme`. When no colorscheme in the spec applies, it warns with the theme name and the missing plugin — **do not make that path silent again**; it hid this exact bug behind an unchanged-looking editor. It reads the symlinked module as a lazy.nvim-style spec list and calls `spec.opts.colorscheme` — which may be a string *or* a function, since Omarchy themes sometimes drive an existing colorscheme engine with a remapped palette rather than shipping their own plugin.

Live theme switching is **pushed in from outside**, not detected from inside. `hooks/reload-neovim` is installed as an Omarchy `theme-set` hook and calls `:OmarchyReloadTheme` over each running instance's RPC socket:

```bash
omarchy hook install theme-set ~/.config/nvim/hooks/reload-neovim
```

Re-run that after editing the hook — `omarchy hook install` copies the file into `~/.config/omarchy/hooks/theme-set.d/`, it does not link it. Keep the repo copy as the source of truth.

An earlier version used a `vim.loop.new_fs_event` watcher on `theme.lua`. **Do not reintroduce one.** It cannot work: the `rm -rf` destroys the watched inode, so the watcher goes deaf after the first theme switch. The hook has no such failure mode.

`:OmarchyReloadTheme` is deliberately silent — the hook fires it in every open Neovim on every theme change, so a notification there is pure noise.

**Do not use `vim.g.colors_name` to check whether the Omarchy theme applied.** It names the *engine*, not the theme. Themes that ship their own plugin (Catppuccin, Gruvbox, Nord) set it to that plugin's name, but a theme with no plugin of its own drives an existing engine with a remapped palette — Andromeda calls `tokyonight.setup{ style = "moon", on_colors = ... }`, so `colors_name` reads `tokyonight-moon` even though Andromeda is correctly applied. Verify with `omarchy theme current`, or `~/.local/state/omarchy/current/theme.name`, or by comparing a highlight against the palette in the theme file:

```bash
# Andromeda: CursorLineNr should be #ffe66d, not stock tokyonight's #ff966c
nvim --headless -c 'autocmd VimEnter * ++nested lua vim.defer_fn(function()
  print(("#%06x"):format(vim.api.nvim_get_hl(0,{name="CursorLineNr"}).fg)) vim.cmd("qa!") end, 2000)'
```

## Conventions

- Work on a feature branch and open a PR against `main`; history shows every change landing as a merged PR. `main` is the only long-lived branch — `nvim-omarchy` is a retired platform branch kept as a fallback, so do not add to it.
- Anything that differs per machine goes behind `is_omarchy()` in a spec that returns `{}` on the other platform. Never fork the config into a platform branch again.
- Existing files carry explanatory comments about *why* a non-obvious approach was chosen. Match that — the config is read months later by its own author.
- Leader is `<space>`. Per-plugin keymaps are defined inside that plugin's spec (`keys`, `init`, or `config`), not centrally; only general-purpose maps live in `lua/anwar/core/keymaps.lua`.
- Formatting is conform.nvim with format-on-save; linting is nvim-lint on `BufEnter`/`BufWritePost`/`InsertLeave`. Adding a language means editing `formatters_by_ft` in `plugins/formatting.lua` and/or `linters_by_ft` in `plugins/linting.lua`, and ensuring the external formatter/linter binary is installed.

## Loose ends in the working tree

- `lua/config/remote_clipboard.lua` is **not written by hand and not wired up**. The Omarchy 4 ("Quattro") migration `1781587663.sh` copied it in from `/usr/share/omarchy-nvim/config/lua/config/remote_clipboard.lua`; the committed copy is byte-identical to Omarchy's. It defines `M.setup()` — an OSC 52 clipboard for tmux/SSH/herdr sessions that prefers the local Wayland clipboard for paste — but nothing calls it, so `vim.g.clipboard` is unset at runtime.

  It is orphaned because the migration's wiring step only fires when `lua/config/options.lua` exists (the LazyVim layout). This config keeps options at `lua/anwar/core/options.lua`, so the `require("config.remote_clipboard").setup()` line was never inserted, and the `lua/config/` path is Omarchy's convention rather than this repo's `anwar.*` namespace. To activate it, call `require("config.remote_clipboard").setup()` from `anwar.core`. A future Omarchy migration may overwrite this file — treat it as vendored, not authored.
