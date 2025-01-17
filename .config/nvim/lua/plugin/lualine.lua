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
        theme = 'horizon',
        icons_enabled = true,
        disabled_filetypes = {'alpha', 'plugins', '[No Name]', 'vim-plug', 'neo-tree',"dapui*",
			"dapui_scopes",
			"dapui_watches",
			"dapui_console",
			"dapui_breakpoints",
			"dapui_stacks",
			"dap-repl",},
        globalstatus = true
    },
    sections = {
        lualine_a = {
            {
                'mode',
                fmt = string.upper
            }
        },
        lualine_b = {"pretty_path"},
        lualine_c = {
            {
                'b:gitsigns_head',
                icon = ''
            },
            {
                require("todos-lualine").component()
            },
            {
                'diff',
                icon = '',
                source = diff_source
            },
            {
                'lsp_progress',
                display_components = {'lsp_client_name', 'spinner', {'title', 'percentage', 'message'}},
                spinner_symbols = {'⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'},
            },
            {
                'diagnostic-message'

            }
        },
        lualine_x = {},
        lualine_y = {},
        lualine_z = {
            {
                'diagnostics',
                symbols = {
                    error = '',
                    warn = ' ',
                    info = '',
                    hint = ' '
                },
                colored = true,
                diagnostics_color = {
                    error = {
                        fg = get_color("DiagnosticSignError", "fg")
                    },
                    warn = {
                        fg = get_color("DiagnosticSignWarn", "fg")
                    },
                    info = {
                        fg = get_color("DiagnosticSignInfo", "fg")
                    },
                    hint = {
                        fg = get_color("DiagnosticSignHint", "fg")
                    },
                },
            }
        }
    },
    tabline = {
        lualine_a = {'buffers'},
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {
            {
                'aerial',
                sep = ' | '
            },
            'filetype'
        },
        lualine_z = {'location'}
    },
    extensions = {'fzf', 'neo-tree', 'fugitive', 'quickfix', 'nvim-dap-ui'}
}

require("scrollbar").setup()
