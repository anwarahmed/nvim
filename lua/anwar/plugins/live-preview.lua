return {
  "brianhuster/live-preview.nvim",
  dependencies = {
    -- You can choose one of the following pickers
    "nvim-telescope/telescope.nvim",
    -- "ibhagwan/fzf-lua",
    -- "echasnovski/mini.pick",
  },
  config = function(ev)
    local keymap = vim.keymap

    local opts = { buffer = ev.buf, silent = true }

    opts.desc = "Start live-preview server and open browser to preview the current buffer"
    keymap.set("n", "<leader>ps", "<cmd>LivePreview start<cr>", opts) -- start live-preview server and open browser to preview the current buffer

    opts.desc = "Stop live-preview server"
    keymap.set("n", "<leader>pc", "<cmd>LivePreview close<cr>", opts) -- stop live-preview server
  end,
}
