return {
  "img-paste-devs/img-paste.vim",
  ft = "markdown", -- Only load for markdown files
  config = function()
    -- Image directory configuration (relative to the markdown file)
    vim.g.mdip_imgdir = "img"
    vim.g.mdip_imgname = "image"

    -- Optional: Set absolute path for saving images (uncomment if needed)
    -- vim.g.mdip_imgdir_absolute = "/absolute/path/to/imgdir"
    -- vim.g.mdip_imgdir_intext = "/relative/path/to/imgdir"

    -- Keymap for pasting images in markdown files
    vim.keymap.set("n", "<leader>p", ":call mdip#MarkdownClipboardImage()<CR>", {
      buffer = true,
      silent = true,
      desc = "Paste image from clipboard",
    })
  end,
}
