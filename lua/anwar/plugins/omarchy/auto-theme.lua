-- Omarchy Auto-Theme
-- Watches theme.lua and automatically applies theme changes without restarting Neovim

-- Apply initial transparency immediately to prevent flicker on startup
vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })

-- State variables
local theme_file = vim.fn.expand("~/.config/nvim/lua/anwar/plugins/omarchy/theme.lua")
local last_target = ""
local fs_event = nil
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

-- Set up filesystem watcher for theme changes
local function setup_watcher()
  if fs_event then
    return
  end

  last_target = vim.fn.resolve(theme_file)
  fs_event = vim.loop.new_fs_event()

  if not fs_event then
    vim.notify("[Omarchy] Failed to create fs_event watcher", vim.log.levels.ERROR)
    return
  end

  local ok, err = fs_event:start(theme_file, {}, vim.schedule_wrap(function(err, filename, events)
    if err then
      vim.notify("[Omarchy] Watcher error: " .. err, vim.log.levels.ERROR)
      return
    end

    local current_target = vim.fn.resolve(theme_file)
    if current_target ~= last_target then
      last_target = current_target
    end

    -- Wait for file to be fully written before applying
    vim.defer_fn(apply_theme, 200)
  end))

  if not ok then
    vim.notify("[Omarchy] Failed to start watcher: " .. (err or "unknown error"), vim.log.levels.ERROR)
    fs_event = nil
    return
  end

  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if fs_event then
        fs_event:stop()
        fs_event = nil
      end
    end,
  })
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

-- Apply theme on startup and set up file watcher
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if not startup_applied then
      startup_applied = true
      apply_theme()
    end
    setup_watcher()
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

-- Create a command to manually reload the theme for testing
vim.api.nvim_create_user_command("OmarchyReloadTheme", function()
  vim.notify("[Omarchy] Manual reload triggered", vim.log.levels.INFO)
  apply_theme()
end, { desc = "Manually reload Omarchy theme" })

return {}
