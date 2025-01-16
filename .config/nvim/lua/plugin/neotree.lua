require("neo-tree").setup({
  window = {
    width = 30,
  },
  filesystem = {
      follow_current_file = {
            enabled = false,
            leave_dirs_open = true,
      },
      use_libuv_file_watcher = true,
  }
})
vim.keymap.set({ "n", "v" }, "<RightMouse>", function()
require('menu.utils').delete_old_menus()

vim.cmd.exec '"normal! \\<RightMouse>"'

-- clicked buf
local buf = vim.api.nvim_win_get_buf(vim.fn.getmousepos().winid)
local options = vim.bo[buf].ft == "NvimTree" and "nvimtree" or "default"

require("menu").open(options, { mouse = true })
end, {})
