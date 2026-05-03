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
" symbols window width
if !exists('g:symbols_SplitWidth')
    let g:symbols_SplitWidth = 30
endif

if !exists('g:symbols_ShortDisplay')
    let g:symbols_ShortDisplay = 0
endif

" spaces per indent level in the symbols panel
if !exists('g:symbols_IndentLength')
    let g:symbols_IndentLength = 2
endif


"=================================================
" User commands.
command! -nargs=0 -bar SymbolsToggle :call symbols#SymbolsToggle()

" vim: set et fdm=marker sts=4 sw=4:
