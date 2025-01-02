return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")

    -- import mason-tool-installer
    local mason_tool_installer = require("mason-tool-installer")

    -- enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    mason_lspconfig.setup({
      -- list of servers for mason to install
      ensure_installed = {
        "csharp_ls",
        --"omnisharp",
        "ts_ls",
        "eslint",
        "html",
        "cssmodules_ls",
        "tailwindcss",
        "lua_ls",
      },
    })

    mason_tool_installer.setup({
      ensure_installed = {
        "csharpier", -- c# formatter
        "prettier", -- prettier formatter
        "stylua", -- lua formatter
        "eslint_d", -- js linter
      },
    })
  end,
}
