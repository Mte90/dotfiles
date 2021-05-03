require('lualine').setup{
    options = {
        theme = 'papercolor_light',
        icons_enabled = true,
        condition = exclude_statusline,
        disabled_filetypes = {'startify', 'Outline', 'plugins'},
    },
    sections = {
        lualine_a = { { 'mode', upper = true } },
        lualine_b = { { 'branch', icon = '' } },
        lualine_c = { { 'diff', icon = ''}, {'filename'} },
        lualine_x = { { 'filetype', 'fileformat'} },
        lualine_y = { { 'nofixme#amount'} },
        lualine_z = { { 'diagnostics', sources = {'nvim_lsp', 'ale'}, sections = {'error', 'warn', 'info'}, symbols = {error = 'E:', warn = 'W:', info = 'I:'} } }
    },
    extensions = { 'fzf', 'chadtree', 'fugitive' },
    tabline = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {'filename'},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {}
    }
} 
