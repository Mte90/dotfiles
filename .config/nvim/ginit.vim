" https://www.nerdfonts.com/font-downloads
if exists('g:GuiLoaded')
    Guifont! DroidSansM\ Nerd\ Font \Mono:h10
    GuiTabline 1
    call GuiWindowMaximized(1)
    GuiScrollBar 1
    GuiRenderLigatures 1
    GuiAdaptiveColor 1
endif

" https://www.reddit.com/r/neovim/comments/9n7sja/liga_source_code_pro_is_not_a_fixed_pitch_font/
function! AdjustFontSize(amount)
  let s:fontsize = 10+a:amount
  :execute "GuiFont! DroidSansM\ Nerd\ Font:h10"
endfunction

noremap <C-ScrollWheelUp> :call AdjustFontSize(1)<CR>
noremap <C-ScrollWheelDown> :call AdjustFontSize(-1)<CR>
inoremap <C-ScrollWheelUp> <Esc>:call AdjustFontSize(1)<CR>a
inoremap <C-ScrollWheelDown> <Esc>:call AdjustFontSize(-1)<CR>a
