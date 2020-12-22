" based on https://github.com/phongnh/lightline-settings.vim/blob/master/plugin/lightline_settings.vim
let s:filename_modes = {
            \ '__Tagbar__':           'Tagbar',
            \ '[BufExplorer]':        'BufExplorer',
            \ '[Command Line]':       'Command Line',
            \ '[Plugins]':            'Plugins',
            \ '__committia_status__': 'Committia Status',
            \ '__committia_diff__':   'Committia Diff',
\ }
let s:filetype_modes = {
            \ 'netrw':         'NetrwTree',
            \ 'chaddtree':     'CHADTree',
            \ 'startify':      'Startify',
            \ 'vimshell':      'VimShell',
            \ 'help':          'Help',
            \ 'qf':            'Quickfix',
            \ 'gitcommit':     'Commit Message',
            \ 'fugitiveblame': 'FugitiveBlame',
            \ }

let s:short_modes = {
            \ 'NORMAL':   'N',
            \ 'INSERT':   'I',
            \ 'VISUAL':   'V',
            \ 'V-LINE':   'L',
            \ 'V-BLOCK':  'B',
            \ 'COMMAND':  'C',
            \ 'SELECT':   'S',
            \ 'S-LINE':   'S-L',
            \ 'S-BLOCK':  'S-B',
            \ 'TERMINAL': 'T',
\ }
let g:powerline_symbols = {}
let g:powerline_symbols.separator    = { 'left': '', 'right': '' }
let g:powerline_symbols.subseparator = { 'left': '|', 'right': '|' }
let g:powerline_symbols.linenr       = ''
let g:powerline_symbols.branch       = ''
let g:powerline_symbols.readonly     = 'RO'
let g:powerline_symbols.clipboard = ' @'
function! LightlineWinWidth() abort
    return winwidth(0)
endfunction

function! LightlineDisplayFilename() abort
    if LightlineWinWidth() >= 50 && &filetype =~? 'help\|gedoc'
        return 1
    endif
    return LightlineDisplayFileinfo()
endfunction

function! LightlineDisplayFileinfo() abort
    if LightlineWinWidth() < 50 || expand('%:t') =~? '^NrrwRgn' || has_key(s:filename_modes, expand('%:t')) || has_key(s:filetype_modes, &filetype)
        return 0
    endif
    return 1
endfunction

function! LightlineModified() abort
    return &filetype =~? 'help' ? '' : &modified ? '+' : &modifiable ? '' : '-'
endfunction

function! LightlineReadonly() abort
        let fname = expand('%:t')
    return &readonly && &filetype !~# '\v(help|vista|chadtree|netrw)'  ? 'RO' : ''
endfunction

function! LightlineClipboard() abort
    return match(&clipboard, 'unnamed') > -1 ? g:powerline_symbols.clipboard : ''
endfunction

function! LightlineShortMode(mode) abort
    if LightlineWinWidth() > 75
        return a:mode
    endif
    return get(s:short_modes, a:mode, a:mode)
endfunction

