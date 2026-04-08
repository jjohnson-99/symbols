"=================================================
" File: autoload/symbols.vim
" Description: Popout symbols panel.
" Author: Jeremy Johnson <js.johnson990@gmail.com>
" License: BSD


" Avoid installing twice.
" if exists('g:autoloaded_symbols')
"    finish
" endif
" let g:autoloaded_symbols = 0

" load language and language parameters

"[(class_definition
"	name: (identifier) @class_name)
"(function_definition
"	name: (identifier) @function_name)]

function! LuaTest(buf) abort
    echom luaeval('require("backend").get_symbols_tree()')
endfunction
"
"for id, node, metadata, match in query:iter_captures(tree:root(), bufnr, first, last) do
"  local name = query.captures[id] -- name of the capture in the query
"  -- typically useful info about the node:
"  local type = node:type() -- type of the captured node
"  local row1, col1, row2, col2 = node:range() -- range of the capture
"  -- ... use the info here ...
"end

"=================================================
function! s:new(obj) abort
    let newobj = deepcopy(a:obj)
    call newobj.Init()
    return newobj
endfunction

function! s:exec(cmd) abort
    "call s:log("s:exec() ".a:cmd)
    silent exe a:cmd
endfunction

" Don't trigger any events (like BufEnter which could cause redundant refresh)
function! s:exec_silent(cmd) abort
    " call s:log("s:exec_silent() ".a:cmd)
    let ei_bak= &eventignore " save previous ei
    set eventignore=BufEnter,BufLeave,BufWinLeave,InsertLeave,CursorMoved,BufWritePost
    silent exe a:cmd
    let &eventignore = ei_bak " reset to previous ei
endfunction

" Return a unique id each time.
let s:cntr = 0
function! s:getUniqueID() abort
    let s:cntr = s:cntr + 1
    return s:cntr
endfunction


"=================================================
"Base class for panels.
let s:panel = {}

function! s:panel.Init() abort
    let self.bufname = "invalid"
endfunction

function! s:panel.SetFocus() abort
    echom self.bufname
    let winnr = bufwinnr(self.bufname)
    " already focused.
    if winnr == winnr()
        return
    endif
    if winnr == -1
        echoerr "Fatal: window does not exist!"
        return
    endif
    " call s:log("SetFocus() winnr:".winnr." bufname:".self.bufname)
    " wincmd would cause cursor outside window.
    call s:exec_silent("norm! ".winnr."\<c-w>\<c-w>") " e.g., 2<c-w><c-w> goes to second window down
endfunction

function! s:panel.IsVisible() abort
    if bufwinnr(self.bufname) != -1
        return 1
    else
        return 0
    endif
endfunction

function! s:panel.Hide() abort
    " call s:log(self.bufname." Hide()")
    if !self.IsVisible()
        return
    endif
    call self.SetFocus()
    call s:exec("quit")
endfunction


"=================================================
" symbols panel class.
" extended from panel.
"

let s:symbols = s:new(s:panel)

function! s:symbols.Init() abort
    let self.bufname = "symbols_".s:getUniqueID()
    let self.width = g:symbols_SplitWidth
    " let self.opendiff = g:symbols_DiffAutoOpen
    " let self.diffmark = -1 " Marker for the diff view
    let self.targetid = -1
    let self.targetBufnr = -1
    let self.rawtree = []
    let self.tree = []

    let self.symbolstree = [] "output data.

    let self.showHelp = 0
endfunction


"function! s:symbols.BindKey() abort
"
"endfunction


function! s:symbols.BindAu() abort
    " Auto exit if it's the last window
    augroup Symbols_Main
        au!
        au BufEnter <buffer> call s:exitIfLast()
    augroup end
endfunction

"function! s:symbols.Action(action) abort
"
"endfunction
"
"Action functions
"

function! s:symbols.SetTargetFocus() abort
    for winnr in range(1, winnr('$')) " winnr starts from 1
        if getwinvar(winnr,'symbols_id') == self.targetid
            if winnr() != winnr
                call s:exec_silent("norm! ".winnr."\<c-w>\<c-w>")
                return 1
            endif
        endif
    endfor
    return 0
endfunction

" au handles automatic updating
function! s:symbols.Toggle() abort
    " Global auto commands to keep symbols panel up to date
    let auEvents = "BufEnter,InsertLeave" ",CursorMoved,BufWritePost"
    " call s:log(self.bufname." Toggle()")
    if self.IsVisible()
        call self.Hide()
        call self.SetTargetFocus()
        augroup Symbols
            autocmd!
        augroup END
    else
        call self.Show()
       " if !g:symbols_SetFocusWhenToggle " need to define globals
       "     call self.SetTargetFocus()
       " endif
       augroup Symbols
            au!
            exec "au! ".auEvents." * call symbols#SymbolsUpdate()"
       augroup END
    endif
endfunction

