lua << EOF
-- composer global require php-stubs/wordpress-globals
-- composer global require php-stubs/wordpress-stubs
-- composer global require php-stubs/woocommerce-stubs
local nvim_lsp = require'nvim_lsp'
local util = require 'nvim_lsp/util'
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
EOF

au User lsp_setup call lsp#register_server({
     \ 'name': 'psalm-language-server',
     \ 'cmd': '/home/mte90/.composer/vendor/bin/psalm-language-server',
     \ 'whitelist': ['php'],
     \ })
