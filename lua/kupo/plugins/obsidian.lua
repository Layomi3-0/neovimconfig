return {
  "epwalsh/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  cmd = {
    "ObsidianOpen",
    "ObsidianNew",
    "ObsidianQuickSwitch",
    "ObsidianFollowLink",
    "ObsidianBacklinks",
    "ObsidianTags",
    "ObsidianToday",
    "ObsidianYesterday",
    "ObsidianTomorrow",
    "ObsidianDailies",
    "ObsidianTemplate",
    "ObsidianSearch",
    "ObsidianLink",
    "ObsidianLinkNew",
    "ObsidianLinks",
    "ObsidianExtractNote",
    "ObsidianWorkspace",
    "ObsidianPasteImg",
    "ObsidianRename",
    "ObsidianToggleCheckbox",
    "ObsidianNewFromTemplate",
    "ObsidianTOC",
  },
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",
    -- Optional, for completion.
    "hrsh7th/nvim-cmp",
    -- Optional, for picker support.
    "nvim-telescope/telescope.nvim",
    -- Optional, for syntax highlighting.
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("obsidian").setup({
      workspaces = {
        {
          name = "Kupo-brain",
          path = "~/Documents/Kupo-documents/Archives/Obsidian - Kupo-brain/Kupo-brain",
        },
      },

      -- Optional, set the log level
      log_level = vim.log.levels.INFO,

      -- Daily notes configuration
      daily_notes = {
        folder = "Archives/Daily notes",
        date_format = "%Y-%m-%d",
        alias_format = "%B %-d, %Y",
        default_tags = { "daily-notes" },
        template = nil,
      },

      -- Optional, completion of wiki links, local markdown links, and tags
      completion = {
        nvim_cmp = true,
        min_chars = 2,
      },

      -- Optional, configure key mappings
      mappings = {
        -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault
        ["gf"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
        -- Toggle check-boxes
        ["<leader>ch"] = {
          action = function()
            return require("obsidian").util.toggle_checkbox()
          end,
          opts = { buffer = true },
        },
        -- Smart action depending on context, either follow link or toggle checkbox
        ["<cr>"] = {
          action = function()
            return require("obsidian").util.smart_action()
          end,
          opts = { buffer = true, expr = true },
        },
      },

      -- Where to put new notes
      new_notes_location = "current_dir",

      -- Optional, customize how note IDs are generated
      note_id_func = function(title)
        -- Create note IDs from title if given, otherwise use timestamp
        local suffix = ""
        if title ~= nil then
          -- Transform title into valid file name
          suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        else
          -- Use timestamp if no title
          suffix = tostring(os.time())
        end
        return suffix
      end,

      -- Optional, customize wiki link format
      wiki_link_func = function(opts)
        return require("obsidian.util").wiki_link_id_prefix(opts)
      end,

      -- Preferred link style
      preferred_link_style = "wiki",

      -- Optional, disable frontmatter management
      disable_frontmatter = false,

      -- Optional, for templates (commented out - uncomment and set a valid folder path if you want to use templates)
      -- templates = {
      --   folder = "templates",
      --   date_format = "%Y-%m-%d",
      --   time_format = "%H:%M",
      -- },

      -- Optional, by default when you use `:ObsidianFollowLink` on a link to an external URL
      follow_url_func = function(url)
        vim.fn.jobstart({ "open", url }) -- Mac OS
      end,

      -- Optional, set to true if you use the Obsidian Advanced URI plugin
      use_advanced_uri = false,

      -- Optional, set to true to force ':ObsidianOpen' to bring the app to the foreground
      open_app_foreground = false,

      -- Configure picker (using telescope)
      picker = {
        name = "telescope.nvim",
        note_mappings = {
          new = "<C-x>",
          insert_link = "<C-l>",
        },
        tag_mappings = {
          tag_note = "<C-x>",
          insert_tag = "<C-l>",
        },
      },

      -- Sort search results
      sort_by = "modified",
      sort_reversed = true,

      -- Set the maximum number of lines to read from notes
      search_max_lines = 1000,

      -- How to open notes
      open_notes_in = "current",

      -- Optional, configure additional syntax highlighting / extmarks
      -- NOTE: requires 'conceallevel' set to 1 or 2 (set in core/options.lua)
      -- If you don't want these features, uncomment the line below:
      -- ui = { enable = false },
      ui = {
        enable = true,
        update_debounce = 200,
        max_file_length = 5000,
        checkboxes = {
          [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
          ["x"] = { char = "", hl_group = "ObsidianDone" },
          [">"] = { char = "", hl_group = "ObsidianRightArrow" },
          ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
          ["!"] = { char = "", hl_group = "ObsidianImportant" },
        },
        bullets = { char = "· ", hl_group = "ObsidianBullet" },  -- Smaller bullet with trailing space
        external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
        reference_text = { hl_group = "ObsidianRefText" },
        highlight_text = { hl_group = "ObsidianHighlightText" },
        tags = { hl_group = "ObsidianTag" },
        block_ids = { hl_group = "ObsidianBlockID" },
        hl_groups = {
          ObsidianTodo = { bold = true, fg = "#f78c6c" },
          ObsidianDone = { bold = true, fg = "#89ddff" },
          ObsidianRightArrow = { bold = true, fg = "#f78c6c" },
          ObsidianTilde = { bold = true, fg = "#ff5370" },
          ObsidianImportant = { bold = true, fg = "#d73128" },
          ObsidianBullet = { bold = true, fg = "#89ddff" },
          ObsidianRefText = { underline = true, fg = "#c792ea" },
          ObsidianExtLinkIcon = { fg = "#c792ea" },
          ObsidianTag = { italic = true, fg = "#89ddff" },
          ObsidianBlockID = { italic = true, fg = "#89ddff" },
          ObsidianHighlightText = { bg = "#75662e" },
        },
      },

      -- Specify how to handle attachments
      attachments = {
        img_folder = "assets/imgs",
        img_name_func = function()
          return string.format("%s-", os.time())
        end,
        img_text_func = function(client, path)
          path = client:vault_relative_path(path) or path
          return string.format("![%s](%s)", path.name, path)
        end,
      },
    })

    -- Set keymaps
    local keymap = vim.keymap

    keymap.set("n", "<leader>oo", "<cmd>ObsidianOpen<cr>", { desc = "Open note in Obsidian app" })
    keymap.set("n", "<leader>on", "<cmd>ObsidianNew<cr>", { desc = "Create new note" })
    keymap.set("n", "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", { desc = "Quick switch to note" })
    keymap.set("n", "<leader>of", "<cmd>ObsidianFollowLink<cr>", { desc = "Follow link under cursor" })
    keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<cr>", { desc = "Show backlinks" })
    keymap.set("n", "<leader>ot", "<cmd>ObsidianTags<cr>", { desc = "Search tags" })
    keymap.set("n", "<leader>od", "<cmd>ObsidianToday<cr>", { desc = "Open today's daily note" })
    keymap.set("n", "<leader>oy", "<cmd>ObsidianYesterday<cr>", { desc = "Open yesterday's daily note" })
    keymap.set("n", "<leader>om", "<cmd>ObsidianTomorrow<cr>", { desc = "Open tomorrow's daily note" })
    keymap.set("n", "<leader>os", "<cmd>ObsidianSearch<cr>", { desc = "Search notes" })
    keymap.set("v", "<leader>ol", "<cmd>ObsidianLink<cr>", { desc = "Link selection to note" })
    keymap.set("v", "<leader>oln", "<cmd>ObsidianLinkNew<cr>", { desc = "Link selection to new note" })
    keymap.set("n", "<leader>oli", "<cmd>ObsidianLinks<cr>", { desc = "List all links in note" })
    keymap.set("v", "<leader>oe", "<cmd>ObsidianExtractNote<cr>", { desc = "Extract selection to new note" })
    keymap.set("n", "<leader>ow", "<cmd>ObsidianWorkspace<cr>", { desc = "Switch workspace" })
    keymap.set("n", "<leader>op", "<cmd>ObsidianPasteImg<cr>", { desc = "Paste image from clipboard" })
    keymap.set("n", "<leader>or", "<cmd>ObsidianRename<cr>", { desc = "Rename note" })
    keymap.set("n", "<leader>otm", "<cmd>ObsidianTemplate<cr>", { desc = "Insert template" })
    keymap.set("n", "<leader>onf", "<cmd>ObsidianNewFromTemplate<cr>", { desc = "New note from template" })
    keymap.set("n", "<leader>otc", "<cmd>ObsidianTOC<cr>", { desc = "Show table of contents" })
  end,
}
