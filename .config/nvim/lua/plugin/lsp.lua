-- composer global require php-stubs/wordpress-globals php-stubs/wordpress-stubs php-stubs/woocommerce-stubs php-stubs/acf-pro-stubs wpsyntex/polylang-stubs php-stubs/genesis-stubs php-stubs/wp-cli-stubs
local nvim_lsp = require'lspconfig'
local configs  = require'lspconfig/configs'
local util     = require'lspconfig/util'
local lsp_installer = require("nvim-lsp-installer")

-- Check if WordPress mode
is_wp, message = pcall(function()
    return vim.api.nvim_get_var("wordpress_mode")
  end)

local on_attach = function(client, bufnr)
    require 'lsp_signature'.on_attach({
      bind = true,
      floating_window = true,
      handler_opts = {
        border = "rounded"
      }
    })
    require("aerial").on_attach(client, bufnr)
    if client.server_capabilities.document_highlight then
      vim.api.nvim_create_augroup('lsp_document_highlight', {
        clear = false
      })
      vim.api.nvim_clear_autocmds({
        buffer = bufnr,
        group = 'lsp_document_highlight',
      })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        group = 'lsp_document_highlight',
        buffer = bufnr,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd('CursorMoved', {
        group = 'lsp_document_highlight',
        buffer = bufnr,
        callback = vim.lsp.buf.clear_references,
      })
    end
end
require('lspkind').init()
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true
}
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
                "Core",
                "curl",
                "date",
                "dom",
                "fileinfo",
                "filter",
                "gd",
                "gettext",
                "hash",
                "iconv",
                "imap",
                "intl",
                "json",
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
                "regex",
                "session",
                "SimpleXML",
                "sockets",
                "sodium",
                "standard",
                "superglobals",
                "tokenizer",
                "xml",
                "xdebug",
                "xmlreader",
                "xmlwriter",
                "yaml",
                "zip",
                "zlib",
                "wordpress-stubs",
                "woocommerce-stubs",
                "acf-pro-stubs",
                "wordpress-globals",
                "wp-cli-stubs",
                "genesis-stubs",
                "polylang-stubs"
            },
            environment = {
              includePaths = {'/home/mte90/.composer/vendor/php-stubs/', '/home/mte90/.composer/vendor/wpsyntex/'}
            },
            files = {
                maxSize = 5000000;
            };
        };
    },
    capabilities = capabilities,
    on_attach = on_attach
});
if is_wp == false then
  local phpactor_capabilities = vim.lsp.protocol.make_client_capabilities()
  phpactor_capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true
  }
  phpactor_capabilities['textDocument']['codeAction'] = {}
  nvim_lsp.phpactor.setup{
      capabilities = phpactor_capabilities,
      on_attach = on_attach
  }
end
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

vim.api.nvim_create_autocmd({'CursorHoldI', 'CursorHold'}, {
  pattern = '*',
  callback = function()
    require'nvim-lightbulb'.update_lightbulb()
  end,
})

require("lsp_lines").setup()

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
