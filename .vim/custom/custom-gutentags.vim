" GutenTags
let g:gutentags_enabled                  = 1
let g:gutentags_generate_on_missing      = 1
let g:gutentags_generate_on_new          = 1
let g:gutentags_generate_on_write        = 1
let g:gutentags_define_advanced_commands = 1
let g:gutentags_resolve_symlinks         = 1
let g:gutentags_file_list_command = {
      \ 'markers': {
      \   '.git': 'git ls-files'
      \ },
\ }
let g:gutentags_ctags_exclude = [
      \ '*lock', '*.json', '*.xml', '*.yml',
      \ '*.phar', '*.ini', '*.rst', '*.md',
      \ '*vendor/*/test*', '*lib/**',
      \ '*vendor/**', '*tests*',
      \ '*var/cache*', '*var/log*'
\ ]
let g:gutentags_cache_dir = '~/.vim/tags/'
let g:gutentags_project_root = ['/var/www/VVV/www/', '/home/mte90/Desktop/VVV/www/'] 
