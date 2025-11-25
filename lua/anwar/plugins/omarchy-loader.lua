-- Omarchy auto-theme loader
-- This loads the auto-theme watcher during Neovim startup
return {
  {
    "LazyVim/LazyVim",
    -- Simple init function to load the auto-theme watcher
    -- This runs early during startup, before plugins are loaded
    init = function()
      require("anwar.plugins.omarchy.auto-theme")
    end,
  }
}
