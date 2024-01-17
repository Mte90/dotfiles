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

local set_python_dap = function()
    require('dap-python').setup() -- earlier so setup the various defaults ready to be replaced
    dap.configurations.python = {
        {
            type = 'python';
            request = 'launch';
            name = "Launch file";
            program = "${file}";
            pythonPath = venv_python_path()
        },
        {
            type = 'python',
            request = 'launch',
            name = 'DAP Django',
            program = vim.loop.cwd() .. '/manage.py',
            args = {
                'runserver', --'--nothreading',
                '--noreload'
            },
            justMyCode = true,
            django = true,
            console = "integratedTerminal", --             subProcess = true, trying to understand if nvim-dap support it
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
            pythonPath = venv_python_path()
        }
    }

    dap.adapters.python = {
        type = 'executable',
        command = venv_python_path(),
        args = {'-m', 'debugpy.adapter'}
    }
end

set_python_dap()
vim.api.nvim_create_autocmd({"DirChanged"}, {
    callback = function() set_python_dap() end,
})

require("nvim-dap-virtual-text").setup()
require("dapui").setup({
    layouts = {
        {
            elements = {
                {
                    id = "scopes",
                    size = 0.70
                },
                {
                    id = "breakpoints",
                    size = 0.10
                },
                {
                    id = "stacks",
                    size = 0.20
                }
            },
            position = "left",
            size = 50
        },
        {
            elements = {
                {
                    id = "repl",
                    size = 1
                }
            },
            position = "bottom",
            size = 10
        }
    },
})
