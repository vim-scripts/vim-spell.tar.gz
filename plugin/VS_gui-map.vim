"=============================================================================
" Part:		lhVimSpell/mappings for the corrector buffer {{{
" Last Update:	22nd jul 2002
"------------------------------------------------------------------------
" Description:	Defines the mappings and menus for the Corrector buffer.
"------------------------------------------------------------------------
" TODO:		«missing features»
"=============================================================================

"===========================================================================
" Macros
"===========================================================================
"
" Planned to be used through buffoptions2.vim ; *MUST* be in unix
" fileformat on order to correctly be prossessed by buffoptions2.vim
" Help {{{
function! VS_add2help(msg, help_var) " {{{
  if (!exists(a:help_var))
    exe 'let ' . a:help_var . '   = a:msg'
    exe 'let ' . a:help_var . 'NB = 0'
  else
    exe 'let ' . a:help_var . ' = ' . a:help_var . '."\n" . a:msg'
  endif
  ""let g:vsgui_help_maxNB = g:vsgui_help_maxNB+1
  exe 'let ' . a:help_var . 'NB = ' . a:help_var . 'NB + 1 '
endfunction " }}}

if !exists(":VSAHM") " {{{
  command! -nargs=1 VSAHM call VS_add2help(<args>,"g:vsgui_help")
  VSAHM  "@| <cr>, <double-click> : Replace with current word"
  VSAHM  "@| <A>                  : Replace every occurrence of the misspelled word "
  VSAHM  "@|                        within the current buffer"
  VSAHM  "@| <B>                  : Replace every occurrence of the misspelled word "
  VSAHM  "@|                        within all buffers"
  VSAHM  "@| <esc>                : Abort"
  VSAHM  "@| *, &                 : Add word to the dictionary (may be in lower case)"
  VSAHM  "@| <i>                  : Ignore the word momentarily"
  VSAHM  "@| <cursors>, <tab>     : Move between entries"
  VSAHM  "@|"
  VSAHM  "@| <u>/<C-R>            : Undo/Redo last change"
  VSAHM  "@| <M-n>, <M-p>         : Move between misspelled entries of the current buffer"
  VSAHM  "@| h                    : Don't display this help"
  VSAHM  "@+-----------------------------------------------------------------------------"

  command! -nargs=1 VSAHM call VS_add2help(<args>,"g:vsgui_short_help")
  VSAHM  "@| h                    : Display the help"
  VSAHM  "@+-----------------------------------------------------------------------------"
endif " }}}

function! VS_g_help() " {{{
  if g:VS_display_long_help	| return g:vsgui_help
  else				| return g:vsgui_short_help
  endif
endfunction " }}}

function! VS_g_help_NbL() " {{{
  " return 1 + nb lignes of BuildHelp
  if g:VS_display_long_help	| return 1 + g:vsgui_helpNB
  else				| return 1 + g:vsgui_short_helpNB
  endif
endfunction " }}}

function! VS_toggle_gui_help() " {{{
  let g:VS_display_long_help = 1 - g:VS_display_long_help
  Silent call VS_g_Make(b:word)
