local phpcs = require('lint.linters.phpcs')
local util = require("formatter.util")
phpformatter = {
    tempfile_dir = '/tmp/',
    args = {},
    stdin = false,
}

phpcs.args = {
    '-q', -- TODO search for artisan to load a different standard
    '--standard=CodeatCodingStandard',
    '--exclude=Generic.Commenting.Todo,Squiz.PHP.CommentedOutCode',
    '--report=json',
    '-'
}

phpformatter = {
    tempfile_dir = '/tmp/',
    args = {'--standard=CodeatCodingStandard'},
    stdin = false,
}

vim.api.nvim_create_autocmd({"DirChanged"}, {
    callback = function()
        local path = vim.fn.getcwd() .. '/vendor/bin/phpcs'
        if file_exists(path) then phpcs.cmd = path end
        local path = vim.fn.getcwd() .. '/vendor/bin/phpcbf'
        if file_exists(path) then phpformatter.exe = path end
    end,
})

-- Get flake8 global or from venv
flake8 = require('lint.linters.flake8')
flake8.cmd = venv_bin_detection("flake8")

require('lint').linters_by_ft = {
    sh = {'shellcheck'},
    yaml = {'yamlint'},
    sass = {'stylelint'},
    scss = {'stylelint'},
    css = {'stylelint'},
    php = {'phpcs'},
    js = {'eslint'},
    python = {'flake8'},
}

vim.api.nvim_create_autocmd({"BufWritePost", "TextChanged"}, {
    callback = function()
        require("lint").try_lint()
    end,
})

require('formatter').setup{
    filetype = {
        javascript = {eslint_fmt, prettier},
        css = prettier,
        scss = prettier,
        json = prettier,
        html = prettier,
        php = {
            function()
                table.insert(phpformatter.args, util.escape_path(util.get_current_buffer_file_path()))
                return phpformatter
            end
        },
        python = {
            {
                exe = venv_bin_detection("isort"), -- Get isort global or from venv
                args = { "-q", "--filename", util.escape_path(util.get_current_buffer_file_path()), "-" },
                stdin = true,
            },
        }
    }
}

vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup("Format", {
        clear = true
    }),
    pattern = '*',
    command = 'FormatWrite',
})

vim.api.nvim_create_autocmd({'InsertLeave', 'FocusLost'}, {
    group = vim.api.nvim_create_augroup("Format", {
        clear = true
    }),
    pattern = '*',
    command = 'Format',
})

vim.api.nvim_create_autocmd({"BufEnter", "CursorHold", "CursorHoldI", "FocusGained"}, {
    command = "if mode() != 'c' | checktime | endif",
    pattern = {"*"},
})
