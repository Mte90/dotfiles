
-- https://github.com/xdebug/vscode-php-debug/releases
-- Extract the vsix content
local dap = require'dap'
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
      -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
      -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
      -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
      local cwd = vim.fn.getcwd()
      if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
        return cwd .. '/venv/bin/python'
      elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
        return cwd .. '/.venv/bin/python'
      else
        return '/usr/bin/python'
      end
    end

dap.configurations.python = {
    {
        type = 'python',
        request = 'launch',
        name = 'Django',
        program = "poetry run " .. vim.fn.getcwd() .. '/manage.py',
        args = {'runserver', '--noreload'},
        pythonPath = pythonPath()
    }
}

dap.adapters.python = {
  type = 'executable',
  command = "poetry run " .. pythonPath(),
  args = { '-m', 'debugpy.adapter' }
}
require('dap-python').setup()
require("nvim-dap-virtual-text").setup()
require("dapui").setup()
