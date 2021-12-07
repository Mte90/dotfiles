-- set default notification thing to nvim-notify
vim.notify = require("notify")
require('dressing').setup({
  input = {
    -- These can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
    prefer_width = 40,
    max_width = nil,
    min_width = 20,

  },
  select = {
    backend = { "fzf", "builtin" },
    fzf = {
      window = {
        width = 0.5,
        height = 0.4,
      },
    },
    builtin = {
      -- These can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
      width = nil,
      max_width = 0.8,
      min_width = 40,
      height = nil,
      max_height = 0.9,
      min_height = 10,
    },
  },
})
