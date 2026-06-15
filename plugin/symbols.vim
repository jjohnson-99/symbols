"=================================================
" File: plugin/symbols.vim
" Description: Popout symbols panel inspired by GitHub.
" Author: Jeremy Johnson <js.johnson990@gmail.com>
" License: BSD

" Avoid installing twice.
if exists('g:loaded_symbols')
    finish
endif
let g:loaded_symbols = 0


"=================================================
" compact indicators -> narrower default panel (24 instead of 30)
if !exists('g:symbols_ShortIndicators')
    let g:symbols_ShortIndicators = 0
endif

" Panel width is derived from g:symbols_ShortIndicators (24 when on, else 30).
" Set g:symbols_SplitWidth explicitly to override with an exact width. It is
" intentionally left unset by default so the width can be re-evaluated on each
" toggle (letting runtime changes take effect).

" place the panel on the right instead of the left
if !exists('g:symbols_SplitRight')
    let g:symbols_SplitRight = 0
endif

" strip C++ scope qualifiers in symbol names, e.g. ns::Foo::bar -> bar
if !exists('g:symbols_ShortNames')
    let g:symbols_ShortNames = 1
endif

" highlight the line under the cursor in the symbols panel
if !exists('g:symbols_CursorLine')
    let g:symbols_CursorLine = 1
endif

" spaces per indent level in the symbols panel
if !exists('g:symbols_IndentLength')
    let g:symbols_IndentLength = 2
endif


"=================================================
" User commands.
command! -nargs=0 -bar SymbolsToggle :call symbols#SymbolsToggle()

" vim: set et fdm=marker sts=4 sw=4:
