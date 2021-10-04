
if exists('g:GuiLoaded')
    Guifont! DroidSansMono\ Nerd\ Font:h10
    GuiTabline 0
    call GuiWindowMaximized(1)
    GuiScrollBar 1
endif

" https://www.reddit.com/r/neovim/comments/9n7sja/liga_source_code_pro_is_not_a_fixed_pitch_font/
function! AdjustFontSize(amount)
  let s:fontsize = 10+a:amount
  ":execute "GuiFont! Consolas:h" . s:fontsize
  :execute "GuiFont! DroidSansMono\ Nerd\ Font:h10"
endfunction

noremap <C-ScrollWheelUp> :call AdjustFontSize(1)<CR>
noremap <C-ScrollWheelDown> :call AdjustFontSize(-1)<CR>
inoremap <C-ScrollWheelUp> <Esc>:call AdjustFontSize(1)<CR>a
inoremap <C-ScrollWheelDown> <Esc>:call AdjustFontSize(-1)<CR>a

" Right Click Context Menu (Copy-Cut-Paste)
nnoremap <silent><RightMouse> :call GuiShowContextMenu()<CR>
inoremap <silent><RightMouse> <Esc>:call GuiShowContextMenu()<CR>
xnoremap <silent><RightMouse> :call GuiShowContextMenu()<CR>gv
snoremap <silent><RightMouse> <C-G>:call GuiShowContextMenu()<CR>gv
