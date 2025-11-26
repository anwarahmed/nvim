-- Omarchy Auto-Theme
-- Watches theme.lua and automatically applies theme changes without restarting Neovim

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

  -- Check if this directory is already in runtimepath
  for _, path in ipairs(rtp_parts) do
    if path == expanded then
      return -- Already in runtimepath, nothing to do
    end
  end

  -- Add to runtimepath if not already there
  vim.opt.runtimepath:prepend(expanded)
end

-- Apply a colorscheme (function or string)
local function apply_colorscheme(colorscheme)
  -- Check if colorscheme is a function (custom theme like aetheria)
  if type(colorscheme) == "function" then
    -- Execute the function to apply custom highlighting
    local ok, err = pcall(colorscheme)
    if ok then
      vim.notify("Theme reloaded successfully", vim.log.levels.INFO)
    else
      vim.notify("Failed to apply custom colorscheme: " .. tostring(err), vim.log.levels.ERROR)
    end
  -- Check if colorscheme is a string (plugin-based theme like catppuccin, gruvbox, etc.)
  elseif type(colorscheme) == "string" then
    -- Apply the colorscheme by name
    local ok, err = pcall(vim.cmd.colorscheme, colorscheme)
    if ok then
      vim.notify("Theme changed to: " .. colorscheme, vim.log.levels.INFO)
    else
      vim.notify("Failed to apply colorscheme '" .. colorscheme .. "': " .. tostring(err), vim.log.levels.ERROR)
    end
  end
end

-- Main theme application function
local function apply_theme()
  -- Step 1: Reset to dark mode before applying new theme
  -- This ensures a consistent starting point for all themes
  vim.o.background = 'dark'

  -- Step 2: Clear module cache to force reload
  -- This ensures we get the latest theme configuration
  package.loaded["anwar.plugins.omarchy.theme"] = nil
  local ok, theme_config = pcall(require, "anwar.plugins.omarchy.theme")
  if not ok then
    vim.notify("Failed to load theme configuration: " .. tostring(theme_config), vim.log.levels.ERROR)
    return
  end

  -- Step 3: Process theme specs
  for _, spec in ipairs(theme_config) do
    -- First, check for local directory plugins and ensure they're loaded
    if spec.dir then
      ensure_in_runtimepath(spec.dir)
    end

    -- Then extract and apply the colorscheme
    if spec.opts and spec.opts.colorscheme then
      apply_colorscheme(spec.opts.colorscheme)
    end
  end

  -- Step 4: Post-processing after theme application
  -- Restore alpha-nvim colors and apply transparency settings
  vim.defer_fn(function()
    restore_alpha_colors()
    apply_transparency()
    -- Force a redraw to make changes visible immediately
    vim.cmd('redraw!')
  end, 50)
end

-- Set up filesystem event watcher using libuv
local function setup_watcher()
  if fs_event then
    vim.notify("[Omarchy] Watcher already running", vim.log.levels.WARN)
    return
  end

  -- Get initial symlink target
  last_target = vim.fn.resolve(theme_file)
  vim.notify("[Omarchy] Watching: " .. theme_file, vim.log.levels.INFO)

  -- Create filesystem event watcher
  fs_event = vim.loop.new_fs_event()
  if not fs_event then
    vim.notify("[Omarchy] Failed to create fs_event watcher", vim.log.levels.ERROR)
    return
  end

  -- Start watching the theme file for changes
  local ok, err = fs_event:start(theme_file, {}, vim.schedule_wrap(function(err, filename, events)
    if err then
      vim.notify("[Omarchy] Watcher error: " .. err, vim.log.levels.ERROR)
      return
    end

    -- Check if the symlink target changed
    local current_target = vim.fn.resolve(theme_file)
    local target_changed = current_target ~= last_target

    if target_changed then
      vim.notify("[Omarchy] Symlink target changed: " .. current_target, vim.log.levels.INFO)
      last_target = current_target
    else
      vim.notify("[Omarchy] File modification detected", vim.log.levels.INFO)
    end

    -- Wait a bit for the file to be fully written before applying
    vim.defer_fn(apply_theme, 200)
  end))

  if not ok then
    vim.notify("[Omarchy] Failed to start fs_event watcher: " .. (err or "unknown error"), vim.log.levels.ERROR)
    fs_event = nil
    return
  end

  -- Clean up watcher on Neovim exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if fs_event then
        fs_event:stop()
        fs_event = nil
      end
    end,
  })
end

-- Set up the watcher after Neovim has fully started
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.notify("[Omarchy] Setting up file watcher...", vim.log.levels.INFO)
    -- Set up the watcher for future theme changes
    setup_watcher()
  end,
})

-- Apply transparency after UI is ready
vim.api.nvim_create_autocmd("UIEnter", {
  callback = function()
    -- Use schedule to ensure this runs after everything else
    vim.schedule(function()
      apply_transparency()
      restore_alpha_colors()
      -- Force multiple redraws to ensure changes are visible
      vim.cmd('redraw!')
      vim.schedule(function()
        vim.cmd('redraw!')
      end)
    end)
  end,
})

-- Apply Omarchy theme after any colorscheme loads (including onedark)
-- This ensures Omarchy theme always takes precedence
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    if not startup_applied then
      -- Wait a bit to ensure the colorscheme has fully loaded
      vim.defer_fn(function()
        vim.notify("[Omarchy] Applying Omarchy theme...", vim.log.levels.INFO)
        startup_applied = true
        apply_theme()
      end, 100)
    end
  end,
})

-- Create a command to manually reload the theme for testing
vim.api.nvim_create_user_command("OmarchyReloadTheme", function()
  vim.notify("[Omarchy] Manual reload triggered", vim.log.levels.INFO)
  apply_theme()
end, { desc = "Manually reload Omarchy theme" })

return {}