function! s:symbols.Show() abort
    " call s:log("symbols.Show()")
    if self.IsVisible()
        return
    endif

    let self.targetid = w:symbols_id

    " Create symbols window.
    let cmd = "topleft vertical" .
            \self.width . ' new ' . self.bufname

    call s:exec("silent keepalt ".cmd)
    call self.SetFocus()

    " ensures we have a way to tell whether buffer belongs to symbols panel
    let b:isSymbolsBuffer = 1

    setlocal winfixwidth
    setlocal noswapfile
    setlocal buftype=nowrite
    setlocal bufhidden=delete
    setlocal nowrap
    setlocal nolist
    setlocal foldcolumn=0
    setlocal nobuflisted
    setlocal nospell
    setlocal nonumber
    setlocal norelativenumber

    " ...
    "

    " Make :q call ActionClose
    "cabbrev <silent><buffer> q :call t:undotree.ActionClose()<CR>
    "call self.BindKey()
    call self.BindAu()

    let ei_bak= &eventignore
    set eventignore=all

    call self.SetTargetFocus()
    let self.targetBufnr = -1
    call self.Update()

    let &eventignore = ei_bak
endfunction


" called outside of symbols window
function! s:symbols.Update() abort
    if !self.IsVisible()
        return
    endif
    " do nothing if we're in the symbols panel
    if exists('b:isSymbolsBuffer')
        return
    endif

    " disable symbols for chosen buftypes/filetypes

    " bt ~ buftype, <empty> ~ normal buffer, acwrite ~ buffer will always be written with BufWriteCmd
    if (&bt != '' && &bt != 'acwrite') || (&modifiable == 0) || (mode() != 'n')
        if self.targetBufnr == bufnr('%') && self.targetid == w:symbols_id
            "call s:log("symbols.Update() invalid buffer NOupdate")
            return
        endif
        let emptybuf = 1 "This is not a valid buffer, could be help or something.
        "call s:log("symbols.Update() invalid buffer update")
    else
        let emptybuf = 0 "Valid buffer
    endif

    let self.targetBufnr = bufnr('%')
    let self.targetid = w:symbols_id
    echom &filetype

    if emptybuf " Show an empty undo tree instead of do nothing.
        "let self.rawtree = {'seq_last':0,'entries':[],'time_cur':0,'save_last':0,'synced':1,'save_cur':0,'seq_cur':0}
    else
        let newsymbolstree = luaeval('require("backend").get_symbols_tree()')
        echom newsymbolstree
        if self.rawtree == newsymbolstree
            return
        endif
    endif

    " drawing logic
    "call self.ConvertInput(1) "update all.
    "call self.Render()
    "call self.SetFocus()
    "call self.Draw()

    " echom self.targetBufnr " above manages which is target window

endfunction


function! s:symbols.Index2Screen(index) abort
    return
endfunction

function! s:symbols.Screen2Index(index) abort
    return
endfunction

" Current window must be symbols.
function! s:symbols.Draw() abort
    " remember the current cursor position.
    let savedview = winsaveview()

    setlocal modifiable
    " Delete text into blackhole register.
    call s:exec('1,$ d _')
    call append(0,self.symbolstree)

    "remove the last empty line
    call s:exec('$d _')

    " restore previous cursor position.
    call winrestview(savedview)

    setlocal nomodifiableendfunction
endfunction

" in undotree, does self.tree -> self.asciitree
" while Draw displays self.asciitree
function! s:symbols.Render() abort

endfunction

"=================================================

function! s:exitIfLast() abort
    let num = 0
    if exists('t:symbols') && t:symbols.IsVisible()
        let num = 1
    endif
    if winnr('$') == num
        if exists('t:symbols')
            call t:symbols.Hide()
        endif
    endif
endfunction

"=================================================
" User command functions
" called outside symbols window

echom "Autoloading..."

function! symbols#SymbolsUpdate() abort
    if !exists('t:symbols')
        return
    endif
    if !exists('w:symbols_id')
        let w:symbols_id = 'id_'.s:getUniqueID()
        "call s:log("Unique window id assigned: ".w:undotree_id)
    endif
    " assume window layout won't change during updating.
    let thiswinnr = winnr()
    call t:symbols.Update()
    " focus moved
    if winnr() != thiswinnr
        call s:exec("norm! ".thiswinnr."\<c-w>\<c-w>")
    endif
endfunction

function! symbols#SymbolsToggle() abort

    let t:bufnumber = winnr('$')
    "echom s:getUniqueID()
    "echom s:symbols.bufname
    "echom g:symbols_SplitWidth
    if !exists('w:symbols_id')
        let w:symbols_id = 'id_'.s:getUniqueID()
    endif
    if !exists('t:symbols')
        let t:symbols = s:new(s:symbols)
    endif

    "call LuaTest(t:bufnumber)
    call t:symbols.Toggle()
    "try
    "    " call s:log(">>> SymbolsToggle()")
    "    if !exists('w:symbols_id)
    "        let w:symbols_id = 'id_'.s:getUniqueID()
    "        " call s:log("Unique window id assigned: ".w:symbols_id)
    "    endif
    "    if !exists('t:symbols')
    "        let t:symbols= s:new(s:symbols)
    "    endif
    "    call t:symbols.Toggle()
    "    " call s:log("<<< UndotreeToggle() leave")
    "catch /^Vim\%((\a\+)\)\?:E11/
    "    echohl ErrorMsg
    "    echom v:exception
    "    echohl NONE
    "endtry
endfunction


"=================================================

function! symbols#Hello() abort
    echo "Hi"
endfunction
echom "Done loading..."

