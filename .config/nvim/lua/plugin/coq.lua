vim.g.coq_settings = {
    auto_start = true,
    clients = {
        lsp = {
          enabled = true,
        },
        tree_sitter = {
          enabled = true,
          weight_adjust = 1.0
        },
        tabnine = {
          enabled = false,
        },
        snippets = {
          user_path = '/home/mte90/.config/nvim/lua/coq-user-snippets',
          weight_adjust = 2
        },
    },
}

local coq = require("coq")

-- https://github.com/saweima12/nvimenv/blob/3a239cc068150e9908b03ab12206c12a94ea760c/.config/nvim/lua/partial/lsp.lua#L24
local install_servers = require('nvim-lsp-installer.servers')
local gset = vim.api.nvim_set_var
local partial = {}

-- loading lsp.%s module for configure lsp setting.
partial.setup = function()
  local servers = {}

  servers = install_servers.get_installed_servers()

  for _, server in pairs(servers) do
    local config = partial.make_config()
    local lsp_ext_path = string.format("lsp.%s", server.name)

    local ok, lspconf = pcall(require, lsp_ext_path)

    if ok then
      lspconf.attach(config)
    end
    local coq = require('coq')

    server:setup(coq.lsp_ensure_capabilities(config))
  end
end

-- generate lsp config base.
partial.make_config = function()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  -- add snippet supoort.
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  return {
    capabiities = capabilities,
    on_attach=function(client, bufnr)
      vim.lsp_attach_keybind(client, bufnr)
      return require('coq').lsp_ensure_capabilities()
    end
  }
end
