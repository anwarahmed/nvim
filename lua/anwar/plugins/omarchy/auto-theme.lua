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

-- Apply a colorscheme (function or string)
local function apply_colorscheme(colorscheme, silent)
  if type(colorscheme) == "function" then
    local ok, err = pcall(colorscheme)
    if not silent and not ok then
      vim.notify("Failed to apply custom colorscheme: " .. tostring(err), vim.log.levels.ERROR)
    end
  elseif type(colorscheme) == "string" then
    local ok, err = pcall(vim.cmd.colorscheme, colorscheme)
    if not silent and not ok then
      vim.notify("Failed to apply colorscheme '" .. colorscheme .. "': " .. tostring(err), vim.log.levels.ERROR)
    end
  end
end

-- Main theme application function
local function apply_theme()
  vim.o.background = 'dark'

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

  -- Apply colorscheme
  for _, spec in ipairs(theme_config) do
    if spec.dir then
      ensure_in_runtimepath(spec.dir)
    end
    if spec.opts and spec.opts.colorscheme then
      apply_colorscheme(spec.opts.colorscheme, true)
    end
  end

  -- Apply transparency and restore alpha colors
  restore_alpha_colors()
  apply_transparency()

  -- Re-enable events and redraw
  vim.o.eventignore = eventignore_old
  vim.cmd('redraw')
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
