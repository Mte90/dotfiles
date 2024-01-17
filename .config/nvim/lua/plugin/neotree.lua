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
