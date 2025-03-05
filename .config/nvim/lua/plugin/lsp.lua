local nvim_lsp = require('lspconfig') -- composer global require php-stubs/wordpress-globals php-stubs/wordpress-stubs php-stubs/woocommerce-stubs php-stubs/acf-pro-stubs wpsyntex/polylang-stubs php-stubs/genesis-stubs php-stubs/wp-cli-stubs
local configs = require'lspconfig/configs'
local util = require'lspconfig/util'

vim.lsp.set_log_level("off")

require('lspkind').init()
require("lsp_lines").setup()

local on_attach = function(client, bufnr)
    vim.lsp.completion.enable(true, client, bufnr, {autotrigger=true})
    require'lsp_signature'.on_attach({
        bind = true,
        floating_window = true,
        handler_opts = {
            border = "rounded"
        }
    })

    if client.server_capabilities.documentHighlightProvider then
        vim.api.nvim_create_augroup('lsp_document_highlight', {
            clear = false
        })

        vim.api.nvim_clear_autocmds({
            buffer = bufnr,
            group = 'lsp_document_highlight',
        })

        vim.api.nvim_create_autocmd({'CursorHold', 'CursorHoldI'}, {
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

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true
}

capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {'documentation', 'detail', 'additionalTextEdits',}
}

local coq = require("coq")
capabilities = coq.lsp_ensure_capabilities(capabilities)
nvim_lsp.intelephense.setup({
    settings = {
        intelephense = {
            stubs = {"bcmath", "bz2", "Core", "curl", "date", "dom", "fileinfo", "filter", "gd", "gettext", "hash", "iconv", "imap", "intl", "json", "libxml", "mbstring", "mcrypt", "mysql", "mysqli", "password", "pcntl", "pcre", "PDO", "pdo_mysql", "Phar", "readline", "regex", "session", "SimpleXML", "sockets", "sodium", "standard", "superglobals", "tokenizer", "xml", "xdebug", "xmlreader", "xmlwriter", "yaml", "zip", "zlib", "wordpress-stubs", "woocommerce-stubs", "acf-pro-stubs", "wordpress-globals", "wp-cli-stubs", "genesis-stubs", "polylang-stubs"},
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
})

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

nvim_lsp.tailwindcss.setup{
    capabilities = capabilities,
    on_attach = on_attach
}
require("tailwind-tools").setup()
-- I am getting an invalid client ID
-- nvim_lsp.typos_lsp.setup{
--     capabilities = capabilities,
--     on_attach = on_attach,
--     init_options = {
--         diagnosticSeverity = 'Warning',
--     },
-- }
nvim_lsp.emmet_language_server.setup{
    capabilities = capabilities,
    on_attach = on_attach
}
nvim_lsp.gitlab_ci_ls.setup{
    capabilities = capabilities,
    on_attach = on_attach
}
nvim_lsp.htmx.setup{
    capabilities = capabilities,
    on_attach = on_attach
}
nvim_lsp.jsonls.setup{}
nvim_lsp.lua_ls.setup {
  capabilities = capabilities,
  on_attach = on_attach,
  on_init = function(client)
    local path = client.workspace_folders[1].name
    if vim.loop.fs_stat(path..'/.luarc.json') or vim.loop.fs_stat(path..'/.luarc.jsonc') then
      return
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = {
        version = 'LuaJIT'
      },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME
        }
      }
    })
  end,
  settings = {
    Lua = {}
  }
}
nvim_lsp.marksman.setup{
    capabilities = capabilities,
    on_attach = on_attach
}
nvim_lsp.ruby_lsp.setup{
    capabilities = capabilities,
    on_attach = on_attach
}

require'py_lsp'.setup({
    language_server = "pylsp",
    source_strategies = {"poetry", "hatch", "default", "system"},
    capabilities = capabilities,
    on_attach = on_attach,
    pylsp_plugins = {
        pyls_mypy = {
            enabled = true
        },
        rope_autoimport = {
            enabled = true
        },
        rope_completion = {
            enabled = true
        },
        pyls_isort = {
            enabled = true
        },
        pycodestyle = {
            enabled = false,
        },
        flake8 = {
            enabled = false,
        }
    }
})

-- I want to be sure that there isn't any pycodestyle
local function filter_diagnostics(diagnostic)
  if diagnostic.source == 'pycodestyle'then
    return false
  end
  return true
end

vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
  function(_, result, ctx, config)
    result.diagnostics = vim.tbl_filter(filter_diagnostics, result.diagnostics)
    vim.lsp.diagnostic.on_publish_diagnostics(_, result, ctx, config)
  end,
  {}
)

require'nvim-lightbulb'.update_lightbulb({
    sign = {
        enabled = true,
        priority = 10,
    },
    float = {
        enabled = false,
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
    callback = function() require'nvim-lightbulb'.update_lightbulb() end,
})

local notify = require'notify'
vim.lsp.handlers['window/showMessage'] = function(_, result, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    local lvl = ({'ERROR', 'WARN', 'INFO', 'DEBUG',})[result.type]
    notify(result.message, lvl, {
        title = 'LSP | ' .. client.name,
        timeout = 10000,
        keep = function() return lvl == 'ERROR' or lvl == 'WARN' end,
    })
end

require('tw-values').setup({
    show_unknown_classes = true,
})

vim.g.tabby_agent_start_command = {"npx", "tabby-agent", "--stdio"}
vim.g.tabby_inline_completion_trigger = "manual"
vim.g.tabby_inline_completion_keybinding_accept = "<leader>,"
