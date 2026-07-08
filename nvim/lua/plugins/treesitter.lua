return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local parsers = { "c", "lua", "vim", "vimdoc", "query", "javascript", "typescript", "python", "html", "css" }
      -- Install parsers asynchronously
      require("nvim-treesitter").install(parsers)

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(event)
          -- Enable treesitter highlighting for all filetypes (if parser is available)
          pcall(vim.treesitter.start, event.buf)
          -- Enable treesitter indentation
          vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
