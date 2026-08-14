-- Every Omarchy-selectable colorscheme plugin.
-- Registered here as bare specs; omarchy-loader.lua decides how they load
-- (eagerly, so any theme is ready for hot-reloading — see auto-theme.lua).
--
-- This list must cover the plugin every installed Omarchy theme names in its
-- own neovim.lua. A theme whose plugin is missing cannot be applied at all:
-- the switch fails with E185 and auto-theme.lua warns about it. Re-audit after
-- an Omarchy upgrade adds themes, since the sets drift apart silently:
--
--   for f in /usr/share/omarchy/themes/*/neovim.lua; do
--     grep -oE '"[^"]+/[^"]+"' "$f" | grep -v LazyVim | head -1
--   done | sort -u
return {
  { "ribru17/bamboo.nvim" },
  { "bjarneo/aether.nvim" },
  { "bjarneo/ethereal.nvim" },
  { "bjarneo/hackerman.nvim" },
  { "catppuccin/nvim", name = "catppuccin" },
  { "sainnhe/everforest" },
  { "kepano/flexoki-neovim" },
  { "ellisonleao/gruvbox.nvim" },
  { "rebelot/kanagawa.nvim" },
  { "tahayvr/matteblack.nvim" },
  { "loctvl842/monokai-pro.nvim" },
  { "shaunsingh/nord.nvim" },
  { "rose-pine/neovim", name = "rose-pine" },
  { "folke/tokyonight.nvim" },

  -- Themes Omarchy ships that the list above did not cover. The everforest and
  -- nord entries above are for different plugins than those themes actually
  -- name, so both spellings have to be present.
  { "ficcdaf/ashen.nvim" }, -- solitude
  { "neanias/everforest-nvim" }, -- everforest
  { "omacom-io/lumon.nvim" }, -- lumon
  { "EdenEast/nightfox.nvim" }, -- nord
  { "OldJobobo/retro-82.nvim" }, -- retro-82
}
