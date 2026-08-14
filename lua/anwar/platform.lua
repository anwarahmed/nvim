-- Which machine is this?
--
-- The config runs on both Omarchy (Arch) and macOS boxes from a single branch.
-- Only the colorscheme differs: on Omarchy it follows the system theme (see
-- plugins/omarchy-loader.lua), everywhere else it is a self-contained
-- colorscheme (see plugins/colorscheme.lua). Each of those guards itself with
-- `is_omarchy()` and returns no specs on the other platform.

local M = {}

-- Where Omarchy 4+ materializes the active theme. This is the precondition
-- the theme pipeline actually needs -- not merely "is Arch" or "is Linux" --
-- so a machine without it falls back to the portable colorscheme instead of
-- failing at VimEnter.
local OMARCHY_THEME_DIR = "~/.local/state/omarchy/current/theme"

local detected = nil

---Is this an Omarchy machine with a usable theme?
---
---Two overrides, for the case where detection guesses wrong on some machine:
---
---  * `NVIM_FORCE_OMARCHY=1` / `=0` in the environment. Prefer this per machine
---    — it needs no edit to a file that is shared with every other machine.
---  * `vim.g.force_omarchy = true/false`, which MUST be set before lazy.nvim
---    collects specs (core/options.lua is early enough; a `-c` argument is not).
---    Set it later and this returns the new value while the specs were already
---    chosen from the old one, which looks like the guards silently failing.
---@return boolean
function M.is_omarchy()
  if type(vim.g.force_omarchy) == "boolean" then
    return vim.g.force_omarchy
  end

  local env = vim.env.NVIM_FORCE_OMARCHY
  if env and env ~= "" then
    return env ~= "0"
  end

  if detected == nil then
    local uv = vim.uv or vim.loop
    detected = uv.fs_stat(vim.fn.expand(OMARCHY_THEME_DIR)) ~= nil
  end

  return detected
end

return M