function! LightlineMode() abort
    let fname = expand('%:t')
    if &filetype == 'netrw'
        return ''
    else
        return fname  ==# '__Tagbar__' ? 'Tagbar':
            \ fname ==# '__vista__' ? 'Vista':
            \ fname ==# 'ControlP' ? 'CtrlP':
            \ &filetype ==# 'chadtree' ? 'CHADTree' :
            \ get(s:filename_modes, fname, get(s:filetype_modes, &filetype, LightlineShortMode(lightline#mode())))
    endif
endfunction

function! LightlineModeAndClipboard() abort
    return LightlineMode() . LightlineClipboard()
endfunction

" Copied from https://github.com/SethBarberee/dotfiles/blob/master/neovim/.config/nvim/after/plugin/lightline.vim
function! LightlineTabReadonly(n) abort
    let fname = expand('%:t')
    return &readonly && &filetype !~# '\v(help|vista|chadtree|netrw)'  ? 'RO' : ''
endfunction

" Copied from https://github.com/itchyny/lightline-powerful
function! LightlineTabFilename(n) abort
    let bufnr = tabpagebuflist(a:n)[tabpagewinnr(a:n) - 1]
    let bufname = expand('#' . bufnr . ':t')
    let buffullname = expand('#' . bufnr . ':p')
    let bufnrs = filter(range(1, bufnr('$')), 'v:val != bufnr && len(bufname(v:val)) && bufexists(v:val) && buflisted(v:val)')
    let i = index(map(copy(bufnrs), 'expand("#" . v:val . ":t")'), bufname)
    let ft = gettabwinvar(a:n, tabpagewinnr(a:n), '&ft')
    if strlen(bufname) && i >= 0 && map(bufnrs, 'expand("#" . v:val . ":p")')[i] != buffullname
        let fname = substitute(buffullname, '.*/\([^/]\+/\)', '\1', '')
    else
        let fname = bufname
    endif
    return fname =~# '^\[preview' ? 'Preview' : get(s:filename_modes, fname, get(s:filetype_modes, ft, fname))
endfunction

function! LightlineAlternateFilename(fname) abort
    if a:fname ==# 'ControlP'
        return LightlineCtrlPMark()
    elseif a:fname ==# '__Tagbar__'
        return g:lightline.fname
    elseif a:fname =~ '__Gundo\|NERD_tree'
        return ''
    elseif a:fname =~? '^NrrwRgn'
        let bufname = (get(b:, 'orig_buf', 0) ? bufname(b:orig_buf) : substitute(bufname('%'), '^Nrrwrgn_\zs.*\ze_\d\+$', submatch(0), ''))
        return bufname
    elseif &filetype ==# 'qf'
        return get(w:, 'quickfix_title', a:fname)
    elseif &filetype ==# 'unite'
        return unite#get_status_string()
    elseif &filetype ==# 'vimfiler'
        return vimfiler#get_status_string()
    elseif &filetype ==# 'vimshell'
        return vimshell#get_status_string()
    endif
    return ''
endfunction

function! LightlineFilenameWithFlags(fname) abort
    if LightlineDisplayFilename()
        let str = (LightlineReadonly() != '' ? LightlineReadonly() . ' ' : '')
        if strlen(a:fname)
            let path = expand('%:~:.')
            if strlen(path) > 60
                let path = substitute(path, '\v\w\zs.{-}\ze(\\|/)', '', 'g')
            endif
            if strlen(path) > 60
                let path = a:fname
            endif
            let str .= path
        else
            let str .= '[No Name]'
        endif
        let str .= (LightlineModified() != '' ? ' ' . LightlineModified() : '')
        return str
    endif
    return ''
endfunction

function! LightlineFilename() abort
    let fname = expand('%:t')

    let str = LightlineAlternateFilename(fname)

    if strlen(str)
        return str
    endif

    return LightlineFilenameWithFlags(fname)
endfunction

function! LightlineFileencoding() abort
    if LightlineDisplayFileinfo()
        let encoding = strlen(&fenc) ? &fenc : &enc
        if encoding !=? 'utf-8'
            return encoding
        endif
    endif
    return ''
endfunction

" https://github.com/skbolton/titan/blob/4c306d82697cedc0952d1c36f7174076abf81c4d/nvim/nvim/status-line.vim
function! FileNameWithIcon() abort
  return winwidth(0) > 70  ? luaeval("require'nvim-web-devicons'.get_icon(_A[1], _A[2], { default = true })", [expand('%:t'), expand('%:e')]) . ' ' . expand('%:e') : '' 
endfunction

let g:lightline = {
    \ 'colorscheme': 'breezy',
    \ 'active': {
    \   'left': [['mode', 'paste'], ['filename', 'modified'], ['gitbranch']],
    \   'right': [['filetype', 'readonly'], ['nofixme', 'gitstatus'], [ 'lsp_errors', 'lsp_warnings', 'lsp_ok', 'linter_errors', 'linter_warnings', 'linter_ok' ]]
    \ },
    \ 'inactive': {
    \   'left': [['mode', 'paste'], ['filename', 'modified'], ['gitbranch', 'gitstatus']],
    \   'right': [['filetype']]
    \ },
    \ 'component': {
    \   'gitstatus': '%<%{lightline_gitdiff#get_status()}',
    \ },
    \ 'component_visible_condition': {
    \   'gitstatus': 'lightline_gitdiff#get_status() !=# ""',
    \ },
    \ 'component_function': {
    \   'filetype':  'FileNameWithIcon',
    \   'mode':      'LightlineModeAndClipboard',
    \   'readonly': 'LightlineReadonly',
    \   'filename':  'LightlineFilename',
    \   'gitbranch': 'gitbranch#name'
    \ },
    \ 'component_expand': {
    \   'linter_warnings': 'lightline#ale#warnings',
    \   'linter_errors':   'lightline#ale#errors',
    \   'linter_ok':    'lightline#ale#ok',
    \   'lsp_warnings': 'lightline_lsp#warnings',
    \   'lsp_errors':   'lightline_lsp#errors',
    \   'lsp_ok':       'lightline_lsp#ok',
    \   'nofixme':      'nofixme#amount',
    \ },
    \ 'component_type': {
    \   'linter_warnings': 'warning',
    \   'linter_errors': 'error',
    \   'lsp_warnings': 'warning',
    \   'lsp_errors':   'error',
    \   'lsp_ok':       'middle',
    \   'gitstatus':    'middle',
    \   'nofixme':      'warning',
    \ },
    \ 'subseparator': {
    \   'left': '', 'right': ''
    \ },
    \ 'separator': {
    \   'left': '', 'right': ''
    \ },
    \ 'tabline': {
    \   'left': [ ['tabs'] ],
    \   'right': [ ['close'] ]
    \ }
\ }
