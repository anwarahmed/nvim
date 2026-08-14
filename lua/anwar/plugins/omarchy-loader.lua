-- Omarchy auto-theme entry point.
--
-- This is the only spec lazy.nvim imports from the Omarchy setup; everything
-- under anwar/plugins/omarchy/ is a helper module required from here. It wires
-- up theme application and registers every selectable colorscheme plugin.

-- Off Omarchy there is no system theme to follow, so contribute nothing and let
-- plugins/colorscheme.lua take over. Bail before requiring auto-theme, whose
-- autocmds would otherwise try to read a theme file that does not exist here.
if not require("anwar.platform").is_omarchy() then
  return {}
end

-- Register the autocmds that apply the theme, plus the :OmarchyReloadTheme
-- command the theme-set hook calls. No plugin dependency, so it is safe to load
-- here as this spec module is collected (see auto-theme.lua).
require("anwar.plugins.omarchy.auto-theme")

local themes = require("anwar.plugins.omarchy.all-themes")

-- Load every theme eagerly so any colorscheme is ready for hot-reloading.
local specs = {}
for _, theme in ipairs(themes) do
  theme.lazy = false
  theme.priority = 1000
  specs[#specs + 1] = theme
end

return specs
