-- Omarchy auto-theme loader
-- This loads the auto-theme watcher and all theme plugins from all-themes.lua

-- Load all theme plugin specs from all-themes.lua
local all_themes = require("anwar.plugins.omarchy.all-themes")

-- Create a combined table with the auto-theme loader and all theme plugins
local plugins = {
  {
    "LazyVim/LazyVim",
    -- Load the auto-theme watcher
    init = function()
      require("anwar.plugins.omarchy.auto-theme")
    end,
  }
}

-- Determine active theme from theme.lua
local theme_file = vim.fn.expand("~/.config/nvim/lua/anwar/plugins/omarchy/theme.lua")
local active_colorscheme = nil

-- Parse theme.lua to find the active colorscheme
local ok, theme_config = pcall(dofile, theme_file)
if ok and type(theme_config) == "table" then
  for _, spec in ipairs(theme_config) do
    if spec.opts and spec.opts.colorscheme then
      active_colorscheme = spec.opts.colorscheme
      break
    end
  end
end

-- Add all theme plugins, but only load the active one immediately
for _, theme_spec in ipairs(all_themes) do
  -- Check if this theme matches the active colorscheme
  local theme_name = theme_spec.name or theme_spec[1]:match("([^/]+)%.nvim$") or theme_spec[1]:match("([^/]+)$")

  -- Only load the active theme immediately
  if active_colorscheme and theme_name == active_colorscheme then
    theme_spec.lazy = false
    theme_spec.priority = 1000
  else
    -- Keep others lazy (respecting their original setting)
    theme_spec.lazy = true
  end

  table.insert(plugins, theme_spec)
end

return plugins
