" deoplete
let g:deoplete#enable_at_startup = 1
" maximum candidate window length
call deoplete#custom#source('_', 'max_menu_width', 80)
call deoplete#custom#option('enable_at_startup',1)
call deoplete#custom#option('min_pattern_length',1)
call deoplete#custom#option('enable_buffer_path',1)
call deoplete#custom#option('max_candidates', 30)
call deoplete#custom#option({
    \ 'auto_complete': v:true,
    \ 'smart_case': v:true,
    \ 'camel_case': v:true,
\ })
"  Other stuff
call deoplete#custom#option('sources', {
		\ '_': ['buffer'],
		\ 'php': [ 'lsp', 'wp-hooks', 'ultisnips'],
		\ 'css': ['omni', 'ultisnips'],
		\ 'js': ['omni', 'ultisnips'],
		\ 'html': ['omni', 'ultisnips'],
\})
function! s:check_back_space() abort "{{{
    let col = col('.') - 1
    return !col || getline('.')[col - 1]  =~ '\s'
endfunction "}}}
inoremap <silent><expr> <C-Space>
		\ pumvisible() ? "\<C-o>" :
		\ <SID>check_back_space() ? "\<TAB>" :
		\ deoplete#manual_complete()
inoremap <silent><expr> <s-tab>
		\ pumvisible() ? "\<C-p>" :
		\ <SID>check_back_space() ? "\<TAB>" :
		\ deoplete#manual_complete()

" Close the documentation window when completion is done
autocmd InsertLeave,CompleteDone * if pumvisible() == 0 | pclose | endif

