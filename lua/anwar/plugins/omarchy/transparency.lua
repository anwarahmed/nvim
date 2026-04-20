-- Helper function to make a highlight group transparent while preserving other attributes
local function make_transparent(group)
  local hl = vim.api.nvim_get_hl(0, { name = group })
  if hl then
    hl.bg = nil -- Remove background
    hl.ctermbg = nil -- Remove terminal background
    vim.api.nvim_set_hl(0, group, hl)
  end
end

-- transparent background
make_transparent("Normal")
make_transparent("NormalFloat")
make_transparent("FloatBorder")
make_transparent("Pmenu")
make_transparent("Terminal")
make_transparent("EndOfBuffer")
make_transparent("FoldColumn")
make_transparent("Folded")
make_transparent("SignColumn")
make_transparent("NormalNC")
make_transparent("WhichKeyFloat")
make_transparent("TelescopeBorder")
make_transparent("TelescopeNormal")
make_transparent("TelescopePromptBorder")
make_transparent("TelescopePromptTitle")

-- transparent background for neotree
make_transparent("NeoTreeNormal")
make_transparent("NeoTreeNormalNC")
make_transparent("NeoTreeVertSplit")
make_transparent("NeoTreeWinSeparator")
make_transparent("NeoTreeEndOfBuffer")

-- transparent background for nvim-tree
make_transparent("NvimTreeNormal")
make_transparent("NvimTreeVertSplit")
make_transparent("NvimTreeEndOfBuffer")

-- transparent notify background
make_transparent("NotifyINFOBody")
make_transparent("NotifyERRORBody")
make_transparent("NotifyWARNBody")
make_transparent("NotifyTRACEBody")
make_transparent("NotifyDEBUGBody")
make_transparent("NotifyINFOTitle")
make_transparent("NotifyERRORTitle")
make_transparent("NotifyWARNTitle")
make_transparent("NotifyTRACETitle")
make_transparent("NotifyDEBUGTitle")
make_transparent("NotifyINFOBorder")
make_transparent("NotifyERRORBorder")
make_transparent("NotifyWARNBorder")
make_transparent("NotifyTRACEBorder")
make_transparent("NotifyDEBUGBorder")
