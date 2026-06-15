### Description

A popout panel displaying the symbols (classes, functions, methods, and more)
in the current buffer, much like the symbols panel on GitHub. It uses
Treesitter on the backend, so it requires Neovim and the relevant parsers.

Jump to a symbol by moving the cursor onto its line in the panel and pressing
`<CR>`. The panel keeps itself up to date as you edit and switch windows.

### Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "jjohnson-99/symbols",
  cmd = "SymbolsToggle",
  keys = {
    { "<leader>zs", "<cmd>SymbolsToggle<cr>", desc = "Toggle symbols panel" },
  },
}
```

### Usage

Toggle the panel with `<leader>zs`, or the command:

```
:SymbolsToggle
```

### Supported languages

- Python
- Lua
- C++ (`.cpp` and `.hpp`)

Each language is driven by a Treesitter query (`queries/<lang>/symbols.scm`),
so adding a language is mostly a matter of writing one.

### Roadmap

- Folding of symbols (collapse/expand nested symbols) is planned.

This plugin is still early; expect slow, steady improvements.
