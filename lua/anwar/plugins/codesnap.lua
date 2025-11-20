return {
  "mistricky/codesnap.nvim",
  build = "make",
  keys = {
    { "<leader>cc", "<cmd>CodeSnap<cr>", mode = "x", desc = "Save selected code snapshot into clipboard" },
    { "<leader>cs", "<cmd>CodeSnapSave<cr>", mode = "x", desc = "Save selected code snapshot in ~/Desktop" },
  },
  opts = {
    -- Custom settings:
    code_font_family = "MesloLGS Nerd Font Mono",
    watermark = "",
    bg_theme = "dusk",
    has_breadcrumbs = true,
    has_line_number = true,
    save_path = "~/Desktop",

    -- Default settings:
    -- mac_window_bar = true,
    -- title = "CodeSnap.nvim",
    -- code_font_family = "CaskaydiaCove Nerd Font",
    -- watermark_font_family = "Pacifico",
    -- watermark = "CodeSnap.nvim",
    -- bg_theme = "default", -- available themes: default, bamboo, sea, peach, grape, dusk, summer (see https://github.com/mistricky/codesnap.nvim?tab=readme-ov-file#custom-background)
    -- breadcrumbs_separator = "/",
    -- has_breadcrumbs = false,
    -- has_line_number = false,
    -- show_workspace = false,
    -- min_width = 0,
    -- bg_x_padding = 122,
    -- bg_y_padding = 82,
    -- save_path = os.getenv("XDG_PICTURES_DIR") or (os.getenv("HOME").. "/Pictures")
  },
}
