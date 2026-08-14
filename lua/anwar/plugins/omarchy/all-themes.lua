-- Every Omarchy-selectable colorscheme plugin, derived from the themes that are
-- actually installed rather than hardcoded.
--
-- An Omarchy theme is not self-contained: its neovim.lua names the colorscheme
-- plugin it needs (solitude wants ficcdaf/ashen.nvim, nord wants
-- EdenEast/nightfox.nvim). Nothing else installs those, so a theme whose plugin
-- is absent cannot be applied at all -- the switch fails with E185 and
-- auto-theme.lua warns about it.
--
-- This list used to be maintained by hand, which meant every new or upgraded
-- theme silently broke until someone noticed and added its plugin. Reading the
-- declaration out of each theme instead keeps the two in step on their own,
-- and covers themes added later by `omarchy theme install` as well as by an
-- Omarchy upgrade.
--
-- The one thing this cannot do is react to a theme installed *after* Neovim
-- started: lazy.nvim resolves plugins at startup, so a genuinely new theme
-- needs one restart before it can be selected. auto-theme.lua's warning names
-- exactly which plugin is missing when that happens.
--
-- Only ever reached on Omarchy -- omarchy-loader.lua guards on is_omarchy().

-- Stock themes, then user themes, then two easily-missed sources:
--
--   * default/themed/neovim.lua.tpl -- Omarchy's fallback. Several stock themes
--     ship no neovim.lua of their own; for those Omarchy renders this template
--     with the theme's palette, so the plugin it names has to be installed even
--     though no theme directory mentions it. The template is valid Lua (its
--     {{ placeholders }} sit inside strings), so it reads like any theme.
--   * the materialized current theme -- catches whatever is selected right now
--     regardless of which of the above produced it.
--
-- A user theme overriding a stock slug is deduplicated below, first match wins.
local SEARCH_PATHS = {
  "/usr/share/omarchy/themes/*/neovim.lua",
  "~/.local/share/omarchy/themes/*/neovim.lua",
  "~/.config/omarchy/themes/*/neovim.lua",
  "/usr/share/omarchy/default/themed/neovim.lua.tpl",
  "~/.local/share/omarchy/default/themed/neovim.lua.tpl",
  "~/.local/state/omarchy/current/theme/neovim.lua",
}

local function theme_files()
  -- Expand only the leading `~`: vim.fn.glob() does not resolve it, while
  -- vim.fn.expand() would resolve the `*` too and hand back the matches
  -- newline-joined, which the following glob then finds nothing for.
  local home = vim.fn.expand("~")
  local files = {}

  for _, pattern in ipairs(SEARCH_PATHS) do
    local path = (pattern:gsub("^~", home))
    vim.list_extend(files, vim.fn.glob(path, false, true))
  end

  return files
end

local specs, seen = {}, {}

for _, file in ipairs(theme_files()) do
  -- A malformed or unreadable theme must not take the whole config down, so
  -- both loading and running the chunk are protected. A theme we cannot read
  -- simply contributes nothing, and only fails if it is the one selected.
  local chunk = loadfile(file)
  local ok, theme = pcall(chunk or function() end)

  if ok and type(theme) == "table" then
    for _, spec in ipairs(theme) do
      local repo = type(spec) == "table" and spec[1] or nil

      -- LazyVim is the carrier for `opts.colorscheme`, not a colorscheme
      -- plugin, and this config does not use it (see auto-theme.lua).
      if type(repo) == "string" and repo ~= "LazyVim/LazyVim" and not seen[repo] then
        seen[repo] = true
        -- Take only what identifies the plugin and pins what gets cloned --
        -- aether is declared on branch v3, and installing its default branch
        -- would be a different plugin in practice. Deliberately not the theme's
        -- opts/config: those are written against LazyVim's conventions, and
        -- auto-theme.lua applies the colorscheme itself.
        specs[#specs + 1] = { repo, name = spec.name, branch = spec.branch }
      end
    end
  end
end

return specs
