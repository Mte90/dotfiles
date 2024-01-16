local remap = vim.api.nvim_set_keymap
local npairs = require('nvim-autopairs')
local Rule = require('nvim-autopairs.rule')
npairs.setup({
    map_bs = false,
    check_ts = true
})

remap('i', '<esc>', [[pumvisible() ? "<c-e><esc>" : "<esc>"]], {
    expr = true, -- these mappings are coq recommended mappings unrelated to nvim-autopairs
    noremap = true
})

remap('i', '<c-c>', [[pumvisible() ? "<c-e><c-c>" : "<c-c>"]], {
    expr = true,
    noremap = true
})

remap('i', '<tab>', [[pumvisible() ? "<c-n>" : "<tab>"]], {
    expr = true,
    noremap = true
})

remap('i', '<s-tab>', [[pumvisible() ? "<c-p>" : "<bs>"]], {
    expr = true,
    noremap = true
})

_G.MUtils = {} -- skip it, if you use another global object
MUtils.CR = function()
    if vim.fn.pumvisible() ~= 0 then
        if vim.fn.complete_info({'selected'}).selected ~= -1 then
            return npairs.esc('<c-y>')
        else
            return npairs.esc('<c-g><c-g>') .. npairs.autopairs_cr() -- you can change <c-g><c-g> to <c-e> if you don't use other i_CTRL-X modes
        end
    else
        return npairs.autopairs_cr()
    end
end

remap('i', '<cr>', 'v:lua.MUtils.CR()', {
    expr = true,
    noremap = true
})

MUtils.BS = function()
    if vim.fn.pumvisible() ~= 0 and vim.fn.complete_info({'mode'}).mode == 'eval' then
        return npairs.esc('<c-e>') .. npairs.autopairs_bs()
    else
        return npairs.autopairs_bs()
    end
end

remap('i', '<bs>', 'v:lua.MUtils.BS()', {
    expr = true,
    noremap = true
})

local ts_conds = require('nvim-autopairs.ts-conds')
npairs.add_rules({
    Rule("%", "%", "lua"):with_pair(ts_conds.is_ts_node({
        'string', -- press % => %% is only inside comment or string
        'comment'
    })),
    Rule("$", "$", "lua"):with_pair(ts_conds.is_not_ts_node({'function'}))
})

require'colorizer'.setup()
