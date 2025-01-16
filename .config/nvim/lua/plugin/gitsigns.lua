require('gitsigns').setup {
  numhl = true,
  signcolumn = false,
  signs = {
    add          = {text = '+'},
    change       = {text = '~'},
    delete       = {text = '-'},
    topdelete    = {text = '‾'},
    changedelete = {text = '~'},
  }
} 
