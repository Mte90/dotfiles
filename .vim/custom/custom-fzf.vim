let g:fzf_action = {
  \ 'return': 'tab split',
\}

command! -bang -nargs=? -complete=dir Files
  \ call fzf#vim#files(<q-args>,
  \ fzf#vim#with_preview(),
  \ <bang>0)
