return {
  "alexpasmantier/tv.nvim",
  config = function()
    require("tv").setup({
      keybindings = {
        files = "<C-p>", -- or false to disable
        text = "<leader><leader>",
        channels = "<leader>tv", -- channel selector
        files_qf = "<C-q>", -- quickfix binding (inside tv)
        text_qf = "<C-q>",
      },
      quickfix = {
        auto_open = true, -- auto-open quickfix window
      },
      window = {
        width = 0.8, -- 80% of editor
        height = 0.8,
        border = "rounded", -- none|single|double|rounded|solid|shadow
        title = " tv ",
      },
      files = {
        args = { "--preview-size", "70" },
        window = {}, -- override window config for files
      },
      text = {
        args = { "--preview-size", "70" },
        window = {}, -- override window config for text
      },
    })
  end,
}
