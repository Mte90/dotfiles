local phpcs = require('lint.linters.phpcs')
-- Check if WordPress mode
is_wp, message = pcall(function()
    return vim.api.nvim_get_var("wordpress_mode")
  end)
local util = require("formatter.util")
if is_wp == false then
    phpcs.args = {
        '-q',
        '--standard=CodeatCodingStandard',
        '--report=json',
        '-'
    }
    phpformatter = {
      args = {'--standard=CodeatCodingStandard', util.escape_path(util.get_current_buffer_file_path())},
      stdin = false,
    }
else
    phpcs.args = {
        '-q',
        '--standard=WordPress-Core',
        '--report=json',
        '-'
    }
    phpformatter = {
      args = {'--standard=WordPress-Core', util.escape_path(util.get_current_buffer_file_path())},
      stdin = false,
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

require('formatter').setup {
  filetype = {
    javascript = {eslint_fmt, prettier},
    css = prettier,
    scss = prettier,
    json = prettier,
    html = prettier,
    php = {
      function ()
        phpformatter.exe = vim.fn.getcwd() .. '/vendor/bin/phpcbf'
        return phpformatter
      end
    }
  }
}

vim.api.nvim_create_autocmd('BufWritePost', {
  group = group,
  pattern = '*',
  command = 'silent! FormatWrite',
})

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
