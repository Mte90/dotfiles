require'tabline'.setup {
    enable = false,
    options = {
            section_separators = {'', ''},
            component_separators = {'', ''},
            max_bufferline_percent = 66,
            show_tabs_always = true,
            show_devicons = true,
            show_filename_only = true,
        }
}
require('lualine').setup{
    options = {
        theme = 'papercolor_light',
        icons_enabled = true,
        disabled_filetypes = {'alpha', 'Outline', 'plugins','CHADTree', '[No Name]', 'OUTLINE', 'vim-plug'},
    },
    sections = {
        lualine_a = { { 'mode', fmt = string.upper } },
        lualine_b = {},
        lualine_c = { { 'b:gitsigns_head', icon = '' }, { 'diff', icon = ''}, {
            'lsp_progress',
            display_components = {'lsp_client_name', 'spinner', { 'title', 'percentage', 'message' }},
            spinner_symbols = {'⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'},
          }
        },
        lualine_x = {},
        lualine_y = {},
        lualine_z = { { 'diagnostics', sources = {'nvim_diagnostic', 'ale'}, sections = {'error', 'warn', 'info'} } }
    },
    tabline = {
        lualine_a = {require'tabline'.tabline_buffers},
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {'filetype'},
        lualine_z = {{'nofixme#amount'}}
    },
    extensions = { 'fzf', 'chadtree', 'fugitive', 'quickfix' }
} 

require("scrollbar").setup()
