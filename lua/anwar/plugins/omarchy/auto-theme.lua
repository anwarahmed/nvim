-- Auto-reload theme when theme.lua changes
-- This plugin watches the omarchy theme.lua file and automatically applies
-- theme changes without requiring a Neovim restart

local M = {}

local theme_file = vim.fn.expand("~/.config/nvim/lua/anwar/plugins/omarchy/theme.lua")
local last_modified = 0
local last_target = ""
local timer = nil

-- Debug: Print when module loads
vim.notify("[Omarchy Auto-Theme] Module loaded", vim.log.levels.DEBUG)

-- Function to restore alpha-nvim colors
local function restore_alpha_colors()
  -- Recreate alpha's highlight groups with the original colors
  local alpha_colors = {
    Alphab = { fg = "#3399ff", ctermfg = 33 },
    Alphaa = { fg = "#53C670", ctermfg = 35 },
    Alphag = { fg = "#39ac56", ctermfg = 29 },
    Alphah = { fg = "#33994d", ctermfg = 23 },
    Alphai = { fg = "#33994d", bg = "#39ac56", ctermfg = 23, ctermbg = 29 },
    Alphaj = { fg = "#53C670", bg = "#33994d", ctermfg = 35, ctermbg = 23 },
    Alphak = { fg = "#30A572", ctermfg = 36 },
    Alphal = { fg = "#ec2160", ctermfg = 197, bold = true },
  }

  for name, hl in pairs(alpha_colors) do
    vim.api.nvim_set_hl(0, name, hl)
  end
end

-- Function to load and apply the theme
local function apply_theme()
  -- Reset to dark mode before applying new theme
  vim.o.background = 'dark'

  -- Clear the module cache to force reload
  package.loaded["anwar.plugins.omarchy.theme"] = nil

  -- Load the theme configuration
  local ok, theme_config = pcall(require, "anwar.plugins.omarchy.theme")
  if not ok then
    vim.notify("Failed to load theme configuration: " .. tostring(theme_config), vim.log.levels.ERROR)
    return
  end

  -- First, check for local directory plugins and ensure they're loaded
  for _, spec in ipairs(theme_config) do
    if spec.dir then
      local plugin_dir = vim.fn.expand(spec.dir)

      -- Check if this directory is already in runtimepath
      local rtp_parts = vim.split(vim.o.runtimepath, ',')
      local in_rtp = false
      for _, path in ipairs(rtp_parts) do
        if path == plugin_dir then
          in_rtp = true
          break
        end
      end

      -- Add to runtimepath if not already there
      if not in_rtp then
        vim.opt.runtimepath:prepend(plugin_dir)
      end
    end
  end

  -- Now extract and apply the colorscheme
  for _, spec in ipairs(theme_config) do
    if spec.opts and spec.opts.colorscheme then
      local colorscheme = spec.opts.colorscheme

      -- Check if colorscheme is a function (custom theme)
      if type(colorscheme) == "function" then
        -- Execute the function to apply custom highlighting
        local status, err = pcall(colorscheme)
        if not status then
          vim.notify("Failed to apply custom colorscheme: " .. tostring(err), vim.log.levels.ERROR)
        else
          vim.notify("Theme reloaded successfully", vim.log.levels.INFO)
        end
      elseif type(colorscheme) == "string" then
        -- For plugin-based colorschemes, use Lazy's loader if available
        local has_lazy, lazy_loader = pcall(require, "lazy.core.loader")
        if has_lazy then
          -- Try to load the colorscheme plugin if it's lazy-loaded
          pcall(lazy_loader.load, { plugins = { colorscheme } })
        end

        -- Apply the colorscheme by name
        local status, err = pcall(vim.cmd.colorscheme, colorscheme)
        if not status then
          vim.notify("Failed to apply colorscheme '" .. colorscheme .. "': " .. tostring(err), vim.log.levels.ERROR)
        else
          vim.notify("Theme changed to: " .. colorscheme, vim.log.levels.INFO)
        end
      end
    end
  end

  -- Restore alpha-nvim colors and apply transparency after theme application
  vim.defer_fn(function()
    restore_alpha_colors()

    -- Apply transparency settings from transparency.lua
    local transparency_ok, _ = pcall(require, "anwar.plugins.omarchy.transparency")
    if not transparency_ok then
      vim.notify("[Omarchy Auto-Theme] Failed to load transparency settings", vim.log.levels.WARN)
    end
  end, 50)
end

-- Set up timer-based file watcher (polls every second)
local function setup_watcher()
  if timer then
    vim.notify("[Omarchy Auto-Theme] Watcher already running", vim.log.levels.WARN)
    return
  end

  local watch_file = vim.fn.expand(theme_file)

  -- Get initial state (both symlink target and modification time)
  local stat = vim.loop.fs_stat(watch_file)
  if stat then
    last_modified = stat.mtime.sec
    last_target = vim.fn.resolve(watch_file)
    vim.notify("[Omarchy Auto-Theme] Watching: " .. watch_file, vim.log.levels.INFO)
    vim.notify("[Omarchy Auto-Theme] Target: " .. last_target, vim.log.levels.DEBUG)
  else
    vim.notify("[Omarchy Auto-Theme] Failed to stat file: " .. watch_file, vim.log.levels.ERROR)
    return
  end

  -- Create timer that checks file every second
  timer = vim.loop.new_timer()
  timer:start(1000, 1000, vim.schedule_wrap(function()
    -- Check both if the symlink target changed OR if the file was modified
    local current_target = vim.fn.resolve(watch_file)
    local current_stat = vim.loop.fs_stat(watch_file)

    local target_changed = current_target ~= last_target
    local file_modified = current_stat and current_stat.mtime.sec > last_modified

    if target_changed or file_modified then
      if target_changed then
        vim.notify("[Omarchy Auto-Theme] Symlink target changed: " .. current_target, vim.log.levels.INFO)
        last_target = current_target
      end
      if file_modified then
        vim.notify("[Omarchy Auto-Theme] File modification detected!", vim.log.levels.INFO)
        last_modified = current_stat.mtime.sec
      end

      -- Wait a bit for the file to be fully written
      vim.defer_fn(function()
        apply_theme()
      end, 200)
    end
  end))

  -- Clean up on exit
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if timer then
        timer:stop()
        timer:close()
        timer = nil
      end
    end,
  })
end

-- Track if we've applied the theme on startup
local startup_applied = false

-- Set up the watcher after Neovim has fully started
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.notify("[Omarchy Auto-Theme] Setting up file watcher...", vim.log.levels.INFO)

    -- Set up the watcher for future changes
    setup_watcher()
  end,
})

-- Apply Omarchy theme after any colorscheme loads (including onedark)
-- This ensures Omarchy theme always takes precedence
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    if not startup_applied then
      -- Wait a bit to ensure the colorscheme has fully loaded
      vim.defer_fn(function()
        vim.notify("[Omarchy Auto-Theme] Applying Omarchy theme...", vim.log.levels.INFO)
        startup_applied = true
        apply_theme()
      end, 100)
    end
  end,
})

-- Create a command to manually reload the theme for testing
vim.api.nvim_create_user_command("OmarchyReloadTheme", function()
  vim.notify("[Omarchy Auto-Theme] Manual reload triggered", vim.log.levels.INFO)
  apply_theme()
end, { desc = "Manually reload Omarchy theme" })

-- Return empty table for Lazy.nvim compatibility (won't load LazyVim)
return {}
