_G.lualine_tabs_last_fname = {}
local tab = require('lualine.components.tabs.tab')
local old_tab_label = tab.label
function tab:label()
  if not vim.tbl_contains(self.options.disabled_filetypes, vim.bo.ft) then
    _G.lualine_tabs_last_fname[self.tabnr] = old_tab_label(self)
  end
  return _G.lualine_tabs_last_fname[self.tabnr] or ''
end

require('lualine').setup{
    options = {
        theme = 'papercolor_light',
        icons_enabled = true,
        disabled_filetypes = {'alpha', 'Outline', 'plugins','CHADTree', '[No Name]', 'OUTLINE', 'vim-plug'},
    },
    sections = {
        lualine_a = { { 'mode', fmt = string.upper } },
        lualine_b = {  },
        lualine_c = { { 'b:gitsigns_head', icon = '' }, { 'diff', icon = ''}, {
            'lsp_progress',
            display_components = {'lsp_client_name', 'spinner', { 'title', 'percentage', 'message' }},
            spinner_symbols = {'⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'},
          }
        },
        lualine_x = {},
        lualine_y = {  },
        lualine_z = { { 'diagnostics', sources = {'nvim_diagnostic', 'ale'}, sections = {'error', 'warn', 'info'} } }
    },
    tabline = {
        lualine_a = {{'tabs',
            max_length = vim.o.columns / 3,
            mode = 2
        }},
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {'filetype', { 'branch', icon = '' }},
        lualine_z = {{ 'nofixme#amount'}}
    },
    extensions = { 'fzf', 'chadtree', 'fugitive', 'quickfix' }
} 

require("scrollbar").setup()
