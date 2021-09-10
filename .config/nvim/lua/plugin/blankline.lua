-- define the highlight groups with only background colors (or leave odd empty to just show the normal background)
vim.cmd [[highlight IndentOdd guifg=NONE guibg=NONE gui=nocombine]]
vim.cmd [[highlight IndentEven guifg=NONE guibg=#1a1a1a gui=nocombine]]

require("indent_blankline").setup {
    show_end_of_line = true,
    use_treesitter = true,
    filetype_exclude = {'help', 'chadtree', 'alpha', 'fzf',  "markdown", "json", "txt", "undotree", "git"},
    buftype_exclude = {'terminal', 'nofile'},

-- and then use the highlight groups
    char_highlight_list = {"IndentOdd", "IndentEven"},
    space_char_highlight_list = {"IndentOdd", "IndentEven"},
    context_patterns = {
        "class", "function", "method", "block", "list_literal", "selector",
        "^if", "^table", "if_statement", "while", "for"
    },

-- don't show any characters
    char = "|",
    space_char = " ",

-- when using background, the trailing indent is not needed / looks wrong
    show_trailing_blankline_indent = false
}
