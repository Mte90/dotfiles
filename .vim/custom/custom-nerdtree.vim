" nerdtree configuration
function! NERDTreeToggleInCurDir()
  " If NERDTree is open in the current buffer
  if (exists('t:NERDTreeBufName') && bufwinnr(t:NERDTreeBufName) != -1)
    exe ':NERDTreeClose'
  else
    if (expand('%:t') != '')
      exe ':NERDTreeFind'
    else
      exe ':NERDTreeToggle'
    endif
  endif
endfunction 
"  don't display informations (type ? for help and so on)
let g:NERDTreeMinimalUI = 1
"  don't replace the native vim file explorer
let g:NERDTreeHijackNetrw = 1
let g:NERDTreeChDirMode = 2
let g:NERDTreeAutoDeleteBuffer = 1
let g:NERDTreeShowBookmarks = 0
let g:NERDTreeCascadeOpenSingleChildDir = 1
let g:NERDTreeWinSize=35
"  change the arrows
let g:NERDTreeDirArrowExpandable = ''
let g:NERDTreeDirArrowCollapsible = ''
"  ignore files
let NERDTreeIgnore = [
	\ '\.git$', '\.hg$', '\.svn$', '\.stversions$', '\.pyc$', '\.svn$', '__init__.py', 'vendor',
	\ '\.DS_Store$', '\.sass*$', '__pycache__$', '\.egg-info$', '\.cache$','composer.lock','node_modules'
\ ]
" Webdevicons
let g:webdevicons_enable = 1
let g:webdevicons_enable_nerdtree = 1
let entry_format = "'   ['. index .']'. repeat(' ', (3 - strlen(index)))"
let g:WebDevIconsNerdTreeGitPluginForceVAlign = 1
let g:WebDevIconsNerdTreeAfterGlyphPadding    = ' '
let entry_format .= '. entry_path'
if exists('*WebDevIconsGetFileTypeSymbol')  " support for vim-devicons
  let entry_format .= ". WebDevIconsGetFileTypeSymbol(entry_path) .' '.  entry_path"
endif
function! NERDTreeRefresh()
    if &filetype == "nerdtree"
        silent exe substitute(mapcheck("R"), "<CR>", "", "")
    endif
endfunction

autocmd BufEnter * call NERDTreeRefresh()
