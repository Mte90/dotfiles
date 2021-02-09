-- composer global require php-stubs/wordpress-globals
-- composer global require php-stubs/wordpress-stubs
-- composer global require php-stubs/woocommerce-stubs
local nvim_lsp = require'lspconfig'
local configs  = require'lspconfig/configs'
local util     = require'lspconfig/util'
nvim_lsp.intelephense.setup({
    settings = {
        intelephense = {
            stubs = { 
                "bcmath",
                "bz2",
                "calendar",
                "Core",
                "curl",
                "date",
                "dba",
                "dom",
                "enchant",
                "fileinfo",
                "filter",
                "ftp",
                "gd",
                "gettext",
                "hash",
                "iconv",
                "imap",
                "intl",
                "json",
                "ldap",
                "libxml",
                "mbstring",
                "mcrypt",
                "mysql",
                "mysqli",
                "password",
                "pcntl",
                "pcre",
                "PDO",
                "pdo_mysql",
                "Phar",
                "readline",
                "recode",
                "Reflection",
                "regex",
                "session",
                "SimpleXML",
                "soap",
                "sockets",
                "sodium",
                "SPL",
                "standard",
                "superglobals",
                "sysvsem",
                "sysvshm",
                "tokenizer",
                "xml",
                "xdebug",
                "xmlreader",
                "xmlwriter",
                "yaml",
                "zip",
                "zlib",
                "wordpress",
                "woocommerce"
            },
            files = {
                maxSize = 5000000;
            };
        };
    }; 
});

nvim_lsp.cssls.setup{}
nvim_lsp.html.setup{}
nvim_lsp.bashls.setup{}

vim.api.nvim_command([[
    au User lsp_setup call lsp#register_server({
     \ 'name': 'psalm-language-server',
     \ 'cmd': '/home/mte90/.composer/vendor/bin/psalm-language-server',
     \ 'whitelist': ['php'],
     \ })

au User lsp_setup call lsp#register_server({
     \ 'name': 'kite',
     \ 'cmd': '~/.local/share/kite/current/kite-lsp --editor=vim',
     \ 'whitelist': ["php", "javascript", "python", "bash"],
     \ })                   
]]);
