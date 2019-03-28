hi clear

set background=dark
if version > 580
    " no guarantees for version 5.8 and below, but this makes it stop
    " complaining
    hi clear
    if exists("syntax_on")
      syntax reset
    endif
endif
let g:colors_name="valloric"


hi Boolean         guifg=#af5fff
hi Character       guifg=#afaf87
hi Number          guifg=#af5fff
hi String          guifg=#E6DB74
hi Conditional     guifg=#df005f               gui=bold
hi Constant        guifg=#af5fff
hi Cursor          guifg=#000000 guibg=#dadada
hi Debug           guifg=#ffd7ff               gui=bold
hi Define          guifg=#5fdfff
hi Delimiter       guifg=#606060

hi DiffAdd                       guibg=#005f87
hi DiffChange      guifg=#dfafaf guibg=#4e4e4e
hi DiffDelete      guifg=#df0087 guibg=#5f005f
hi DiffText                      guibg=#878787 gui=bold

hi Directory       guifg=#87ff00               gui=bold
hi Error           guifg=#ffafff guibg=#87005f
hi ErrorMsg        guifg=#ff00af guibg=#000000 gui=bold
hi Exception       guifg=#87ff00               gui=bold
hi Float           guifg=#af5fff
hi FoldColumn      guifg=#5f87af guibg=#000000
hi Folded          guifg=#5f87af guibg=#000000
hi Function        guifg=#87ff00
hi Identifier      guifg=#ff8700  
hi Ignore          guifg=#808080 guibg=#080808
hi IncSearch       guifg=#d7ffaf guibg=#000000

hi Keyword         guifg=#df005f               gui=bold
hi Label           guifg=#ffffaf               gui=none
hi Macro           guifg=#d7ffaf               gui=none
hi SpecialKey      guifg=#5fdfff               gui=none

hi MatchParen      guifg=#000000 guibg=#ff8700 gui=bold
hi ModeMsg         guifg=#ffffaf
hi MoreMsg         guifg=#ffffaf
hi Operator        guifg=#d7005f

" complete menu
hi Pmenu           guifg=#5fd7ff guibg=#000000
hi PmenuSel                      guibg=#808080
hi PmenuSbar                     guibg=#080808
hi PmenuThumb      guifg=#5fdfff

hi PreCondit       guifg=#87ff00               gui=bold
hi PreProc         guifg=#87ff00
hi Question        guifg=#5fd7ff
hi Repeat          guifg=#d7005f
hi Search          guifg=#dadada guibg=#5f8787

" marks column
hi SignColumn      guifg=#87ff00 guibg=#262626
hi SpecialChar     guifg=#df005f               gui=bold
hi SpecialComment  guifg=#8a8a8a               gui=bold
hi Special         guifg=#5fdfff guibg=#121212 gui=none
hi SpecialKey      guifg=#8a8a8a               gui=none
if has("spell")
    hi SpellBad    guisp=#FF0000 gui=undercurl
    hi SpellCap    guisp=#7070F0 gui=undercurl
    hi SpellLocal  guisp=#70F0F0 gui=undercurl
    hi SpellRare   guisp=#FFFFFF gui=undercurl
endif
hi Statement       guifg=#df005f               gui=bold
hi StatusLine      guifg=#444444 guibg=#dadada
hi StatusLineNC    guifg=#808080 guibg=#080808
hi StorageClass    guifg=#ff8700               gui=none
hi Structure       guifg=#5fd7ff
hi Tag             guifg=#d7005f               gui=none
hi Title           guifg=#d75f00               gui=none
hi Todo            guifg=#FFFFFF guibg=#080808 gui=bold

hi Typedef         guifg=#5fd7ff
hi Type            guifg=#5fd7ff               gui=none
hi Underlined      guifg=#808080               gui=underline

hi VertSplit       guifg=#808080 guibg=#080808 gui=bold
hi VisualNOS                     guibg=#444444
hi Visual                        guibg=#262626
hi WarningMsg      guifg=#FFFFFF guibg=#444444 gui=bold
hi WildMenu        guifg=#5fd7ff guibg=#000000

hi mySpecialSymbols guifg=cyan  gui=NONE
hi ColorColumn     guibg=#3B3A32

hi Normal          guifg=#d0d0d0 guibg=#121212
hi Comment         guifg=#5f5f5f               gui=none
hi CursorLine                    guibg=#1c1c1c
hi CursorColumn                  guibg=#1c1c1c
hi LineNr          guifg=#bcbcbc guibg=#1c1c1c
hi NonText         guifg=#BCBCBC guibg=#1c1c1c

hi! link htmlValue Normal

