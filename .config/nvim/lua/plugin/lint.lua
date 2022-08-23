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
      args = {'--standard=CodeatCodingStandard'},
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
      args = {'--standard=WordPress-Core'},
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

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  callback = function()
    if is_wp == false then
      phpcs.cmd = vim.fn.getcwd() .. '/vendor/bin/phpcs'
    end
    require("lint").try_lint()
  end,
})

require('formatter').setup {
  tempfile_dir = '/tmp/',
  filetype = {
    javascript = {eslint_fmt, prettier},
    css = prettier,
    scss = prettier,
    json = prettier,
    html = prettier,
    php = {
      function ()
        if is_wp == false then
          phpformatter.exe = vim.fn.getcwd() .. '/vendor/bin/phpcbf'
        end
        table.insert(phpformatter.args, util.escape_path(util.get_current_buffer_file_path()))
        return phpformatter
      end
    }
  }
}

vim.api.nvim_create_autocmd('BufWritePost', {
  group = vim.api.nvim_create_augroup("Format", { clear = true }),
  pattern = '*',
  command = 'FormatWrite',
})

vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = { "*" },
})

vim.diagnostic.config({
  virtual_text = false,
  float = {
    source = "always",
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  callback = function()
    vim.diagnostic.open_float(nil, {focus=false})
  end,
})
