-- Omarchy Auto-Theme
-- Applies the current Omarchy theme, and re-applies it on demand without
-- restarting Neovim. Live theme switches arrive via the omarchy theme-set hook
-- in hooks/reload-neovim, which calls :OmarchyReloadTheme over the RPC socket.

-- Apply initial transparency immediately to prevent flicker on startup
vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })

-- State variables
local startup_applied = false

-- Where Omarchy materializes the selected theme's Neovim colorscheme. A theme
-- that does not theme Neovim simply has no file here.
local THEME_FILE = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")

-- Themes already complained about, so a switch to one that cannot be applied
-- is reported once rather than on every reload the theme-set hook triggers.
local warned = {}

-- Alpha-nvim color definitions
local ALPHA_COLORS = {
  Alphab = { fg = "#3399ff", ctermfg = 33 },
  Alphaa = { fg = "#53C670", ctermfg = 35 },
  Alphag = { fg = "#39ac56", ctermfg = 29 },
  Alphah = { fg = "#33994d", ctermfg = 23 },
  Alphai = { fg = "#33994d", bg = "#39ac56", ctermfg = 23, ctermbg = 29 },
  Alphaj = { fg = "#53C670", bg = "#33994d", ctermfg = 35, ctermbg = 23 },
  Alphak = { fg = "#30A572", ctermfg = 36 },
  Alphal = { fg = "#ec2160", ctermfg = 197, bold = true },
}

-- Restore alpha-nvim highlight groups
local function restore_alpha_colors()
  for name, hl in pairs(ALPHA_COLORS) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

-- Apply transparency settings
local function apply_transparency()
  local ok = pcall(require, "anwar.plugins.omarchy.transparency")
  if not ok then
    vim.notify("[Omarchy] Failed to load transparency settings", vim.log.levels.WARN)
  end
end

-- Add plugin directory to runtimepath if needed
local function ensure_in_runtimepath(plugin_dir)
  local expanded = vim.fn.expand(plugin_dir)
  local rtp_parts = vim.split(vim.o.runtimepath, ',')

  for _, path in ipairs(rtp_parts) do
    if path == expanded then
      return
    end
  end

  vim.opt.runtimepath:prepend(expanded)
end

-- Apply a colorscheme (function or string). Returns whether it took.
local function apply_colorscheme(colorscheme)
  if type(colorscheme) == "function" then
    return (pcall(colorscheme))
  elseif type(colorscheme) == "string" then
    return (pcall(vim.cmd.colorscheme, colorscheme))
  end
  return false
end

-- Name of the theme Omarchy currently has selected, for error messages.
local function current_theme_name()
  local ok, lines = pcall(vim.fn.readfile, vim.fn.expand("~/.local/state/omarchy/current/theme.name"))
  return (ok and lines[1]) or "unknown"
end

-- Main theme application function
local function apply_theme()
  vim.o.background = 'dark'

  -- Not every Omarchy theme themes Neovim -- several stock ones ship no
  -- neovim.lua, which leaves theme.lua dangling. That is a normal state, not a
  -- failure: keep whatever colorscheme is up and say so once, rather than
  -- raising a load error on every startup.
  if not (vim.uv or vim.loop).fs_stat(THEME_FILE) then
    local name = current_theme_name()
    if not warned[name] then
      warned[name] = true
      vim.notify(
        ("[Omarchy] Theme '%s' ships no Neovim colorscheme; keeping the current one."):format(name),
        vim.log.levels.WARN
      )
    end
    return
  end

  -- Reload theme configuration
  package.loaded["anwar.plugins.omarchy.theme"] = nil
  local ok, theme_config = pcall(require, "anwar.plugins.omarchy.theme")
  if not ok then
    vim.notify("Failed to load theme configuration: " .. tostring(theme_config), vim.log.levels.ERROR)
    return
  end

  -- Disable events during theme application to prevent flicker
  local eventignore_old = vim.o.eventignore
  vim.o.eventignore = "all"

  -- Apply colorscheme. An Omarchy theme names the colorscheme plugin it needs;
  -- if that plugin is not in all-themes.lua it was never installed, and the
  -- apply fails with E185. Track that so it surfaces instead of leaving the
  -- previous theme on screen with no explanation.
  local applied, wanted, plugin = false, nil, nil
  for _, spec in ipairs(theme_config) do
    if spec.dir then
      ensure_in_runtimepath(spec.dir)
    end
    if type(spec[1]) == "string" and spec[1] ~= "LazyVim/LazyVim" then
      plugin = spec[1]
    end
    if spec.opts and spec.opts.colorscheme then
      wanted = spec.opts.colorscheme
      applied = apply_colorscheme(spec.opts.colorscheme) or applied
    end
  end

  -- Apply transparency and restore alpha colors
  restore_alpha_colors()
  apply_transparency()

  -- Re-enable events and redraw
  vim.o.eventignore = eventignore_old
  vim.cmd('redraw')

  -- all-themes.lua derives its plugin list from the installed themes, so this
  -- normally only fires for a theme installed since Neovim started -- lazy.nvim
  -- resolves plugins at startup, so that one needs a restart.
  local name = current_theme_name()
  if wanted and not applied and not warned["plugin:" .. name] then
    warned["plugin:" .. name] = true
    vim.notify(
      ("[Omarchy] Theme '%s' needs the colorscheme %s (%s), which is not installed.\nRestart Neovim to pick it up.")
        :format(name, type(wanted) == "string" and ("'" .. wanted .. "'") or "<function>", plugin or "plugin unknown"),
      vim.log.levels.WARN
    )
  end
end

-- Apply theme when a colorscheme loads
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    if not startup_applied then
      startup_applied = true
      apply_theme()
    end
  end,
})

-- Apply theme on startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if not startup_applied then
      startup_applied = true
      apply_theme()
    end
  end,
})

-- Fallback: apply transparency if theme hasn't loaded yet
vim.api.nvim_create_autocmd("UIEnter", {
  callback = function()
    if not startup_applied then
      apply_transparency()
      restore_alpha_colors()
    end
  end,
})

-- Re-apply the current theme. Driven by the theme-set hook on every theme
-- switch, so it stays silent -- the colors changing is feedback enough.
vim.api.nvim_create_user_command("OmarchyReloadTheme", function()
  apply_theme()
end, { desc = "Reload the current Omarchy theme" })

return {}
