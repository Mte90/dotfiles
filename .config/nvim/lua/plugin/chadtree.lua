vim.api.nvim_set_var("chadtree_ignores", { name = {".*", ".git", "vendor", "node_modules"} })
vim.api.nvim_set_var("chadtree_settings", {
                                           keymap = { tertiary = {"<tab>"}, trash = {'a'} },
                                           theme = { text_colour_set = "solarized_dark" }
                                          }
                    )
