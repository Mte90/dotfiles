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
vim.cmd[[
      set guioptions-=e " Use showtabline in gui vim
      set sessionoptions+=tabpages,globals " store tabpages and globals in session
]]
local function diff_source()
  local gitsigns = vim.b.gitsigns_status_dict
  if gitsigns then
    return {
      added = gitsigns.added,
      modified = gitsigns.changed,
      removed = gitsigns.removed
    }
  end
end
local get_color = require'lualine.utils.utils'.extract_highlight_colors
require('lualine').setup{
    options = {
        theme = 'papercolor_light',
        icons_enabled = true,
        disabled_filetypes = {'alpha', 'Outline', 'plugins','CHADTree', '[No Name]', 'OUTLINE', 'vim-plug'},
        globalstatus = true
    },
    sections = {
        lualine_a = { { 'mode', fmt = string.upper } },
        lualine_b = {},
        lualine_c = { { 'b:gitsigns_head', icon = '' }, { 'diff', icon = '', source = diff_source }, {
            'lsp_progress',
            display_components = {'lsp_client_name', 'spinner', { 'title', 'percentage', 'message' }},
            spinner_symbols = {'⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'},
          }
        },
        lualine_x = {},
        lualine_y = {},
        lualine_z = { {
            'diagnostics',
            symbols = {error = ' ', warn = ' ', info = ' ', hint = ' '},
            colored = true,
            diagnostics_color = {
                error = {fg = get_color("DiagnosticSignError", "fg")},
                warn = {fg = get_color("DiagnosticSignWarn", "fg")},
                info = {fg = get_color("DiagnosticSignInfo", "fg")},
                hint = {fg = get_color("DiagnosticSignHint", "fg")},
                },
            } }
    },
    tabline = {
        lualine_a = {require'tabline'.tabline_buffers},
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {{'aerial', sep=' | '}, 'filetype'},
        lualine_z = {'progress'}
    },
    extensions = { 'fzf', 'chadtree', 'fugitive', 'quickfix' }
}

require("scrollbar").setup()
