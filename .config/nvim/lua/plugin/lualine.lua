require('lualine').setup{
    options = {
        theme = 'papercolor_light',
        icons_enabled = true,
        condition = exclude_statusline,
        disabled_filetypes = {'alpha', 'Outline', 'plugins','CHADtree'},
    },
    sections = {
        lualine_a = { { 'mode', fmt = string.upper } },
        lualine_b = { { 'branch', icon = '' } },
        lualine_c = { { 'diff', icon = ''}, {'filename'} },
        lualine_x = { { 'filetype', 'fileformat'} },
        lualine_y = { { 'nofixme#amount'} },
        lualine_z = { { 'diagnostics', sources = {'nvim_lsp', 'ale'}, sections = {'error', 'warn', 'info'} } }
    },
    extensions = { 'fzf', 'chadtree', 'fugitive', 'quickfix' }
} 

require'bufferline'.setup{
    options = {
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(count, level, diagnostics_dict, context)
            if context.buffer:current() then
                return ''
            end

            return ''
        end,
        offsets = {
            {
                filetype = "CHADtree",
                text = "File Explorer",
                highlight = "Directory",
                text_align = "left"
            }
        }
    }
}
