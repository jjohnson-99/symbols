"=================================================
" File: symbols.vim
" Description: symbols syntax
" Author: Jeremy Johnson <js.johnson990@gmail.com>
" License: BSD

" ⌄ (unfolded) and › (folded) in column 1
"syntax match SymbolsChevron /^[⌄›]/

" type keyword: first non-whitespace word after the col-1 chevron/space
"syntax match SymbolsType /^\s*\zs\(class\|func\|struct\|enum\|union\)\>/
"syntax match SymbolsType /class/

" symbol name: word immediately after the type keyword
"syntax match SymbolsName /^\s*\%(class\|func\|struct\|enum\|union\)\>\s\+\zs\S\+/
"
syntax match SymbolsChevron /^[⌄›]/

syntax match SymbolsType /\<\(class\|func\|struct\|enum\|union\)\>/ nextgroup=SymbolsName skipwhite

syntax match SymbolsName /\S\+/ contained

" persistent cursor-line highlight (matchadd keeps this visible when unfocused)
highlight default link SymbolsChevron Comment
highlight default link SymbolsType    Keyword
highlight default link SymbolsName    Function
"
" vim: set et fdm=marker sts=4 sw=4:
