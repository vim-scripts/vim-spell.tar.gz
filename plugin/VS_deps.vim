" -*- VIM -*-
" Check for other non essential VIM plugins.
"
" File:		VS_deps.vim 
" Author:	Luc Hermitte <EMAIL:hermitte@free.fr>
" 		<URL:http://hermitte.free.fr/vim>
" Ver:		0.2b
" Last Update:	31st jan 2002
"
"===========================================================================
"

" Enable to use silent in scripts for VIM 5.7+ and VIM 6.0, with none of
" them complaining ; from my runtime.vim script for VIM 5.7+
if !exists(":Silent")
  if version < 600
    command! -nargs=+ -complete=file -bang Silent exe "<args>"
  else
    command! -nargs=+ -complete=file -bang Silent silent<bang> <args>
  endif
endif

if exists("*Trigger_DoSwitch")
  command! -nargs=* IfTriggers <args>
else
  command! -nargs=* IfTriggers silent :"<args>
endif
