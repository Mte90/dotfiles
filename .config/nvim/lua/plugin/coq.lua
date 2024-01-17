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

require("coq_3p") {
  { src = "dap" },
  { src = "builtin/js"      },
  { src = "builtin/php"     },
  { src = "builtin/html"    },
  { src = "builtin/css"     },
}
