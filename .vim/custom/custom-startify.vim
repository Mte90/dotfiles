" Load custom file that is not git synced
source /home/mte90/.vim/startify.vim

let g:startify_enable_special = 0
let g:startify_session_dir = '~/.vim/sessions'
let g:startify_lists = [
          \ { 'type': 'files',     'header': ['   Most Recent'] },
          \ { 'type': 'bookmarks', 'header': ['   Bookmarks']   },
\ ]
let g:startify_files_number = 3
let g:startify_padding_left = 5 
let g:startify_change_to_vcs_root = 1
let g:ascii=[
    \ '                      ,-~   _  ^^~-.,\                        ',
    \ '                    ,^        -,____ ^,         ,/\/\/\,\     ',
    \ '                   /           (____)  |      S~         ~7\  ',
    \ '                  ;  .---._    | | || _|     S   I AM THE   Z\',
    \ '                  | |      ~-.,\ | |!/ |     /_  VIM-LAW   _\\',
    \ '                  ( |    ~<-.,_^\|_7^ ,|     _//_         _\\  ',
    \ '                  | |      ", 77>   (T/|   _//   \/\/\/\/     ',
    \ '                  |  \_      )/<,/^\)i(|\                     ',
    \ '                  (    ^~-,  |________||\                     ',
    \ '                  ^!,_    / /, ,"^~^",!!_,..---.\             ',
    \ '                   \_ "-./ /   (-~^~-))" =,__,..>-,\          ',
    \ '                     ^-,__/#w,_  "^" /~-,_/^\      )\         ',
    \ '                  /\  ( <_    ^~~--T^ ~=, \  \_,-=~^\\        ',
    \ '     .-==,    _,=^_,.-"_  ^~*.(_  /_)    \ \,=\      )\       ',
    \ '    /-~;  \,-~ .-~  _,/ \    ___[8]_      \ T_),--~^^)\       ',
    \ '      _/   \,,..==~^_,.=,\   _.-~O   ~     \_\_\_,.-=}\       ',
    \ '    ,{       _,.-<~^\  \ \\      ()  .=~^^~=. \_\_,./\        ',
    \ '   ,{ ^T^ _ /  \  \  \  \ \)    [|   \oDREDD >\      \        ',
\ ]

let g:startify_custom_header=startify#center(g:ascii)

