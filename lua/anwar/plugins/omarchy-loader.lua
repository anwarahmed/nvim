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

-- Add all theme plugins to the table and make them load immediately
for _, theme_spec in ipairs(all_themes) do
  -- Override lazy setting to ensure themes load on startup
  theme_spec.lazy = false
  table.insert(plugins, theme_spec)
end

return plugins