"
" Support for 256-color terminal
"
if &t_Co > 255
   hi Boolean         ctermfg=135  ctermbg=NONE cterm=NONE
   hi Character       ctermfg=144  ctermbg=NONE cterm=NONE
   hi Number          ctermfg=135  ctermbg=NONE cterm=NONE
   hi String          ctermfg=144  ctermbg=NONE cterm=NONE
   hi Conditional     ctermfg=161  ctermbg=NONE cterm=bold
   hi Constant        ctermfg=135  ctermbg=NONE cterm=NONE
   hi Cursor          ctermfg=16   ctermbg=253  cterm=NONE
   hi Debug           ctermfg=225  ctermbg=NONE cterm=bold
   hi Define          ctermfg=81   ctermbg=NONE cterm=NONE
   hi Delimiter       ctermfg=241  ctermbg=NONE cterm=NONE

   hi DiffAdd                     ctermbg=24   cterm=NONE
   hi DiffChange      ctermfg=181 ctermbg=239  cterm=NONE
   hi DiffDelete      ctermfg=162 ctermbg=53   cterm=NONE
   hi DiffText                    ctermbg=102  cterm=bold

   hi Directory       ctermfg=118 ctermbg=NONE  cterm=bold
   hi Error           ctermfg=219 ctermbg=89    cterm=NONE
   hi ErrorMsg        ctermfg=199 ctermbg=16    cterm=bold
   hi Exception       ctermfg=118 ctermbg=NONE  cterm=bold
   hi Float           ctermfg=135  ctermbg=NONE cterm=NONE
   hi FoldColumn      ctermfg=67  ctermbg=16    cterm=NONE
   hi Folded          ctermfg=67  ctermbg=16    cterm=NONE
   hi Function        ctermfg=118  ctermbg=NONE cterm=NONE
   hi Identifier      ctermfg=208  ctermbg=NONE cterm=NONE
   hi Ignore          ctermfg=244 ctermbg=232   cterm=NONE
   hi IncSearch       ctermfg=193 ctermbg=16    cterm=NONE

   hi Keyword         ctermfg=161  ctermbg=NONE cterm=bold
   hi Label           ctermfg=229  ctermbg=NONE cterm=none
   hi Macro           ctermfg=193  ctermbg=NONE cterm=NONE
   hi SpecialKey      ctermfg=81   ctermbg=NONE cterm=NONE

   hi MatchParen      ctermfg=16   ctermbg=208  cterm=bold
   hi ModeMsg         ctermfg=229  ctermbg=NONE cterm=NONE
   hi MoreMsg         ctermfg=229  ctermbg=NONE cterm=NONE
   hi Operator        ctermfg=161  ctermbg=NONE cterm=NONE

   " complete menu
   hi Pmenu           ctermfg=81  ctermbg=16   cterm=NONE
   hi PmenuSel                    ctermbg=244  cterm=NONE
   hi PmenuSbar                   ctermbg=232  cterm=NONE
   hi PmenuThumb      ctermfg=81  ctermbg=NONE cterm=NONE

   hi PreCondit       ctermfg=118 ctermbg=NONE  cterm=bold
   hi PreProc         ctermfg=118 ctermbg=NONE  cterm=NONE
   hi Question        ctermfg=81  ctermbg=NONE  cterm=NONE
   hi Repeat          ctermfg=161 ctermbg=NONE  cterm=NONE
   hi Search          ctermfg=253 ctermbg=66    cterm=NONE

   " marks column
   hi SignColumn      ctermfg=118 ctermbg=235  cterm=NONE
   hi SpecialChar     ctermfg=161 ctermbg=NONE cterm=bold
   hi SpecialComment  ctermfg=245 ctermbg=NONE cterm=bold
   hi Special         ctermfg=81  ctermbg=232  cterm=NONE
   hi SpecialKey      ctermfg=245 ctermbg=NONE cterm=NONE

   hi Statement       ctermfg=161 ctermbg=NONE  cterm=bold
   hi StatusLine      ctermfg=238 ctermbg=253   cterm=NONE
   hi StatusLineNC    ctermfg=244 ctermbg=232   cterm=NONE
   hi StorageClass    ctermfg=208  ctermbg=NONE cterm=NONE
   hi Structure       ctermfg=81  ctermbg=NONE  cterm=NONE
   hi Tag             ctermfg=161  ctermbg=NONE cterm=NONE
   hi Title           ctermfg=166  ctermbg=NONE cterm=NONE
   hi Todo            ctermfg=231 ctermbg=232   cterm=bold

   hi Typedef         ctermfg=81  ctermbg=NONE  cterm=NONE
   hi Type            ctermfg=81  ctermbg=NONE  cterm=none
   hi Underlined      ctermfg=244 ctermbg=NONE  cterm=underline

   hi VertSplit       ctermfg=244 ctermbg=232   cterm=bold
   hi VisualNOS                   ctermbg=238   cterm=NONE
   hi Visual                      ctermbg=235   cterm=NONE
   hi WarningMsg      ctermfg=231 ctermbg=238   cterm=bold
   hi WildMenu        ctermfg=81  ctermbg=16    cterm=NONE

   hi Normal          ctermfg=252 ctermbg=233  cterm=NONE
   hi Comment         ctermfg=59  ctermbg=NONE cterm=NONE
   hi CursorLine                  ctermbg=234  cterm=none
   hi CursorColumn                ctermbg=234  cterm=NONE
   hi LineNr          ctermfg=250 ctermbg=234  cterm=NONE
   hi NonText         ctermfg=250 ctermbg=234  cterm=NONE
end

