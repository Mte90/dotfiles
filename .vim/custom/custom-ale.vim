" Ale linting
let g:ale_php_phpcbf_executable = $HOME.'/.vim/custom/php-cbf-helper.sh'
let g:ale_php_phpcbf_use_global = 1
if !exists('wordpress_mode')
    let g:ale_php_phpcs_standard  = 'CodeatCodingStandard'
    let g:ale_php_phpcbf_standard  = 'CodeatCodingStandard'
    let g:ale_php_phpmd_ruleset = '/home/mte90/Desktop/Prog/CodeatCS/codeat-phpmd.xml'
    let g:ale_php_cs_fixer_options = 'position_after_functions_and_oop_constructs=same'
    let g:ale_php_psalm_executable = '/usr/local/bin/psalm'
    let g:ale_php_phpstan_executable = $HOME.'/.composer/vendor/bin/phpstan'
else
    let g:ale_php_phpcs_standard  = 'WordPress-Core'
    let g:ale_php_phpcbf_standard  = 'WordPress-Core'
endif
let g:ale_scss_sasslint_executable = '/usr/bin/sass-lint'
let g:ale_php_phpcs_use_global = 1
let g:ale_php_cs_fixer_use_global = 1
let g:ale_disable_lsp = 1
let g:ale_completion_enabled = 0


function LoadNewPHPStan()
    " Wait Rooter that set the path
    sleep 100m
    if filereadable(getcwd() . '/phpstan.neon')
        let g:ale_php_phpstan_configuration = getcwd() . '/phpstan.neon'
    else
        let g:ale_php_phpstan_configuration = '/home/mte90/Desktop/Prog/CodeatCS/codeat-phpstan.neon'
    endif
endfunction
augroup PHP
  autocmd!
  autocmd BufReadPost,BufNewFile *.php call LoadNewPHPStan()
  autocmd BufWritePost * silent! !$HOME'/.vim/custom/indent-comment.sh' <afile>
augroup END

if !exists('wordpress_mode')
    let g:ale_linters = {
    \   '*': ['remove_trailing_lines', 'trim_whitespace'],
    \   'bash': ['shellcheck'],
    \   'css': ['prettier'],
    \   'html': ['htmlhint'],
    \   'javascript': ['eslint', 'jshint'],
    \   'markdown': ['remark-lint'],
    \   'php': ['phpcs', 'phpmd', 'psalm', 'phpstan'],
    \   'sass': ['sass-lint'],
    \}

    let g:ale_fixers = {
    \   '*': ['remove_trailing_lines', 'trim_whitespace'],
    \   'bash': ['shellcheck'],
    \   'css': ['prettier'],
    \   'html': ['htmlhint', 'prettier', 'jshint'],
    \   'javascript': ['eslint', 'prettier'],
    \   'markdown': ['remark-lint'],
    \   'sass': ['sass-lint'],
    \   'php': ['php_cs_fixer', 'phpcbf'],
    \}
else
    let g:ale_linters = {
    \   '*': ['trim_whitespace'],
    \   'html': ['htmlhint'],
    \   'javascript': ['eslint', 'jshint'],
    \   'php': ['phpcs'],
    \   'sass': ['sass-lint'],
    \   'scss': ['sass-lint'],
    \}

    let g:ale_fixers = {
    \   '*': ['trim_whitespace'],
    \   'sass': ['sass-lint'],
    \   'php': ['phpcbf'],
    \}
endif
let g:PHP_vintage_case_default_indent = 1

let g:ale_fix_on_save = 1
let g:ale_sign_error = ''
let g:ale_sign_warning = ''
let g:ale_change_sign_column_color = 1
let g:ale_completion_enabled = 0
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
