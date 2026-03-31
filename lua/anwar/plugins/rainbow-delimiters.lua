return {
  "HiPhish/rainbow-delimiters.nvim",
  config = function()
    require("rainbow-delimiters.setup").setup({
      condition = function(bufnr)
        local ft = vim.bo[bufnr].filetype
        if ft == "alpha" or ft == "" then
          return false
        end
        local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
        return ok and parser ~= nil
      end,
    })
  end,
}
