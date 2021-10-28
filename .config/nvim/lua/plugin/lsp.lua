-- composer global require php-stubs/wordpress-globals php-stubs/wordpress-stubs php-stubs/woocommerce-stubs php-stubs/acf-pro-stubs wpsyntex/polylang-stubs php-stubs/genesis-stubs php-stubs/wp-cli-stubs
local nvim_lsp = require'lspconfig'
local configs  = require'lspconfig/configs'
local util     = require'lspconfig/util'

local lsp_installer = require("nvim-lsp-installer")

local on_attach = function(client, bufnr)
    require 'lsp_signature'.on_attach({
      bind = true,
      handler_opts = {
        border = "single"
      }
    })
end
require("trouble").setup {
    mode = "quickfix", 
    auto_open = true,
    auto_close = true
}
require('lspkind').init()
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    'documentation',
    'detail',
    'additionalTextEdits',
  }
}

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
                "woocommerce",
                "acf-pro",
                "wordpress-globals",
                "wp-cli",
                "genesis",
                "polylang"
            },
            files = {
                maxSize = 5000000;
            };
        };
    },
    capabilities = capabilities,
    on_attach = on_attach
});
nvim_lsp.phpactor.setup{}
nvim_lsp.cssls.setup{
    capabilities = capabilities,
    on_attach = on_attach
}
nvim_lsp.html.setup{
    capabilities = capabilities,
    on_attach = on_attach
}
nvim_lsp.bashls.setup{
    capabilities = capabilities,
    on_attach = on_attach
}

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

vim.cmd [[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()]]

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    underline = false,
    virtual_text = true,
    signs = true,
    update_in_insert = true,
  }
)

vim.ui.select = require"popui.ui-overrider"
vim.api.nvim_command([[autocmd CursorHold <cmd>lua vim.lsp.buf.code_action()<CR>]])
