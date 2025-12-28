# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Neovim configuration codebase named "kupo". It uses lazy.nvim for plugin management and follows a modular architecture with clear separation between core settings and plugin configurations.

## Installation

Place this entire directory at `~/.config/nvim/`. Neovim will automatically load `init.lua` on startup.

## Architecture

### Entry Point and Loading Sequence

1. `init.lua` - Two-line entry point that loads in order:
   - `require("kupo.core")` - Core Neovim settings (options and keymaps)
   - `require("kupo.lazy")` - Plugin manager bootstrap

2. Core settings load **before** any plugins to ensure proper initialization

### Directory Structure

```
lua/kupo/
├── core/              # Core Neovim configuration
│   ├── init.lua      # Loads options.lua then keymaps.lua
│   ├── options.lua   # All vim.opt settings
│   └── keymaps.lua   # Global keymaps (leader = space)
├── lazy.lua          # Plugin manager bootstrap and setup
└── plugins/          # Individual plugin configurations
    ├── init.lua      # Base plugins (plenary, vim-tmux-navigator)
    ├── lsp/          # LSP-specific configs
    │   ├── mason.lua
    │   └── lspconfig.lua
    └── [32+ plugin files]
```

### Plugin Configuration Pattern

Each plugin file in `lua/kupo/plugins/` returns a lazy.nvim spec:

```lua
return {
  "author/plugin-name",
  event = "VeryLazy",        -- Lazy loading trigger
  dependencies = {...},      -- Plugin dependencies
  config = function()
    require("plugin").setup({...})
    -- Plugin-specific keymaps here
  end,
}
```

The `lua/kupo/lazy.lua` file imports plugins from two namespaces:
- `kupo.plugins` - General plugins
- `kupo.plugins.lsp` - LSP-related plugins (isolated for organization)

## Common Development Tasks

### Managing Plugins

**Add a new plugin:**
1. Create `lua/kupo/plugins/plugin-name.lua`
2. Return a lazy.nvim spec table
3. Restart Neovim - lazy.nvim auto-detects and installs

**Add an LSP-specific plugin:**
1. Create in `lua/kupo/plugins/lsp/` subdirectory
2. Same pattern as above

**Update plugins:**
- Open Neovim and run `:Lazy update`
- Plugin versions are locked in `lazy-lock.json`

**Check plugin status:**
- Run `:Lazy` to open the lazy.nvim UI
- Shows installed, loaded, and available updates

### Modifying Configuration

**Add global keymaps:**
- Edit `lua/kupo/core/keymaps.lua`
- Use format: `vim.keymap.set("n", "<leader>x", "<cmd>...<cr>", { desc = "Description" })`

**Add plugin-specific keymaps:**
- Define in the plugin's config function
- Keep keymaps close to plugin setup for clarity

**Change vim settings:**
- Edit `lua/kupo/core/options.lua`
- Use `vim.opt.setting = value` format

**Add/modify LSP server:**
- Edit `lua/kupo/plugins/lsp/lspconfig.lua`
- Servers are auto-installed via Mason
- Use the setup_handlers pattern for per-server customization

### Testing Configuration Changes

1. Save the file (`:w`)
2. Reload with `:source %` (for current file) or restart Neovim
3. For plugin changes, lazy.nvim auto-detects on restart
4. Check for errors with `:messages`

### Debugging

**Check if a plugin is loaded:**
```vim
:Lazy
```

**Check plugin configuration:**
```vim
:Lazy log
```

**View startup time:**
```vim
:Lazy profile
```

**Check LSP status:**
```vim
:LspInfo
```

**View keymaps:**
- Press `<Space>` (leader key) and wait - which-key shows available bindings

## Key Architectural Decisions

### Two-Phase Loading
Core settings (`options.lua`, `keymaps.lua`) load before plugins to ensure vim settings are available when plugins initialize.

### LSP Namespace Separation
LSP configs are in their own subdirectory (`plugins/lsp/`) and imported separately in lazy.nvim setup. This isolates language server complexity.

### One Plugin Per File
Each plugin gets its own file for portability and clarity. Makes it easy to share or remove individual plugins.

### Aggressive Lazy Loading
Most plugins use `event`, `ft`, or `cmd` triggers to load on-demand, reducing startup time.

### Handler Pattern for LSP
The `lspconfig.lua` file uses Mason's `setup_handlers` to configure servers consistently while allowing per-server customization.

## Plugin Categories

Current plugin count: 32+

Key categories:
- **UI**: alpha, colorscheme, lualine, bufferline, indent-blankline, dressing
- **Navigation**: nvim-tree, telescope, harpoon
- **Git**: gitsigns, lazygit, diffview
- **LSP**: mason, lspconfig, nvim-cmp (completion)
- **Code Quality**: formatting (conform.nvim), linting (nvim-lint)
- **Editing**: treesitter, autopairs, comment, surround
- **AI**: copilot, chatgpt, avante
- **Utilities**: undotree, vim-maximizer, which-key, trouble, todo-comments, auto-session, ufo (folding)

## Important Conventions

1. **Leader key**: Space (`<leader>` = ` `)
2. **Indentation**: 2 spaces (configured in options.lua)
3. **Keymap descriptions**: Always include `desc` field for which-key integration
4. **Plugin loading**: Use events (`VeryLazy`, `BufReadPre`, etc.) for performance
5. **File changes**: Auto-reload configured via autocommand in options.lua

## Language Support

This configuration is set up for full-stack development:
- **Web**: TypeScript, JavaScript, HTML, CSS, React
- **Backend**: Python, Lua
- **Config**: JSON, YAML, TOML
- **Other**: Git, Markdown

LSP servers, formatters, and linters are managed through Mason and configured in the `plugins/lsp/` directory.
