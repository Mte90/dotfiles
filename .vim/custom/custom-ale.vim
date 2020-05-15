" Ale linting (installed on system: phpmd, phpcs, coffeelint, sass-lint, htmlhint, prettier)
let g:ale_php_phpcs_standard  = '/home/mte90/Desktop/Prog/CodeatCS/codeat.xml'
let g:ale_php_phpcbf_standard  = '/home/mte90/Desktop/Prog/CodeatCS/codeat.xml'
let g:ale_php_phpmd_ruleset = '/home/mte90/Desktop/Prog/CodeatCS/codeat-phpmd.xml'
let g:ale_php_cs_fixer_options = 'position_after_functions_and_oop_constructs=same'
let g:ale_php_psalm_executable      = '/usr/local/bin/psalm'

function LoadNewPHPCS()
    " Wait Rooter that set the path
    sleep 100m
    if filereadable(getcwd() . '/phpcs.xml')
        let g:ale_php_phpcs_standard = getcwd() . '/phpcs.xml'
    endif
endfunction
augroup PHP
  autocmd!
  autocmd BufReadPost,BufNewFile *.php call LoadNewPHPCS()
augroup END

let g:ale_linters = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'bash': ['shellcheck'],
\   'coffee': ['coffeelint'],
\   'css': ['prettier'],
\   'html': ['htmlhint'],
\   'javascript': ['eslint', 'jshint'],
\   'markdown': ['remark-lint'],
\   'php': ['phpcs', 'phpmd', 'psalm', 'phpstan'],
\   'sass': ['sass-lint'],
\   'scss': ['sass-lint'],
\}
 " removed php_cs_fixer
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'bash': ['shellcheck'],
\   'coffee': ['coffeelint'],
\   'css': ['prettier'],
\   'html': ['htmlhint', 'prettier', 'jshint'],
\   'javascript': ['eslint', 'prettier'],
\   'markdown': ['remark-lint'],
\   'php': ['phpcbf'],
\   'sass': ['sass-lint'],
\   'scss': ['sass-lint'],
\}
let g:PHP_vintage_case_default_indent = 1
" Sometimes phpcbf replace the content of the file with the output of the command with ale
let g:ale_fix_on_save = 1
let g:ale_sign_error = 'EE'
let g:ale_sign_warning = 'WW'
let g:ale_change_sign_column_color = 1
let g:ale_completion_enabled = 1 
