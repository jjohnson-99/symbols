### Description

A popout panel displaying the symbols (classes, functions, methods, and more)
in the current buffer, much like the symbols panel on GitHub. It uses
Treesitter on the backend, so it requires Neovim and the relevant parsers.

Move the cursor onto a symbol's line in the panel to navigate to it. The panel
keeps itself up to date as you edit and switch windows.

![Symbols panel example](media/symbols-example.png)

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

Inside the panel:

| Key    | Action                                                       |
| ------ | ------------------------------------------------------------ |
| `<CR>` | Jump to the symbol and focus the target window.              |
| `s`    | Jump to the symbol but keep the panel focused (preview).     |

### Options

```vim
" Strip C++ scope qualifiers in symbol names: ns::Foo::bar -> bar (default: 1)
let g:symbols_ShortNames = 1
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
