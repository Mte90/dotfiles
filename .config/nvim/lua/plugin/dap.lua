vim.g.dap_virtual_text = true
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
        hostname = '0.0.0.0',
        port = '9003',
        stopOnEntry = false,
        serverSourceRoot = '/srv/www/',
        localSourceRoot = '/var/www/VVV/www/',
    },
}
