" deoplete
let g:deoplete#enable_at_startup = 1
let g:deoplete#min_pattern_length = 1
let g:deoplete#max_candidates = 30
"  deoplete tab-complete
let g:deoplete#file#enable_buffer_path = 1
let g:deoplete#enable_smart_case = 1
let g:deoplete#enable_camel_case = 1
"  Other stuff
call deoplete#custom#option('sources', {
		\ '_': ['buffer'],
		\ 'php': ['tabnine', 'phpcd', 'ultisnips', 'omni'],
		\ 'css': ['tabnine', 'omni', 'ultisnips'],
		\ 'js': ['tabnine', 'omni', 'ultisnips'],
		\ 'html': ['tabnine', 'omni', 'ultisnips'],
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
