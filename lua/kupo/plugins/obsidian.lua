return {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",               -- For autocompletion
        "nvim-telescope/telescope.nvim",  -- For searching notes
        "nvim-treesitter/nvim-treesitter" -- For syntax highlighting
    },
    opts = {
        workspaces = {
            {
                name = "G-Obsidian",
                -- I pasted your exact path below:
                path = "/Users/lkupo/Library/CloudStorage/GoogleDrive-lkupo@google.com/My Drive/G-Obsidian",
            },
        },

        ui = {
            enable = false,
        },
        
        -- Optional: Configure completion behavior
        completion = {
            nvim_cmp = true,
            min_chars = 2,
        },
        
        -- Optional: Set daily notes to a specific folder inside your vault (e.g., "dailies")
        daily_notes = {
            folder = "dailies",
            date_format = "%Y-%m-%d",
        },
    }
}
