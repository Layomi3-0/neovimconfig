# Neovim Configuration

## Project Overview

This is a Neovim configuration written in Lua. It uses the `lazy.nvim` plugin manager to handle plugins. The configuration is well-structured, with a clear separation of concerns between core settings, plugin configurations, and keymaps.

The main entry point is `init.lua`, which loads the core configuration from `lua/kupo/core` and the plugin manager setup from `lua/kupo/lazy.lua`. Plugins are defined as individual files in the `lua/kupo/plugins` directory.

## Key Features

*   **Plugin Manager:** `lazy.nvim` is used for plugin management.
*   **Colorscheme:** `tokyonight.nvim` is the configured colorscheme, with a custom color palette.
*   **Fuzzy Finding:** `telescope.nvim` is used for fuzzy finding files, buffers, and more.
*   **Autocompletion:** `nvim-cmp` is used for autocompletion, with sources for LSP, snippets, buffer, and paths.
*   **Snippets:** `luasnip` is used for snippets, with support for VS Code style snippets.
*   **LSP:** The configuration is set up for LSP, but the main `lspconfig.lua` is currently commented out.
*   **Keymaps:** A comprehensive set of keymaps are defined in `lua/kupo/core/keymaps.lua` for improved navigation and functionality.

## Building and Running

To use this configuration, you need to have Neovim installed. Then, clone this repository into your `~/.config/nvim` directory.

```bash
git clone <repository-url> ~/.config/nvim
```

The `lazy.nvim` plugin manager will automatically install the plugins the first time you open Neovim.

## Development Conventions

The configuration is structured in a modular way.

*   `init.lua`: The main entry point.
*   `lua/kupo/core/`: Core Neovim settings, including options and keymaps.
*   `lua/kupo/lazy.lua`: `lazy.nvim` plugin manager setup.
*   `lua/kupo/plugins/`: Plugin configurations. Each file represents a plugin or a group of related plugins.

When adding a new plugin, you should create a new file in the `lua/kupo/plugins/` directory and add the plugin's configuration there.
