# Neovim Configuration

Personal Neovim configuration based on kickstart-modular.nvim. Windows-based setup.

## Project Structure

```
nvim/
├── init.lua              # Entry point - loads core modules
├── lua/
│   ├── options.lua       # Vim options (line numbers, folds, clipboard, etc.)
│   ├── keymap.lua        # Core keymaps (leader=Space)
│   ├── commands.lua      # Autocommands
│   ├── utils.lua         # Utility functions
│   ├── lazy-plugins.lua  # Lazy.nvim plugin manager setup
│   ├── plugins/          # Plugin configurations (auto-imported by Lazy)
│   │   ├── lsp/          # LSP-related configs (servers, keymaps, capabilities)
│   │   ├── debug/        # DAP configurations (C#, Lua, UI)
│   │   └── *.lua         # Individual plugin configs
│   └── snippets/         # Custom snippets (lua, cs, js)
```

## Plugin Manager

Uses **lazy.nvim** with modular imports from `lua/plugins/`. Plugins are automatically loaded from the plugins directory.

## Language Support

LSP servers configured in `lua/plugins/lsp/servers.lua`:
- **C#**: roslyn_ls (Roslyn LSP)
- **TypeScript/JavaScript**: ts_ls
- **Lua**: lua_ls
- **Python**: pyright
- **Rust**: rust_analyzer
- **XML**: lemminx

Debug adapters in `lua/plugins/debug/`:
- C# debugging
- Lua debugging

## Code Style (Lua)

Enforced via StyLua (`.stylua.toml`):
- **Indent**: 2 spaces
- **Line width**: 160 characters
- **Quotes**: Single preferred
- **Line endings**: Unix
- **Call parentheses**: None (no parens for single string/table args)

## Key Conventions

- **Leader key**: Space
- **Window navigation**: `<C-h/j/k/l>`
- **Tab operations**: `t` prefix (`tn`, `tc`, `tl`, `th`, `td`, `tm`)
- **Buffer operations**: `<leader>b` prefix
- **Save operations**: `<leader>s` prefix
- **Quickfix**: `<leader>q` prefix
- **Copy to clipboard**: `<leader>y` prefix

## When Editing This Config

1. Follow existing patterns in similar files
2. Use 2-space indentation, single quotes where possible
3. Place new plugins in `lua/plugins/` as separate files
4. LSP servers go in `lua/plugins/lsp/servers.lua`
5. Debug configs go in `lua/plugins/debug/`
6. Custom snippets go in `lua/snippets/`
7. Keep descriptions concise in keymap definitions

## Testing Changes

After making changes:
1. Save the file (`:w`)
2. Source if needed (`:so` for lua files)
3. Or restart Neovim
4. Check `:Lazy` for plugin status
5. Check `:checkhealth` for issues
