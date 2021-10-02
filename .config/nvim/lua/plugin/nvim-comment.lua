require('nvim_comment').setup({
  marker_padding = true,
  comment_empty = false,
  create_mappings = true,
  line_mapping = "<C-d>",
  operator_mapping = "<C-d>",
  hook = function()
    if vim.api.nvim_buf_get_option(0, "filetype") == "php" then
      require("ts_context_commentstring.internal").update_commentstring()
    end
  end
}) 
require("todo-comments").setup()
