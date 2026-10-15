return {
  "OXY2DEV/markview.nvim",
  lazy = false, -- Important: Do not lazy load as the plugin is already optimized

  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },

  config = function()
    require("markview").setup({
      markdown = {
        list_items = {
          enable = true,
          indent_size = 1, -- Reduce indent (default is 2)
          shift_width = 2, -- Controls how much nested items shift
        },
      },
      markdown_inline = {
        checkboxes = {
          enable = true,
          checked = {
            text = "󰄲", -- Square with checkmark
            hl = "MarkviewCheckboxChecked",
            scope_hl = "MarkviewCheckboxCheckedText", -- Highlight for text after checkbox
          },
          unchecked = {
            text = "󰄱", -- Empty square
            hl = "MarkviewCheckboxUnchecked",
            scope_hl = "MarkviewCheckboxUncheckedText", -- Highlight for text after checkbox
          },
          pending = {
            text = "󰥔", -- Square with dash
            hl = "MarkviewCheckboxPending",
            scope_hl = "MarkviewCheckboxPendingText", -- Highlight for text after checkbox
          },
        },
      },
    })

    -- Define custom highlight groups for checkbox text
    vim.api.nvim_set_hl(0, "MarkviewCheckboxUncheckedText", { fg = "#f78c6c" }) -- Orange/red for uncompleted
    vim.api.nvim_set_hl(0, "MarkviewCheckboxCheckedText", { fg = "#98c379" }) -- Bright green for completed
    vim.api.nvim_set_hl(0, "MarkviewCheckboxPendingText", { fg = "#ffcb6b" }) -- Yellow for pending
  end,
}
