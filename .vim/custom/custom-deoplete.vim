" deoplete
let g:deoplete#enable_at_startup = 1
let g:deoplete#min_pattern_length = 1
let g:deoplete#skip_chars = ['(', ')']
let g:deoplete#tag#cache_limit_size = 800000
"  deoplete tab-complete
let g:deoplete#file#enable_buffer_path = 1
let g:deoplete#auto_complete_delay = 50
let g:deoplete#auto_completion_start_length = 1
"  delay for auto complete and refresh
let g:deoplete#auto_refresh_delay= 5
let g:deoplete#enable_smart_case = 1
let g:deoplete#enable_camel_case = 1
let g:deoplete#enable_refresh_always = 1
"  Other stuff
let g:deoplete#omni_patterns = {}
let g:deoplete#omni_patterns.php = '\w+|[^. \t]->\w*|\w+::\w*'
let g:deoplete#sources = {}
let g:deoplete#sources.php = ['omni', 'ultisnips', 'tag']
let g:deoplete#delimiters = ['/', '.', '::', ':', '#', '->']
let g:deoplete#ignore_sources = {}
let g:deoplete#ignore_sources.html = ['syntax']
let g:deoplete#omni#functions = get(g:, 'deoplete#omni#functions', {})
let g:deoplete#omni#functions.css = 'csscomplete#CompleteCSS'
let g:deoplete#omni#functions.html = 'htmlcomplete#CompleteTags'
let g:deoplete#omni#functions.php = 'phpcomplete#CompletePHP'
let g:deoplete#omni#input_patterns = get(g:, 'deoplete#omni#input_patterns', {})
let g:deoplete#omni#input_patterns.md = '<[^>]*'
let g:deoplete#omni#input_patterns.html = '<[^>]*'
let g:deoplete#omni#input_patterns.xml  = '<[^>]*'
let g:deoplete#omni#input_patterns.css  = '^\s\+\w\+\|\w\+[):;]\?\s\+\w*\|[@!]'
let g:deoplete#omni#input_patterns.scss = '^\s\+\w\+\|\w\+[):;]\?\s\+\w*\|[@!]'
let g:deoplete#omni#input_patterns.sass = '^\s\+\w\+\|\w\+[):;]\?\s\+\w*\|[@!]'

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
