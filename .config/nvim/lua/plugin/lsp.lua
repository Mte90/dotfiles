-- composer global require php-stubs/wordpress-globals php-stubs/wordpress-stubs php-stubs/woocommerce-stubs php-stubs/acf-pro-stubs wpsyntex/polylang-stubs php-stubs/genesis-stubs php-stubs/wp-cli-stubs
local nvim_lsp = require'lspconfig'
local configs  = require'lspconfig/configs'
local util     = require'lspconfig/util'
local lsp_installer = require("nvim-lsp-installer")

local on_attach = function(client, bufnr)
    require 'lsp_signature'.on_attach({
      bind = true,
      floating_window = true,
      handler_opts = {
        border = "rounded"
      }
    })
    require("aerial").on_attach(client, bufnr)
    if client.resolved_capabilities.document_highlight then
        vim.cmd [[
        augroup lsp_document_highlight
            autocmd! * <buffer>
            autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
            autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
        augroup END
        ]]
    end
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
local notify = require 'notify'
vim.lsp.handlers['window/showMessage'] = function(_, result, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  local lvl = ({
    'ERROR',
    'WARN',
    'INFO',
    'DEBUG',
  })[result.type]
  notify({ result.message }, lvl, {
    title = 'LSP | ' .. client.name,
    timeout = 10000,
    keep = function()
      return lvl == 'ERROR' or lvl == 'WARN'
    end,
  })
end
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
local phpactor_capabilities = vim.lsp.protocol.make_client_capabilities()
phpactor_capabilities['textDocument']['codeAction'] = {}
nvim_lsp.phpactor.setup{
     capabilities = phpactor_capabilities,
     on_attach = on_attach
}
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

vim.ui.select = require"popui.ui-overrider"

require'nvim-lightbulb'.update_lightbulb({
  sign = {
    enabled = true,
    priority = 10,
  },
  float = {
    enabled = true,
  },
  virtual_text = {
    enabled = true,
    hl_mode = "combine",
  },
  status_text = {
    enabled = true,
  }
})
vim.cmd [[autocmd CursorHold,CursorHoldI * lua require'nvim-lightbulb'.update_lightbulb()]]
