"=================================================
" File: autoload/symbols.vim
" Description: Popout symbols panel.
" Author: Jeremy Johnson <js.johnson990@gmail.com>
" License: BSD


" Avoid installing twice.
if exists('g:autoloaded_symbols')
    finish
endif
let g:autoloaded_symbols = 0

let s:ns = nvim_create_namespace('symbols')

" load language and language parameters

"[(class_definition
"	name: (identifier) @class_name)
"(function_definition
"	name: (identifier) @function_name)]

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

" Effective panel width, evaluated live so runtime changes take effect on the
" next toggle. An explicit g:symbols_SplitWidth wins; otherwise the width is
" derived from g:symbols_ShortIndicators (24 when on, else 30).
function! s:splitWidth() abort
    if exists('g:symbols_SplitWidth')
        return g:symbols_SplitWidth
    endif
    return g:symbols_ShortIndicators == 1 ? 24 : 30
endfunction


"=================================================
"Base class for panels.
let s:panel = {}

function! s:panel.Init() abort
    let self.bufname = "invalid"
endfunction

function! s:panel.SetFocus() abort
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
    let self.targetid = -1
    let self.targetBufnr = -1
    let self.targetTick = -1

    let self.symbolstree = [] "output data.
    let self.linedata = []
    let self.hlmatchid = -1

    let self.showHelp = 0
endfunction


" from claude
function! s:symbols.BindKey() abort "undotree has call in
    " <CR> jumps to the symbol and focuses the target window.
    nnoremap <silent><buffer> <CR> :call t:symbols.JumpToSymbol(0)<CR>
    " s previews: moves the target window's cursor but keeps the panel focused.
    nnoremap <silent><buffer> s    :call t:symbols.JumpToSymbol(1)<CR>
endfunction


function! s:symbols.JumpToSymbol(stay) abort
    let idx = line('.') - 1
    if idx < 0 || idx >= len(self.linedata)
        return
    endif
    let targetrow = self.linedata[idx]
    if !self.SetTargetFocus()
        return
    endif
    call cursor(targetrow, 1)
    call s:exec_silent("norm! zz")
    " Preview jump: return focus to the panel after moving the target cursor.
    if a:stay
        call self.SetFocus()
    endif
endfunction


function! s:symbols.BindAu() abort
    " Auto exit if it's the last window
    augroup Symbols_Main
        au!
        au BufEnter <buffer> call s:exitIfLast()
        "au CursorMoved <buffer> call t:symbols.UpdateCursorHL()
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
    let auEvents = "BufEnter,InsertLeave,CursorMoved" ",CursorMoved,BufWritePost"
    " call s:log(self.bufname." Toggle()")
    if self.IsVisible()
        call self.Hide()
        "claude
        "let self.rawtree = []
        "let self.hlmatchid = -1
        "endclaude
        call self.SetTargetFocus()
        augroup Symbols
            autocmd!
        augroup END
    else
        call self.Show()
        " Show() leaves the cursor in the panel; return to the original window
        " unless the user wants focus to follow the panel open.
        if !g:symbols_SetFocusWhenToggle
            call self.SetTargetFocus()
        endif
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

    " Create symbols window. Side and width are evaluated here so runtime option
    " changes apply on the next toggle.
    let pos = g:symbols_SplitRight ? "botright" : "topleft"
    let cmd = pos . " vertical" .
            \s:splitWidth() . ' new ' . self.bufname

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
    if g:symbols_CursorLine
        setlocal cursorline
    else
        setlocal nocursorline
    endif
    setlocal nomodifiable
    setfiletype symbols

    " ...
    "

    " Make :q call ActionClose
    "cabbrev <silent><buffer> q :call t:undotree.ActionClose()<CR>
    call self.BindKey()
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
    let curbuf = bufnr('%')

    if (&bt != '' && &bt != 'acwrite') || (&modifiable == 0) || (mode() != 'n')
        if self.targetBufnr == curbuf && self.targetid == w:symbols_id
            "call s:log("symbols.Update() invalid buffer NOupdate")
            return
        endif
        let emptybuf = 1 "This is not a valid buffer, could be help or something.
        "call s:log("symbols.Update() invalid buffer update")
    else
        let emptybuf = 0 "Valid buffer
    endif

    " Skip the expensive re-extract + redraw when nothing affecting the symbol
    " list has changed since the last refresh (mirrors undotree's seq check):
    " same target buffer, same window, and unchanged buffer content.
    if !emptybuf && self.targetBufnr == curbuf
                \ && self.targetid == w:symbols_id
                \ && self.targetTick == b:changedtick
        return
    endif

    let self.targetBufnr = curbuf
    let self.targetid = w:symbols_id
    let self.targetTick = emptybuf ? -1 : b:changedtick

    if emptybuf " Show an empty panel instead of doing nothing.
        let displaylist = []
    else
        let displaylist = luaeval('require("backend").get_display_list()')
    endif

    " Build three parallel lists, one entry per displayed line:
    "   symbolstree - rendered text shown in the panel
    "   renderdata  - structured item (capture, hl, columns) for highlighting
    "   linedata    - target-buffer row to jump to
    let self.symbolstree = []
    let self.renderdata = []
    let self.linedata = []
    for item in displaylist
        call add(self.symbolstree, item.text)
        call add(self.renderdata, item)
        call add(self.linedata, item.row)
    endfor

    call self.SetFocus()
    call self.Draw()
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
    call append(0,self.symbolstree) " keep this

    "remove the last empty line
    call s:exec('$d _')

    " clear previous highlights
    call nvim_buf_clear_namespace(0, s:ns, 0, -1)

    " apply highlights per line (columns are byte offsets supplied by the backend)
    for idx in range(len(self.renderdata))
        let item = self.renderdata[idx]
        let lnum = idx  " 0-based line for the API

        " fold chevron occupies the first cell (3 bytes for the glyph)
        if item.has_children
            call nvim_buf_add_highlight(0, s:ns, 'SymbolsChevron', lnum, 0, 3)
        endif

        " 'class' / 'func' label
        call nvim_buf_add_highlight(0, s:ns, 'SymbolsLabel', lnum, item.label_col, item.label_col + strlen(item.label))

        " symbol name, highlighted per its treesitter capture
        call nvim_buf_add_highlight(0, s:ns, item.hl, lnum, item.name_col, -1)
    endfor

    " restore previous cursor position.
    call winrestview(savedview)

    setlocal nomodifiable
endfunction

" in undotree, does self.tree -> self.asciitree
" while Draw displays self.asciitree

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

