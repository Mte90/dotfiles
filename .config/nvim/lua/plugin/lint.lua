local phpcs = require('lint.linters.phpcs')
-- Check if WordPress mode
is_wp, message = pcall(function()
    return vim.api.nvim_get_var("wordpress_mode")
  end)
if is_wp == false then
    phpcs.args = {
        '-q',
        '--standard=CodeatCodingStandard',
        '--report=json',
        '-'
    }
else
    phpcs.args = {
        '-q',
        '--standard=WordPress-Core',
        '--report=json',
        '-'
    }
end

require('lint').linters_by_ft = {
  sh = { 'shellcheck' },
  yaml = { 'yamlint' },
  sass = { 'stylelint' },
  scss = { 'stylelint' },
  css = { 'stylelint' },
  php = { 'phpcs' },
  js = { 'eslint' },
}

vim.api.nvim_command([[
autocmd BufWritePost <buffer> lua require('lint').try_lint()
autocmd BufRead <buffer> lua require('lint').try_lint()
autocmd InsertLeave <buffer> lua require('lint').try_lint()
autocmd TextChanged <buffer> lua require('lint').try_lint()
let g:neoformat_run_all_formatters = 1

if exists('wordpress_mode')
    function! neoformat#formatters#php#wordpressphpcbf() abort
    return {
            \ 'exe': 'phpcbf',
            \ 'args': ['--standard=WordPress-Core'],
            \ 'stdin': 1,
            \ 'valid_exit_codes': [0, 1]
            \ }
    endfunction

    let g:neoformat_enabled_php = ['wordpress-phpcbf']
else
    function! neoformat#formatters#php#codeatphpcbf() abort
    return {
            \ 'exe': 'phpcbf',
            \ 'args': ['--standard=CodeatCodingStandard'],
            \ 'stdin': 1,
            \ 'valid_exit_codes': [0, 1]
            \ }
    endfunction
    let g:neoformat_enabled_php = ['php-cs-fixer', 'codeatphpcbf']
    let g:neoformat_enabled_css = ['stylelint']
    let g:neoformat_enabled_sass = ['stylelint']
    let g:neoformat_enabled_html = ['prettier']
    let g:neoformat_enabled_js = ['prettier', 'eslint']
    let g:neoformat_enabled_markdown = ['remark']
endif

augroup fmt
  autocmd!
  autocmd BufWritePre * undojoin | Neoformat
augroup END
]]);

vim.diagnostic.config({
  virtual_text = {
    source = "always",
  },
  float = {
    source = "always",
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

vim.cmd [[autocmd CursorHold,CursorHoldI * lua vim.diagnostic.open_float(nil, {focus=false})]]
