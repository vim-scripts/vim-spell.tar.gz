" -*- VIM -*-
" Defines the mappings and menus for the corrected/checked buffer.
"
" File:		VS_gui-map.vim
" Author:	Luc Hermitte <EMAIL:hermitte@free.fr>
" 		<URL:http://hermitte.free.fr/vim>
" Ver:		0.2b
" Last Update:	30th jan 2002
"
"===========================================================================
"

"===========================================================================
" Macros
"===========================================================================
"
  noremap ¡VS_check!	:call VS_parse_file(expand('%:p'))<cr>
  noremap ¡VS_showE!	:call VS_show_errors()<cr>
  noremap ¡VS_nextE!	:call VS_SpchkNext()<cr>
  noremap ¡VS_prevE!	:call VS_SpchkPrev()<cr>

  noremap ¡VS_alt!	:call VS_g_Launch_Corrector()<cr>
  
  noremap ¡VS_addW!	:call VS_add_word()<cr>
  noremap ¡VS_ignW!	:call VS_ignore_word()<cr>

  IfTriggers
	\ noremap ¡VS_swapL!	:call Trigger_DoSwitch('¡VS_swapL!', 
			\ 'let g:VS_language="american"', 
			\ 'let g:VS_language="francais"', 1, 1)<cr>
  noremap ¡VS_exit!	:let @_=VS_ExitSpell()<CR>


" ========================================================================
if version < 600 
  function! VS_Maps_4_file_edited()
    map <F4>	¡VS_check!
    map <S-F4>	¡VS_alt!
    IfTriggers map <C-F4>	¡VS_swapL!
    " map <m-F6>	¡VS_exit!
    " map <ESC><F4>	¡VS_exit!
    map g=	¡VS_exit!

    map <M-s>r	¡VS_check!
    map <M-s>s	¡VS_showE!
    map <M-s>a	¡VS_alt!
    IfTriggers map <M-s>L	¡VS_swapL!
    map <M-s>E	¡VS_exit!

    map <M-n>	¡VS_nextE!
    map <M-p>	¡VS_prevE!
    map <M-s>n	¡VS_nextE!
    map <M-s>N	¡VS_prevE!
    map <M-s>p	¡VS_prevE!

    nmenu 55.100 Spell\ &check.&Run\ spell\ checker<tab><M-s>r	¡VS_check!
    nmenu 55.100 Spell\ &check.&Show\ mispellings<tab><M-s>s	¡VS_showE!
    nmenu 55.100 Spell\ &check.Show\ &alternatives<tab><M-s>a	¡VS_alt!
    nmenu 55.100 Spell\ &check.E&xit<tab><M-s>E			¡VS_exit!
    amenu 55.100 Spell\ &check.-----------------		<c-l>
    IfTriggers
	  \nmenu 55.101 Spell\ &check.S&wap\ Language<tab><M-s>L ¡VS_swapL!
    amenu 55.510 Spell\ &check.------------			<c-l>
    nmenu 55.510  Spell\ &check.&Next\ mispelling<tab><M-s>n	<M-s>n
    nmenu 55.510  Spell\ &check.&Prev\ mispelling<tab><M-s>p	<M-s>p
  endfunction
else
" ------------------------------------------------------------------------
  function! VS_Maps_4_file_edited()
    map <buffer> <F4>		:silent normal ¡VS_check!<cr>
    map <buffer> <S-F4>		:silent normal ¡VS_alt!<cr>
    IfTriggers map <buffer> <C-F4>		¡VS_swapL!
    " map <buffer> <m-F6>	:silent normal ¡VS_exit!<cr>
    " map <buffer> <ESC><F4>	:silent normal ¡VS_exit!<cr>
    map <buffer> g=		:silent normal ¡VS_exit!<cr>

    map <buffer> <M-s>r		:silent normal ¡VS_check!<cr>
    map <buffer> <M-s>s		:silent normal ¡VS_showE!<cr>
    map <buffer> <M-s>a		:silent normal ¡VS_alt!<cr>
    IfTriggers map <buffer> <M-s>L		¡VS_swapL!
    map <buffer> <M-s>E		:silent normal ¡VS_exit!<cr>

    map <buffer> <M-n>		:silent normal ¡VS_nextE!<cr>
    map <buffer> <M-p>		:silent normal ¡VS_prevE!<cr>
    map <buffer> <M-s>n		:silent normal ¡VS_nextE!<cr>
    map <buffer> <M-s>N		:silent normal ¡VS_prevE!<cr>
    map <buffer> <M-s>p		:silent normal ¡VS_prevE!<cr>

    nmenu 55.100 Spell\ &check.&Run\ spell\ checker<tab><M-s>r	¡VS_check!
    nmenu 55.100 Spell\ &check.&Show\ mispellings<tab><M-s>s	¡VS_showE!
    nmenu 55.100 Spell\ &check.Show\ &alternatives<tab><M-s>a	¡VS_alt!
    nmenu 55.100 Spell\ &check.E&xit<tab><M-s>E			¡VS_exit!
    amenu 55.100 Spell\ &check.-----------------		<c-l>
    IfTriggers 
	  \ nmenu 55.101 Spell\ &check.S&wap\ Language<tab><M-s>L ¡VS_swapL!
    amenu 55.510 Spell\ &check.------------			<c-l>
    nmenu 55.510  Spell\ &check.&Next\ mispelling<tab><M-s>n	<M-s>n
    nmenu 55.510  Spell\ &check.&Prev\ mispelling<tab><M-s>p	<M-s>p
  endfunction
endif

  call VS_Maps_4_file_edited()
