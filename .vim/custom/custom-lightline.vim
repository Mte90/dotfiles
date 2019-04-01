" based on https://github.com/phongnh/lightline-settings.vim/blob/master/plugin/lightline_settings.vim
let s:filename_modes = {
            \ '__Tagbar__':           'Tagbar',
            \ '__Gundo__':            'Gundo',
            \ '__Gundo_Preview__':    'Gundo Preview',
            \ '[BufExplorer]':        'BufExplorer',
            \ 'NERD_tree':            'NERDTree',
            \ 'NERD_tree_1':          'NERDTree',
            \ '[Command Line]':       'Command Line',
            \ '[Plugins]':            'Plugins',
            \ '__committia_status__': 'Committia Status',
            \ '__committia_diff__':   'Committia Diff',
\ }
let s:filetype_modes = {
            \ 'netrw':         'NetrwTree',
            \ 'nerdtree':      'NERDTree',
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

function! LightlineDisplayLineinfo() abort
    if LightlineWinWidth() >= 50 && &filetype =~? 'help\|qf\|godoc\|gedoc'
        return 1
    endif
    return LightlineDisplayFileinfo()
endfunction

function! LightlineModified() abort
    return &filetype =~? 'help' ? '' : &modified ? '+' : &modifiable ? '' : '-'
endfunction

function! LightlineReadonly() abort
    return &filetype !~? 'help' && &readonly ? g:powerline_symbols.readonly : ''
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
    if fname =~? '^NrrwRgn' && exists('b:nrrw_instn')
        return printf('%s#%d', 'NrrwRgn', b:nrrw_instn)
    endif
    return get(s:filename_modes, fname, get(s:filetype_modes, &filetype, LightlineShortMode(lightline#mode())))
endfunction

function! LightlineModeAndClipboard() abort
    return LightlineMode() . LightlineClipboard()
endfunction

function! LightlineTabnum(n) abort
    return printf('[%d]', a:n)
endfunction

function! LightlineTabLabel() abort
    return 'Tabs'
endfunction

" Copied from https://github.com/itchyny/lightline-powerful
function! LightlineTabReadonly(n) abort
    let winnr = tabpagewinnr(a:n)
    return gettabwinvar(a:n, winnr, '&readonly') ? g:powerline_symbols.readonly : ''
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

function! LightlineFugitive() abort
    if LightlineDisplayFileinfo() && LightlineWinWidth() > 100 && exists('*fugitive#head')
        let mark = g:powerline_symbols.branch
        try
            let branch = fugitive#head()
            if strlen(branch) > 30
                let branch = strcharpart(branch, 0, 20) . '...'
            endif
            return mark . branch
        catch
        endtry
    endif
    return ''
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

function! LightlineInactiveFilename() abort
    let fname = expand('%:t')

    let str = LightlineAlternateFilename(fname)

    if strlen(str)
        return str
    endif

    let str = get(s:filename_modes, fname, get(s:filetype_modes, &filetype, ''))
    if strlen(str)
        if &filetype ==? 'help'
            let str .= ' ' .  expand('%:~:.')
        endif

        return str
    endif

    return LightlineFilenameWithFlags(fname)
endfunction

function! LightlineLineinfo() abort
    if LightlineDisplayLineinfo()
        return printf('%s%4d:%3d', g:powerline_symbols.linenr, line('.'), col('.'))
    endif
    return ''
endfunction

function! LightlinePercent() abort
    if LightlineDisplayLineinfo()
        return printf('%3d%%', line('.') * 100 / line('$'))
    endif
    return ''
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

function! LightlineTabsOrSpacesStatus() abort
    if LightlineDisplayFileinfo()
        let shiftwidth = exists('*shiftwidth') ? shiftwidth() : &shiftwidth
        return (&expandtab ? 'Spaces' : 'Tab Size') . ': ' . shiftwidth
    endif
    return ''
endfunction

function! WDIFileType()
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype . ' ' . WebDevIconsGetFileTypeSymbol() : 'no ft') : ''
endfunction
function! WDIFileFormat()
  return winwidth(0) > 70 ? (&fileformat . ' ' . WebDevIconsGetFileFormatSymbol()) : ''
endfunction 

let g:lightline = {
    \ 'colorscheme': 'tender',
    \ 'active': {
    \   'left': [['mode', 'paste'], ['readonly', 'filename', 'modified'], ['tagbar', 'gitbranch', 'gitstatus']],
    \   'right': [['lineinfo'], ['filetype'], [ 'linter_errors', 'linter_warnings', 'linter_ok' ]]
    \ },
    \ 'inactive': {
    \   'left': [['mode', 'paste'], ['readonly', 'filename', 'modified'], ['tagbar', 'gitbranch', 'gitstatus']],
    \   'right': [['lineinfo'], ['filetype']]
    \ },
    \ 'component': {
    \   'lineinfo': '%l\%L [%p%%]',
    \   'tagbar': '%{tagbar#currenttag("[%s]", "", "f")}',
    \   'gitbranch': '%{&filetype=="help"?"":exists("*fugitive#head")?fugitive#head():""}',
    \   'gitstatus': '%<%{lightline_gitdiff#get_status()}',
    \ },
    \ 'component_visible_condition': {
    \   'gitstatus': 'lightline_gitdiff#get_status() !=# ""',
    \ },
    \ 'component_function': {
    \   'filetype': 'WDIFileType',
    \   'fileformat': 'WDIFileFormat',
    \   'tablabel':         'LightlineTabLabel',
    \   'mode':             'LightlineModeAndClipboard',
    \   'fugitive':         'LightlineFugitive',
    \   'filename':         'LightlineFilename',
    \   'inactivefilename': 'LightlineInactiveFilename',
    \   'lineinfo':         'LightlineLineinfo',
    \   'percent':          'LightlinePercent',
    \   'spaces': 'LightlineTabsOrSpacesStatus',
    \ },
    \ 'component_expand': {
    \   'linter_warnings': 'lightline#ale#warnings',
    \   'linter_errors': 'lightline#ale#errors',
    \   'linter_ok': 'lightline#ale#ok',
    \ },
    \ 'component_type': {
    \   'linter_warnings': 'warning',
    \   'linter_errors': 'error',
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
