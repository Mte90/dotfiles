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
          enabled = true,
        },
        snippets = {
          user_path = '/home/mte90/.config/nvim/lua/coq-user-snippets',
          weight_adjust = 1.4
        },
    },
}

local coq = require("coq")

local servers = require("lspinstall").installed_servers()
for _, server in pairs(servers) do
  if vim.g.lsp_config[server] then
    lsp[server].setup(coq.lsp_ensure_capabilities(vim.g.lsp_config[server]))
  else
    lsp[server].setup(coq.lsp_ensure_capabilities())
  end
end
