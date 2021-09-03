vim.g.coq_settings = {
    auto_start = true,
    clients = {
        lsp = {
          enabled = true,
        },
        tree_sitter = {
          enabled = true,
        },
        tabnine =  {
          enabled = true,
        }
    }
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
