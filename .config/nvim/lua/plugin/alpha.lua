startify = require'alpha.themes.startify'
startify.section.header.opts.position = 'center'
startify.section.header.val = {
    [[                      ,-~   _  ^^~-.,\                        ]],
    [[                    ,^        -,____ ^,         ,/\/\/\,\     ]],
    [[                   /           (____)  |      S~         ~7\  ]],
    [[                  ;  .---._    | | || _|     S   I AM THE   Z\]],
    [[                  | |      ~-.,\ | |!/ |     /_  NVIM-LAW  _\\]],
    [[                  ( |    ~<-.,_^\|_7^ ,|     _//_         _\\ ]],
    [[                  | |      ", 77>   (T/|   _//   \/\/\/\/     ]],
    [[                  |  \_      )/<,/^\)i(|\                     ]],
    [[                  (    ^~-,  |________||\                     ]],
    [[                  ^!,_    / /, ,"^~^",!!_,..---.\             ]],
    [[                   \_ "-./ /   (-~^~-))" =,__,..>-,\          ]],
    [[                     ^-,__/#w,_  "^" /~-,_/^\      )\         ]],
    [[                  /\  ( <_    ^~~--T^ ~=, \  \_,-=~^\\        ]],
    [[     .-==,    _,=^_,.-"_  ^~*.(_  /_)    \ \,=\      )\       ]],
    [[    /-~;  \,-~ .-~  _,/ \    ___[8]_      \ T_),--~^^)\       ]],
    [[      _/   \,,..==~^_,.=,\   _.-~O   ~     \_\_\_,.-=}\       ]],
    [[    ,{       _,.-<~^\  \ \\      ()  .=~^^~=. \_\_,./\        ]],
    [[   ,{ ^T^ _ /  \  \  \  \ \)    [|   \oMTE90>\       \        ]],
}

-- disable sections
startify.section.top_buttons.val = {}
-- custom sections rewritten
startify.section.mru.val = {
                            {type = "text", val = " Recent Files", opts = { position = 'center', hl = "SpecialComment" } },
                            {type = "padding", val = 1},
                            {type = "group", val = function() return { startify.mru(1, vim.fn.getcwd(), 3) } end, opts = { position = 'center' } }
                           }
startify.section.mru_cwd.val = { { type = "padding", val = 1 }, { type = "text", val = " Bookmark", opts = { position = 'center', hl = "SpecialComment" } } }
-- custom bookmarks that are not on GitHub
dofile('/home/mte90/.config/nvim/alpha_bookmark.lua')

require'alpha'.setup(startify.opts)
