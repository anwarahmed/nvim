return {
  "yorickpeterse/nvim-jump",
  config = function()
    require("jump").setup({
      labels = "fdsaghjklrewqtyuiopvcxzbnm",
      search = "Search",
      label = "FlashLabel",
    })

    vim.keymap.set({ "n", "x", "o" }, "s", require("jump").start, { desc = "Jump" })
  end,
}