endfunction " }}}
"
" }}}
" ======================================================================
" Mappings {{{
if version < 600
  function! VS_g_AltMaps() " {{{
    noremap <cr>		:call SA_return(line('.'))<cr>
    noremap <2-LeftMouse>	:call SA_return(line('.'))<cr>
    noremap A			:call SA_all(line('.'))<cr>
    noremap B			:call SA_all_buffers(line('.'))<cr>
    noremap *			:call VS_g_AddWord(0)<cr>
    noremap &			:call VS_g_AddWord(1)<cr>
    noremap i			:call VS_g_IgnoreWord()<cr>
    noremap <esc>		:call SA_return(-1)<cr>

    noremap <s-tab>		:call VS_g_NextChoice(0)<cr>
    noremap <tab>		:call VS_g_NextChoice(1)<cr>

    noremap <M-n>		:call VS_g_NextError()<cr>
    noremap <M-p>		:call VS_g_PrevError()<cr>

    noremap u			:call VS_g_UndoCorrection(1)<cr>
    noremap <c-r>		:call VS_g_UndoCorrection(0)<cr>

    amenu 55.200 Spell\ &check.---------------			<c-l>
    nmenu 55.200 Spell\ &check.Add\ to\ &dictionary<tab>*	*
    nmenu 55.200 Spell\ &check.Idem\ low&case<tab>\&		\&
    nmenu 55.200 Spell\ &check.&Ignore\ word<tab>i		i
    amenu 55.210 Spell\ &check.--------------			<c-l>

    nmenu 55.500 Spell\ &check.&Undo<tab>u			u
    nmenu 55.500 Spell\ &check.Re&do<tab><c-r>			<c-r>

    nnoremap 0			:VSChooseWord 0
    nnoremap 1			:VSChooseWord 1
    nnoremap 2			:VSChooseWord 2
    nnoremap 3			:VSChooseWord 3
    nnoremap 4			:VSChooseWord 4
    nnoremap 5			:VSChooseWord 5
    nnoremap 6			:VSChooseWord 6
    nnoremap 7			:VSChooseWord 7
    nnoremap 8			:VSChooseWord 8
    nnoremap 9			:VSChooseWord 9
  endfunction " }}}

  function! VS_g_AltUnMaps() " {{{
    unmap <cr>
    unmap <2-LeftMouse>
    unmap A
    unmap B
    unmap <esc>
    unmap *
    unmap &
    unmap i
    unmap <tab>
    unmap <s-tab>
    unmap <M-n>
    unmap <M-p>
    unmap u
    unmap <c-r>
    unmap 0
    unmap 1
    unmap 2
    unmap 3
    unmap 4
    unmap 5
    unmap 6
    unmap 7
    unmap 8
    unmap 9
  endfunction " }}}
" ----------------------------------------------------------------------
else
  function! VS_g_AltMaps_v6() " {{{
    noremap <buffer> <cr>		:silent! :call SA_return(line('.'))<cr>
    noremap <buffer> <2-LeftMouse>	:silent! :call SA_return(line('.'))<cr>
    noremap <buffer> A			:silent! :call SA_all(line('.'))<cr>
    noremap <buffer> B			:silent! :call SA_all_buffers(line('.'))<cr>
    noremap <buffer> *			:silent  :call VS_g_AddWord(0)<cr>
    noremap <buffer> &			:silent  :call VS_g_AddWord(1)<cr>
    noremap <buffer> i			:silent! :call VS_g_IgnoreWord()<cr>
    noremap <buffer> <esc>		:silent! :call SA_return(-1)<cr>

    noremap <buffer> <s-tab>		:silent! :call VS_g_NextChoice(0)<cr>
    noremap <buffer> <tab>		:silent! :call VS_g_NextChoice(1)<cr>

    noremap <buffer> <M-n>		:silent! :call VS_g_NextError()<cr>
    noremap <buffer> <M-p>		:silent! :call VS_g_PrevError()<cr>

    noremap <buffer> u			:silent! :call VS_g_UndoCorrection(1)<cr>
    noremap <buffer> <c-r>		:silent! :call VS_g_UndoCorrection(0)<cr>
        map <buffer> <M-s>E		:silent! normal ¡VS_exit!<cr>
    silent noremap <buffer> h		:call VS_toggle_gui_help()<cr>

    amenu 55.200 Spell\ &check.---------------			<c-l>
    nmenu 55.200 Spell\ &check.Add\ to\ &dictionary<tab>*	*
    nmenu 55.200 Spell\ &check.Idem\ low&case<tab>\&		\&
    nmenu 55.200 Spell\ &check.&Ignore\ word<tab>i		i
    amenu 55.210 Spell\ &check.--------------			<c-l>

    nmenu 55.500 Spell\ &check.&Undo<tab>u			u
    nmenu 55.500 Spell\ &check.Re&do<tab><c-r>			<c-r>

    nnoremap <buffer> 0			:VSChooseWord 0
    nnoremap <buffer> 1			:VSChooseWord 1
    nnoremap <buffer> 2			:VSChooseWord 2
    nnoremap <buffer> 3			:VSChooseWord 3
    nnoremap <buffer> 4			:VSChooseWord 4
    nnoremap <buffer> 5			:VSChooseWord 5
    nnoremap <buffer> 6			:VSChooseWord 6
    nnoremap <buffer> 7			:VSChooseWord 7
    nnoremap <buffer> 8			:VSChooseWord 8
    nnoremap <buffer> 9			:VSChooseWord 9
  endfunction " }}}
endif
" }}}

" Part:		lhVimSpell/mappings for the corrector buffer }}}
"$------------------------------------------------------------------------
"$ vim600: set fdm=marker:
