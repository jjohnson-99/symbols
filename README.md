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

" Narrower default panel: sets the width preset to 24 instead of 30 (default: 0)
let g:symbols_ShortIndicators = 0

" Width of the panel. Defaults from g:symbols_ShortIndicators (30, or 24 if on);
" set explicitly to override with an exact width.
let g:symbols_SplitWidth = 30

" Place the panel on the right instead of the left (default: 0)
let g:symbols_SplitRight = 0

" Move focus into the panel when toggling it open (default: 0 = stay put)
let g:symbols_SetFocusWhenToggle = 0

" Highlight the line under the cursor in the panel (default: 1)
let g:symbols_CursorLine = 1

" Spaces per indent level in the panel (default: 2)
let g:symbols_IndentLength = 2
```

Set these in your config (`init.vim`/`init.lua`, or a lazy.nvim `init` block) to
make them persistent. Running `:let g:symbols_... = ...` only affects the current
session — like any Vim global, it is not saved when you exit Neovim. Most options
are re-read when the panel is toggled, so toggle it off and on to apply a change.

### Supported languages

- Python
- Lua
- C
- C++ (`.cpp` and `.hpp`)
- Go
- Rust
- JavaScript
- TypeScript

Each language is driven by a Treesitter query (`queries/<lang>/symbols.scm`),
so adding a language is mostly a matter of writing one. The relevant Treesitter
parser must be installed (e.g. via `:TSInstall <lang>`).

### Roadmap

- Folding of symbols (collapse/expand nested symbols) is planned.

This plugin is still early; expect slow, steady improvements.
