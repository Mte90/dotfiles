local dap = require'dap' -- https://github.com/xdebug/vscode-php-debug/releases -- Extract the vsix content
vim.fn.sign_define('DapBreakpoint', {
    text = '⬤',
    texthl = 'ErrorMsg',
    linehl = '',
    numhl = 'ErrorMsg'
})

vim.fn.sign_define('DapBreakpointCondition', {
    text = '⬤',
    texthl = 'ErrorMsg',
    linehl = '',
    numhl = 'SpellBad'
})

dap.adapters.php = {
    type = 'executable',
    command = 'nodejs',
    args = {"/opt/vscode-php-debug/out/phpDebug.js"},
}

dap.configurations.php = {
    {
        type = 'php',
        request = 'launch',
        name = 'Listen for xdebug',
        port = '9003',
        log = true,
        serverSourceRoot = '/srv/www/',
        localSourceRoot = '/home/www/VVV/www/',
    },
}

local pythonPath = function()
    local cwd = vim.loop.cwd()
    if vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
        return cwd .. '/.venv/bin/python'
    else
        return '/usr/bin/python'
    end
end

local set_python_dap = function()
    require('dap-python').setup() -- earlier so setup the various defaults ready to be replaced
    dap.configurations.python = {
        {
            type = 'python';
            request = 'launch';
            name = "Launch file";
            program = "${file}";
            pythonPath = pythonPath()
        },
        {
            type = 'python',
            request = 'launch',
            name = 'DAP Django',
            program = vim.loop.cwd() .. '/manage.py',
            args = {'runserver', '--noreload'},
            justMyCode = true,
            django = true,
            console = "integratedTerminal",
        },
        {
            type = 'python';
            request = 'attach';
            name = 'Attach remote';
            connect = function()
                return {
                    host = '127.0.0.1',
                    port = 5678
                }
            end;
        },
        {
            type = 'python';
            request = 'launch';
            name = 'Launch file with arguments';
            program = '${file}';
            args = function()
                local args_string = vim.fn.input('Arguments: ')
                return vim.split(args_string, " +")
            end;
            console = "integratedTerminal",
            pythonPath = pythonPath()
        }
    }

    dap.adapters.python = {
        type = 'executable',
        command = pythonPath(),
        args = {'-m', 'debugpy.adapter'}
    }
end

set_python_dap()
vim.api.nvim_create_autocmd({"DirChanged"}, {
    callback = function() set_python_dap() end,
})

require("nvim-dap-virtual-text").setup()
require("dapui").setup()
