"=============================================================================
" File:		lhVimSpell.vim {{{
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim>
" Version:	0.5
" Created:	One day in 2001
" Last Update:	10th feb 2003
" }}}
"------------------------------------------------------------------------
" Description:	Spellcheck plugin for VIM 6.x. {{{
"               This plugin wraps call to ispell (/aspell) and have *many*
"               other features. cf. |VS_help.txt|
"               }}}
"------------------------------------------------------------------------
" Installation:	 {{{
" The plugin is composed of several files. I suppose here that you have the
" end user version (otherwise, run make!) that contains:
"   - lhVimSpell.vim	: the main file of the plugin
"   - VS_gui-map.vim	: mappings for the corrector mode buffer
"   - a.vim		: an old version of Michael Sharpe's plugin
"   - ChangeLog		: changes history
"   - VS_help.txt	: the documentation of the plugin in VIM help format
"   - VS_help.html	: the same documentation but in HTML.
"
" I use the notation $$ as a shortcut to $HOME/.vim/ (for *NIX systems) or
" $HOME/vimfiles/ (for Ms-Windows systems) ; check ":help 'runtimepath'" for
" other systems.
"   - drop the documentation files into $$/doc and execute (from VIM)
"     ':helptags $HOME/vimfiles/doc' once.
"   - If you want the plugin to be run systematically : drop the three vim
"     files into your $$/plugin/ directory
"     Or, if you want the plugin to be run only in specific situations: drop
"     them into your $$/macros/ directory, and source it whenever you need it.
"     For instance, I execute ":runtime macros/lhVimSpell.vim" from my TeX
"     ftplugin.
"
" VS_gui-map.vim and lhVimSpell.vim *MUST* be in the same directory.
" For other dependencies aspects, check |VS_help.txt|
" 
" N.B.: there also exist my developper version of the plugin : lhVimSpell.vim
" is actually the concatenation of several thematic files. If you want to hack
" the plugin, it could be easier to check
"      <http://hermitte.free.fr/vim/ressources/vim-spell-dev.tar.gz>
" }}}
" Inspiration:	VIMspell.vim by Claudio Fleiner <claudio@fleiner.com>
" History:	cf. Changelog
" TODO:		cf. |VS_help.txt|
"=============================================================================
"
"------------------------------------------------------------------------
" Avoid reinclusion
if exists("g:loaded_lhVimSpell_vim") 
  finish
endif
let g:loaded_lhVimSpell_vim = 1

"=============================================================================
" Part:		lhVimSpell/options {{{
" Last Update:	08th feb 2003
"------------------------------------------------------------------------
" Description:	Options for lhVimSpell
"------------------------------------------------------------------------
" Installation:	If you'd rather have other default values for the options, do
" the assignments into your .vimrc.
" TODO:		«missing features»
"=============================================================================

"=============================================================================
" Default values for the options       {{{
"------------------------------------------------------------------------
" Function: s:Set_if_null(var, value)                    {{{
function! s:Set_if_null(var, value)
  if (!exists(a:var)) | exe "let ".a:var." = a:value" | endif
endfunction
command -nargs=+ VSDefaultValue :call s:Set_if_null(<f-args>)
" }}}
"------------------------------------------------------------------------
" Try to find aspell or ispell                           {{{
" 
" If searchInRuntime.vim has been installed (check the original version on my
" web site -> http://hermitte.free.fr/vim/), then we check if aspell or ispell
" is visible from the $PATH.
" Otherwise, try to use `which' in a *nix shell ; or else suppose aspell.
"
if !exists('g:VS_spell_prog')
  if exists(':SearchInPATH')  " {{{ searchInRuntime installed
    " Best and 100% portable way -- if searchInRuntime.vim is installed
    command! -nargs=1 VSSetProg :let g:VS_spell_prog=<q-args>
    :SearchInPATH VSSetProg aspell.exe ispell.exe aspell ispell 
    delcommand VSSetProg
    " }}}
  elseif &shell =~ 'sh'        " {{{ Unix
    " `which' may exists on *nix systems
    let g:VS_spell_prog = matchstr(system('which aspell'), ".*\\ze\n")
    if g:VS_spell_prog !~ '.*aspell$'	" «aspell: Command not found»
      let g:VS_spell_prog = matchstr(system('which ispell'), ".*\\ze\n")
      if g:VS_spell_prog !~ '.*ispell$'	" «ispell: Command not found»
	unlet g:VS_spell_prog
      endif
    endif
    " }}}
  else                         " {{{ Assume aspell
    " Assuming `aspell', but ... `aspell' may be invisible from the $PATH.
    let g:VS_spell_prog = 'aspell'
  endif
  " }}}

  if exists('g:VS_spell_prog') " {{{ found
    " As the exact path has been found, we split it.
    let s:ProgramPath   = fnamemodify(g:VS_spell_prog, ':p:h')
    let g:VS_spell_prog = fnamemodify(g:VS_spell_prog, ':t')
    " }}}
  else                         " {{{ not found!!!
    call s:ErrorMsg('Please check your installation.'.
	  \ "\n".'lhVimSpell has not been able to find ispell or aspell.'.
	  \ "\n".'Update your $PATH or add into your .vimrc:'.
	  \ "\n".'      :let g:VS_spell_prog = "path/to/aspell_or_ispell/aspell"')
    let g:VS_spell_prog = 'aspell'
  endif
  "}}}
endif
" }}}
"------------------------------------------------------------------------
" Other options                                          {{{
VSDefaultValue g:VS_stripaccents			0
VSDefaultValue g:VS_aspell_add_directly_to_dict		0
VSDefaultValue g:VS_jump_to_next_error_after_validation	1
VSDefaultValue g:VS_display_long_help			0

" Mappings
" Note: must be set before the plugin is loaded -> .vimrc
if exists('g:VS_map_leader')
  let s:map_leader = g:VS_map_leader
elseif (has('win16') || has('win32') || has('dos16') || has('dos32') || has('os2'))
      \ && (&winaltkeys != 'no')
  let s:map_leader = '<Leader>s'
else
  let s:map_leader = '<M-s>'
endif

" Menus:
" Note: must be set before the plugin is loaded -> .vimrc
let s:menu_prio = exists('g:VS_menu_priority') 
      \ ? g:VS_menu_priority : 55
if s:menu_prio !~ '\.$' | let s:menu_prio = s:menu_prio . '.' | endif
let s:menu_name = exists('g:VS_menu_name')
      \ ? g:VS_menu_name     : 'Spell &check.'
if s:menu_name !~ '\.$' | let s:menu_name = s:menu_name . '.' | endif

delcommand VSDefaultValue


" :VSVerbose {num}
let s:verbose = 0
command! -nargs=1 VSVerbose let s:verbose=<arg>


" }}}
"------------------------------------------------------------------------
" }}}
"=============================================================================
" Some accessors to the options        {{{
"------------------------------------------------------------------------
command! -nargs=1 VSEcho :echo s:<arg> 
"------------------------------------------------------------------------
" Function: s:Option(name, default [, scope])            {{{
function! s:Option(name,default,...)
  let scope = (a:0 == 1) ? a:1 : 'bg'
  let name = 'VS_' . a:name
  let i = 0
  while i != strlen(scope)
    if exists(scope[i].':'.name) && ("" != {scope[i]}:{name})
      return {scope[i]}:{name}
    endif
    let i = i + 1
  endwhile 
  return a:default
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:Default_language()                         {{{
function! s:Default_language()
  if s:Option('language','') != "" | return | endif
  if v:lang =~? '^French\|^fr_FR'            | let g:VS_language = 'francais'
  elseif v:lang =~ '^uk_UK\|^us_US\|English' | let g:VS_language = 'english'
  elseif v:lang =~ '^de_DE'                  | let g:VS_language = 'de'
  else 
    call s:ErrorMsg("The language v:lang=".v:lang." is not reconized. ".
	  \ "Assuming English.\n".
	  \ "Please check the functions s:Default_language() ".
	  \ "and s:Personal_dict()")
    let g:VS_language = 'english'
  endif
endfunction 
" }}}
" Function: s:Language()                                 {{{
function! s:Language()
  call s:Default_language()
  return s:Option('language','')
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:AspellDirectories(which_directory)         {{{
" Used by s:Personal_dict() only -> to directly modify the personal
" dictionary.
function! s:AspellDirectories(which_dir)
  if  !exists('s:AspellPersonalDirectory') 
    let config = system(s:I_call_iaspell(' config'))
    if '' == config
      VSgErrorMsg "Can't access to Aspell's configuration..."
      return ''
    endif
    let s:AspellConfigDirectory = 
	  \ matchstr(config,"conf-dir current:\\s*\\zs.\\{-}\\ze\n")
    let s:AspellDataDirectory = 
	  \ matchstr(config,"data-dir current:\\s*\\zs.\\{-}\\ze\n")
    let s:AspellDictionaryDirectory = 
	  \ matchstr(config,"dict-dir current:\\s*\\zs.\\{-}\\ze\n")
    let s:AspellPersonalDirectory = 
	  \ matchstr(config,"home-dir current:\\s*\\zs.\\{-}\\ze\n")
    let s:AspellLocalDataDirectory = 
	  \ matchstr(config,"loacal-data-dir current:\\s*\\zs.\\{-}\\ze\n")
  endif
  if     a:which_dir =~ 'pers\%[onal]'   | return s:AspellPersonalDirectory
  elseif a:which_dir == 'data'           | return s:AspellDataDirectory
  elseif a:which_dir == 'localdata'      | return s:AspellLocalDataDirectory
  elseif a:which_dir =~ 'conf\%[ig]'     | return s:AspellConfigDirectory
  elseif a:which_dir =~ 'dict\%[ionary]' | return s:AspellDictionaryDirectory
  else
  endif
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:Personal_dict()                            {{{
" Function to compute the path to the personal dictionary (for ASPELL only!)
" You may have to customize it to your own needs.
function! s:Personal_dict()
  let lang   = s:Language()
  let aspell = s:AspellDirectories('pers').'/'
  if "" == lang
    :echoerr "The language option is not set.  "
	  \ "Please check the function s:Personal_dict()"
  elseif lang == "francais" | return aspell."fr.pws"
  elseif lang == "english"  | return aspell."english.pws"
  elseif lang == "american" | return aspell."english.pws"
  elseif lang == "de"       | return aspell."de.pws"
  else
    return aspell.lang.".pws"
  endif
endfunction " }}}
"------------------------------------------------------------------------
" Function: s:CheckSpellLanguage()                       {{{
function! s:CheckSpellLanguage()
  if !exists("b:spell_options") | let b:spell_options="" | endif
  return b:spell_options
endfunction " }}}
"------------------------------------------------------------------------
function! s:AddMenuItem(mode,priority,title,key,action)
  exe a:mode.'menu <silent> '.s:menu_prio.a:priority.' '.
	\ escape(s:menu_name.a:title, '\ ').
	\ ((''!=a:key) ? '<tab>'.a:key : '').
	\ ' '. a:action
endfunction
"------------------------------------------------------------------------
" }}}


" Part:		lhVimSpell/options}}}
"=============================================================================
" Part:		lhVimSpell/dependencies {{{
" Last Update:	07th feb 2003
"------------------------------------------------------------------------
" Description:	Check for other non essential VIM plugins.
"------------------------------------------------------------------------
" TODO:		«missing features»
"=============================================================================
"

"------------------------------------------------------------------------
" Function: s:ErrorMsg(msg)                              {{{
" TODO: defines highlights for ErrorMsg and EchoMsg!
function! s:ErrorMsg(msg)
  if has('gui')
    call confirm(a:msg, '&Ok', 1, 'Error')
  else
    echohl ErrorMsg
    echo a:msg
    echohl None
  endif
endfunction
command! -nargs=1 VSgErrorMsg :call s:ErrorMsg(<args>)

function! s:EchoMsg(msg)
  echohl WarningMsg
  echo a:msg
  echohl None
endfunction
command! -nargs=1 VSgEchoMsg :call s:EchoMsg(<args>)
" }}}
"------------------------------------------------------------------------
if exists("*Trigger_DoSwitch")         " {{{
  command! -nargs=* IfTriggers <args>
else " silent comment
  command! -nargs=* IfTriggers silent :"<args>
endif
" }}}
"------------------------------------------------------------------------
if !exists("*FindOrCreateBuffer")      " {{{
  let ff = expand('<sfile>:p:h'). '/a-old.vim'
  let msg=''
  if filereadable(ff) | exe 'source '.ff
  else
    runtime macros/a-old.vim plugin/a-old.vim
  endif
  let msg = '<a-old.vim> is not visible from '.expand('<sfile>:p:h')."/\n"

  if !exists("*FindOrCreateBuffer")
    call s:ErrorMsg(msg.'Make sure <a-old.vim> correctly exports the function '.
	  \ 'FindOrCreateBuffer()')
  endif
endif
" }}}
"------------------------------------------------------------------------
if !exists("*FixPathName")             " {{{
  let ff = expand('<sfile>:p:h'). '/system_utils.vim'
  if filereadable(ff) | exe 'source '.ff
  else
    runtime macros/system_utils.vim plugin/system_utils.vim
  endif

  if !exists("*SysCat")
    call s:ErrorMsg(
	  \ '<system_utils.vim> is not visible from '.expand('<sfile>:p:h'))
  endif
endif
" }}}
"------------------------------------------------------------------------

" Part:		lhVimSpell/dependencies }}}
"=============================================================================
" Part:		lhVimSpell/corrected buffer functions {{{
" Last Update:	08th feb 2003
"------------------------------------------------------------------------
" Description:	Defines the mappings and menus for the corrected/checked
" buffer.
"------------------------------------------------------------------------
" TODO:		«missing features»
"=============================================================================

"===========================================================================
" Macros 
"===========================================================================
" {{{
  noremap !VS_addW!	:call <sid>Add_word()<cr>
  noremap !VS_ignW!	:call <sid>Ignore_word()<cr>

  IfTriggers
	\ noremap !VS_swapL!	:call Trigger_DoSwitch('!VS_swapL!', 
			\ 'let g:VS_language="american"', 
			\ 'let g:VS_language="'.g:VS_language.'"', 1, 1)<cr>
" }}}
" ========================================================================
function! s:Maps_4_file_edited()                         " {{{
  if !hasmapto('<Plug>VS_check', 'n')
    nmap <buffer> <F4>					<Plug>VS_check
    exe 'nmap <buffer> '.s:map_leader.'r		<Plug>VS_check'
  endif
  nnoremap <silent> <buffer> <Plug>VS_check	
	\ :update<cr>:call <sid>Parse_current_file()<cr>

  if !hasmapto('<Plug>VS_showE', 'n')
    exe 'nmap <buffer> '.s:map_leader.'s		<Plug>VS_showE'
  endif
  nnoremap <silent> <buffer> <Plug>VS_showE
	\ :call <sid>Show_errors()<cr>

  if !hasmapto('<Plug>VS_alt', 'n')
    nmap <buffer> <S-F4>				<Plug>VS_alt
    exe 'nmap <silent> <buffer> '.s:map_leader.'a	<Plug>VS_alt'
    exe 'nmap <silent> <buffer> '.s:map_leader.'<tab>	<Plug>VS_alt'
  endif
  nnoremap <silent> <buffer> <Plug>VS_alt
	\ :call <sid>G_Launch_Corrector()<cr>

  " IfTriggers nmap <buffer> <C-F4>			!VS_swapL!
  IfTriggers exe 'nmap <buffer> '.s:map_leader.'L	!VS_swapL!'

  if !hasmapto('<Plug>VS_exit', 'n')
    " nmap <buffer> g=					<Plug>VS_exit
    exe 'nmap <buffer> '.s:map_leader.'E		<Plug>VS_exit'
  endif
  nnoremap <silent> <buffer> <Plug>VS_exit
	\ call <sid>ExitSpell()<CR>


  if !hasmapto('<Plug>VS_nextE', 'n')
    nmap <buffer> <M-n>					<Plug>VS_nextE
    exe 'nmap <buffer> '.s:map_leader.'n		<Plug>VS_nextE'
  endif
  nnoremap <silent> <buffer> <Plug>VS_nextE
	\ :call <sid>SpchkNext()<cr>

  if !hasmapto('<Plug>VS_prevE', 'n')
    nmap <buffer> <M-p>					<Plug>VS_prevE
    exe 'nmap <buffer> '.s:map_leader.'N		<Plug>VS_prevE'
    exe 'nmap <buffer> '.s:map_leader.'p		<Plug>VS_prevE'
  endif
  nnoremap <silent> <buffer> <Plug>VS_prevE
	\ :call <sid>SpchkPrev()<cr>
endfunction " }}}
"------------------------------------------------------------------------
function! s:Global_menus()                               " {{{
  " Menus
  if has('gui_running') && has('menu')
    " let s:menu_start= 'nmenu <silent>'.s:menu_prio.'.100 '.s:menu_name

    call s:AddMenuItem('n', 100, '&Run spell checker', s:map_leader.'r', '<Plug>VS_check')
    call s:AddMenuItem('n', 100, '&Show misspellings',  s:map_leader.'s', '<Plug>VS_showE')
    call s:AddMenuItem('n', 100, 'Show &alternatives', s:map_leader.'a', '<Plug>VS_alt')
    call s:AddMenuItem('n', 100, 'E&xit',              s:map_leader.'E', 'call <sid>ExitSpell()<CR>')
    " TODO: disable/enable menu->exit according to the current mode
    let name = substitute(s:menu_name, '&', '', 'g')
    exe 'menu disable '.escape(name.'Exit', ' \')

    IfTriggers 
	  \ call s:AddMenuItem('a', 100, '-1-', '', '<c-l>')
    IfTriggers 
	  \ call s:AddMenuItem('n', 100, 'Change &Language', s:map_leader.'L', '!VS_swapL!')

    call s:AddMenuItem('a', 510, '-2-', '', '<c-l>')
    call s:AddMenuItem('n', 510, '&Next misspelling', s:map_leader.'n', '<Plug>VS_nextE')
    call s:AddMenuItem('n', 510, '&Prev misspelling', s:map_leader.'p', '<Plug>VS_prevE')
  endif
endfunction " }}}
"------------------------------------------------------------------------
" Define the maps when buffers are loaded                {{{
function! s:CheckMapsLoaded(force)
  if (expand('%') !~ 'spell-corrector') &&
	\ (!exists('b:VS_map_loaded') || (1 == a:force))
    let b:VS_map_loaded = 1
    silent call s:Maps_4_file_edited()
  endif
endfunction
call s:CheckMapsLoaded(1)
call s:Global_menus()

augroup VS_maps
  au!
  au  BufNewFile,BufReadPost * :call s:CheckMapsLoaded(0)
augroup END
" }}}

" Part:		lhVimSpell/corrected buffer functions }}}
"=============================================================================
" Part:		lhVimSpell/interface to [ia]spell {{{
" Last Update:	09th feb 2003
"------------------------------------------------------------------------
" Description:	Interface functions to external spell-checkers like [ia]spell
"------------------------------------------------------------------------
" TODO:		
"=============================================================================
"

"===========================================================================
" Programs calls                       {{{
"------------------------------------------------------------------------
" Function: s:I_mode(ext,ft) : string                    {{{
function! s:I_mode(type)
  " 100% Aspell options {{{
  " if     a:type =~ 'tex\|sty'            | let mode = ' --mode='. a:type 
  " elseif a:type =~ 'htm\|xml\|php\|incl' | let mode = ' --mode=sgml'
  " else                                   | let mode = ''
  " endif
  " }}}

  " Aspell and Ispell compatible options {{{
  if     a:type =~ 'tex\|sty\|dtx\|ltx'                   | let mode = ' -t'
  elseif a:type =~ 'htm\|xml\|php\|incl\|xsl\|sgm\|docbk' | let mode = ' -H'
  elseif a:type =~ 'mail'                                 | let mode = ' -e'
  else                                                    | let mode = ''
  endif
  return mode . ' '
  " }}}
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:I_call_iaspell([parameter for ia-spell])     {{{
function! s:I_call_iaspell(...)
  let arg = (a:0 == 1) ? a:1 : ''
  return g:VS_spell_prog . ' -d ' . s:Language() . arg . ' '
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:I_pipe_to_iaspell(filename)                  {{{
function! s:I_pipe_to_iaspell(filename)
  " let cmd = SysCat(a:filename) . ' | ' . s:I_call_iaspell(' -a')
  let cmd = s:I_call_iaspell(' -a ') . ' < ' . FixPathName(a:filename)
  if s:Option('stripaccents', 0, 'g')
    let cmd = cmd . " --strip-accents " 
  endif
  return system(cmd)
endfunction
" }}}
"------------------------------------------------------------------------
" }}}
"===========================================================================
" List errors                          {{{
"------------------------------------------------------------------------
" Function: s:I_list_errors(filename, filetype_if_known) : string
" Retrieve the list (string) of misspellings
" Note: It even work on MsDos/Windows system, but it is slower if no Unix
" layer (like Cygwin or UnixUtils) has been installed.
function! s:I_list_errors(filename,ft)
  " type <- filetype (if given) or file-extension
  let type = (a:ft!="") ? a:ft : matchstr(a:filename, '[^.]\{-}$')
  " Fix the filename path according to the current shell.
  let filename = FixPathName(a:filename)
  " Check which `sort' will be used
  let msdos = (SystemDetected() == 'msdos') && !UnixLayerInstalled()
  let sort = !msdos ? ' | '.SysSort('-u') : ''
  if s:verbose > 0
    call confirm('calling: '.s:I_call_iaspell(s:I_mode(type)).
	  \ '-l < '.filename.sort, '&Ok', 1)
  endif
  let res  = system(
	\ s:I_call_iaspell(s:I_mode(type)).'-l < '.filename.sort)
  if msdos
    " Special case: on a pure msdos/windows box, `SORT.EXE' is not suitable,
    " hence we emule it as well as `uniq'
    :silent new
    :silent 0put=res
    :Sort
    :Uniq
    let save_a = @a
    :silent %yank a
    let res = @a
    let @a = save_a
    :silent bd!
  endif

  " Return the sorted list of misspellings
  if s:verbose > 0
    call confirm('misspellings found: '.substitute(res, "\r\\|\n", ' ; ', 'g'),
	  \ '&Ok', 1)
  endif
  return res
endfunction
" }}}
"===========================================================================
" Get alternatives                     {{{
"------------------------------------------------------------------------
" Fill a temporary file with the alternative for every misspellings (a:error)
" If fail    : nothing done, empty string returned
" If success : string returned == name of the temporary file for which a
"              buffer is stil open.
function! s:I_get_alternatives(errors)
  let lang = s:Language()
  " filename of a temporary file
  let tmp = tempname()
  
  " split open a new buffer
  silent exe 'split ' . tmp
  " write the list of misspellings to the buffer
  silent 0put = a:errors
  " purge empty lines
  silent g/^$/d
  " write the result and then clear the buffer
  silent w | silent %delete _
  " if the file is empty => abort !
  if 0 == getfsize(tmp) 
    silent bd!
    call delete(tmp)
    return ''
  endif
  " execute aspell, the result is inserted in the current tmp buffer
  let b:VS_language = lang
  let alts = s:I_pipe_to_iaspell(tmp)
  silent 0put=alts
  " delete empty lines
  silent g/^$/d
  " delete '^*$'
  silent g/\*/d
  " write
  silent w
  " return the file name
  return tmp
endfunction
" }}}
"===========================================================================
" Maintenance                          {{{
"------------------------------------------------------------------------
" Function: s:I_aspell_directly_to_dict(word, lowcase)   {{{
function! s:I_aspell_directly_to_dict(word,lowcase)
  " 1- Check we are using Aspell
  if (g:VS_spell_prog !~ '.*aspell\(\.exe\)\=$')
    call s:ErrorMsg("Can not add «".a:word."» directly into the dictionary.\n"
	  \       . "\nThis option is only available with aspell.\n")
    return
  endif
  " 2- Add it
  " 2.a/ Open the ASPELL local-dictionary
  silent exe 'split '.s:Personal_dict() 
  " 2.b/ Increment the number of word
  silent exe "normal! $\<c-a>"
  " 2.c/ Add the word to the last line
  silent $put=a:word
  " 2.d/ chage it to lower case if required
  if a:lowcase == 1 | silent normal! guu 
  endif
  " 2.e/ save and close
  silent w | silent bd
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:I_add_word_to_dict(word, lowcase)          {{{
" If the word to add contains accents, the function offer the choice to
" directly add the word to the dictionary, without using ASPELL. 
" Reason : aspell (under windows/MinGW-build only ?) is not able to add
" accentuated words to the dictionary. Hence, I've chosen to add this kind
" of words directly in the dictionary file.
function! s:I_add_word_to_dict(word,lowcase)
  if g:VS_aspell_add_directly_to_dict == 1
    return s:I_aspell_directly_to_dict(a:word, a:lowcase)
  endif
  if (g:VS_spell_prog=~'.*aspell\(\.exe\)\=') && match(a:word, "[^A-Za-z']") != -1 
    " accentuated word
    let c = confirm("The word «".a:word."» contains accentuated characters.\n"
	  \ . "Are you sure you want to add it to the dictionary ?",
	  \ "&Yes\n&Abort", 1, "Warning")
    if c == 1 
      call s:I_aspell_directly_to_dict(a:word, a:lowcase)
    endif
    return
  else
    " Classical method
    " if a:lowcase == 1 | let cmd = "&" | else | let cmd = "*" | endif
    let cmd = (a:lowcase == 1) ? '&' : '*'
    let cmd = cmd . a:word 
    " Save the dictionary
    let cmd = cmd . "\n#"
    let tmp = tempname()
    silent exe "split ".tmp
    silent 0put=cmd
    silent w | silent bd
    call s:I_pipe_to_iaspell(tmp)
    call delete(tmp)
  endif
endfunction
" }}}
"------------------------------------------------------------------------
" }}}
"===========================================================================

" Part:		lhVimSpell/interface to [ia]spell }}}
"=============================================================================
" Part:		lhVimSpell/files management function {{{
" Last Update:	09th feb 2003
"------------------------------------------------------------------------
" Description:	Files Management functions for Vim-Spell to [ia]spell
"------------------------------------------------------------------------
" TODO:		«missing features»
"=============================================================================

"===========================================================================
" Function: s:FileExist({filename})                      {{{
function! s:FileExist(filename)
  if !filereadable(a:filename)
    call s:ErrorMsg("Error! " . a:filename . " does not exist!")
    return 0
  else
    return 1
  endif
endfunction " }}}
"------------------------------------------------------------------------
" Function: s:F_parse_file(full_path_to_file, filetype)  {{{
" ie: -> call s:F_parse_file(expand('%:p'),&ft) : need the complete path
function! s:F_parse_file(filename,ft)
  " 1- Retrieve the list of errors
    " note: as s:FileExist() is used, F_parse_file() can not be made completly
    " silent.
    if !s:FileExist(a:filename) | return | endif
    let lst = s:I_list_errors(a:filename,a:ft)

  " 2- Check for new errors
    let path = fnamemodify(a:filename,':p:h')
    let no_new_error = -1 == s:CheckNewErrors(path,lst)
    if no_new_error
      VSgEchoMsg 'No new misspelling...' 
    endif

  " 3- Enter correction mode.
  "    Build the Syntax for error and the regex search.
    call s:Show_errors()
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:Parse_current_file()                       {{{
function! s:Parse_current_file()
  call s:F_parse_file(expand('%:p'),&ft)
endfunction
" }}}
"===========================================================================
" Function: s:ExitSpell()                                {{{
" Clear errors
function! s:ExitSpell()
  if &ft != "vsgui" | call s:G_Open_Corrector() | endif
  silent bd!
  " clear the mispelled words
  silent syn clear
  silent syntax on
  " Restore cmd height {{{
  if exists('s:line_height')
    silent let &cmdheight=s:line_height
    unlet s:line_height
  endif " }}}
endfunction " }}}
"===========================================================================
" Show errors                          {{{
" Function: s:Show_errors()                              {{{
" -> start correction mode!
function! s:Show_errors()
    let spell_options = s:CheckSpellLanguage()

    " Load errors-list, abort if none
    let elf = s:F_error_list_file(expand("%:p:h"))
    if ('' == elf) || !filereadable(elf) 
      VSgErrorMsg "No file parsed in this directory..."
      return 
    endif

    " Prepare a temp. file
    let tmp = tempname()
    silent exe "split ".tmp
    silent exe ':r '.elf

    " Delete the header
    silent g/^@(#)/d
    """ todo: Delete Ignored words
    ""g/^I .*/d

    " Build the SpellErrors syntax "pattern"
    let v:errmsg = ''
    exe 'silent! %s/^[&*#] \(\S\+\).*$/syntax match SpellErrors "\\<\1\\>"'.spell_options
    if strlen(v:errmsg)
      " ie. no misspelling
      silent bd!
      call delete(tmp)
      return -1
    endif
    silent wq

    " Do highlight the misspellings
    syn case match
    syn match SpellErrors "xxxxx"
    syn clear SpellErrors
    "syn region Misspelling start="\k" end="\W*" contains=SpellErrors transparent
    exe "source ".tmp
    exe "silent bd! ".tmp
    call delete(tmp)
    
    " Load ignored words
    let ilf = s:F_ignore_list_file(expand("%:p:h"))
    if (""!=ilf) && filereadable(ilf)
      exe "so ".ilf
    endif

    " Enable the highlighting of misspellings for the current filetype {{{
    "syn cluster Spell contains=Misspelling,SpellCorrected
    if &ft == 'tex'
      syn cluster texCommentGroup	add=SpellErrors,Normal
      syn cluster texMatchGroup		add=SpellErrors,Normal
      " Sometimes, we don't want the next group to be searched ...
      syn cluster texCmdGroup		add=SpellErrors,Normal
    elseif &ft == 'bib'
      syn cluster bibVarContents     	contains=SpellErrors,Normal
      syn cluster bibCommentContents 	contains=SpellErrors,Normal
    else 
      " Thanks to Claudio Fleiner's syntax files, we can use the @Spell
      " cluster to highlight misspellings.
      " It works for sure with cs, dtml, html, java, and m4 files (w/ vim 6.1)
      let a_save = @a
      redir @a
	silent! syn list @Spell
      redir END
      if -1 != match(@a, 'Spell\s\+cluster=')
	syn cluster Spell	     	add=SpellErrors,Normal
	" TODO: else autodetect comments and strings
      endif
      let @a = a_save
    endif
    " }}}
    " Actual color for misspellings ; todo: permit overriding
    hi default link SpellErrors Error

    " cmd-line of at least 2 height... {{{
    if !exists('s:line_height')
      if &cmdheight < 2
	silent let s:line_height = &cmdheight
	set cmdheight=2
      endif
    endif " }}}
    " silent call s:Maps_4_file_edited()
    return 1
endfunction " }}}
" }}}
"===========================================================================
"===========================================================================
" Names of the different files used    {{{
"
" Ex.: name of the file listing the errors
" 	-> <spath>/.spell/errors-list
" 	-> <spath>/.spell/ignore-list
" 	-> <spath>/.spell/spell-corrector
"------------------------------------------------------------------------
" Function: s:F_check_for_VS_path(path)                  {{{
" Check the sub directory ./.spell/ exists.
function! s:F_check_for_VS_path(path)
  let path = fnamemodify(a:path,':p:h')
  let path = fnamemodify(a:path . '/.spell', ':p')
  if !isdirectory(path)
    if filereadable(path)
      call s:ErrorMsg("A file is found were a folder is expected: " . path)
      return
    endif
    let v:errmsg=""
    if &verbose >= 1 | echo "Create <".path.">\n" | endif
    call system(SysMkdir(path))
    if strlen(v:errmsg) != 0
      call s:ErrorMsg(v:errmsg)
    elseif !isdirectory(path)
      VSgErrorMsg "Can't create <".path.">"
    endif
  endif
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:F_error_list_file(path)                    {{{
" Returns: 	The name of the errors list file according to the required path
" NB:		Checks the path exists
" Format:	by line: the one produced by «echo 'word' | aspell -a»
function! s:F_error_list_file(path)
  call s:F_check_for_VS_path(a:path)
  return a:path . '/.spell/errors-list'
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:F_ignore_list_file(path)                   {{{
" Returns: 	The name of the file containing the ignored words according to
" 		the required path 
" NB:		Checks the path exists
function! s:F_ignore_list_file(path)
  call s:F_check_for_VS_path(a:path)
  return a:path . '/.spell/ignore-list'
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:F_corrector_file(path)                     {{{
" Returns:	The name of the file used for the corrector buffer
function! s:F_corrector_file(path)
  let path = fnamemodify(a:path . '/.spell', ':p:h')
  return a:path . '/.spell/spell-corrector'
endfunction
" }}}
"------------------------------------------------------------------------
" }}}
"===========================================================================
" Function: s:CheckNewErrors(path,errors)                {{{
" Purpose: Check for new misspellings
function! s:CheckNewErrors(path,errors)
  " 0- File name of the list-errors file
    let elf = s:F_error_list_file(a:path)

  " 1- Comparaison
  "    i-  If did not exist => add everything
  "    ii- add what is new
  " 1.1- Determine what the new errors are
    if !filereadable(elf) | let new = a:errors
    else                  | let new = s:F_compare(elf,a:errors)
    endif
  " 1.2- Build their alternatives
    let tmp = s:F_build_alternatives(new)
    if "" == tmp
      return -1
    endif
  " 1.3- Add them to elf
    call FindOrCreateBuffer(elf,1)	" from a.vim
    silent exe "$r ".tmp
    silent g/^$/d
    " Merge the header lignes produced by aspell in only one.
    silent g/^@(#)/d
    silent 0put=@"
    " Write and quit errors-list
    silent w! | silent bd
    " Purge intermediary buffer
    silent exe "bd ".tmp
    call delete(tmp)
    return 1
endfunction
" }}} 
"===========================================================================
" Build Alternatives for a list of errors {{{
function! s:F_build_alternatives(errors)
  return s:I_get_alternatives(a:errors)
endfunction
" }}}
"===========================================================================
" Compare new errors to errors-list {{{
function! s:F_compare(elf,errors)
    call FindOrCreateBuffer(a:elf,1)	" from a.vim
    let new="" | let er=a:errors
    while "" != er
      let word = matchstr(er, "[^\n]*")
      ""echo "word  -- " . word . "\n"
      let er   = substitute(er, "[^\n]*\n".'\(.*\)$', '\1', '')
      ""echo "er    -- " . er . "\n"
      let found=0
      silent exe 'g/^[#*&] \<'.word.'\>/ let found=1'
      if found == 0
	let new = new . "\n" . word
      endif
      ""echo "found -- " . found . "\n"
    endwhile
    silent bd
    return new
endfunction
" }}}
"===========================================================================
" Functions to manage ignored words {{{
"
" Function: s:F_add_word_to_ignore_file(word) 
function! s:F_add_word_to_ignore_file(word)
    let ilf = s:F_ignore_list_file(expand("%:p:h"))
    if "" == ilf | return | endif

    " Add the pattern to the "ignore" file
    silent exe "split ".ilf
    if search('/'.a:word.'/$') == 0
      silent $put='syn match Normal /'.a:word.'/'
    endif
    silent w | silent bd
endfunction
" }}}
"===========================================================================
" Move from one error to the next {{{
"
" Functions stolen in David Campbell's engspchk.vim
" -------------------------------------------------------------------
" Function: s:SpchkNext() {{{
" Returns: 1 in case of a successful jump, 0 otherwise
function! s:SpchkNext()
  let errid = hlID("SpellErrors")
  let lastline= line("$")
  let curcol  = 0
  let pos = line('.').'normal! '.virtcol('.').'|'

  silent! norm! w

  " skip words until we find next error
  while synID(line("."),col("."),1) != errid
    silent! norm! w
    if line(".") == lastline
      let prvcol=curcol
      let curcol=col(".")
      if curcol == prvcol 
	exe pos
	VSgErrorMsg 'No next misspelling'
	return 0
      endif
    endif
  endwhile

  return 1
endfunction
" }}}
" -------------------------------------------------------------------
" Function: s:SpchkPrev() {{{
" Returns: 1 in case of a successful jump, 0 otherwise
function! s:SpchkPrev()
  let errid = hlID("SpellErrors")
  let curcol= 0
  let pos = line('.').'normal! '.virtcol('.').'|'

  silent! norm! b

  " skip words until we find previous error
  while synID(line("."),col("."),1) != errid
    silent! norm! b
    if line(".") == 1
      let prvcol=curcol
      let curcol=col(".")
      if curcol == prvcol 
	exe pos
	VSgErrorMsg 'No previous misspelling'
	return 0
      endif
    endif
  endwhile

  return 1
endfunction
" }}}
" -------------------------------------------------------------------
" }}}

" Part:		lhVimSpell/file management function }}}
"=============================================================================
" Part:		lhVimSpell/mappings for the corrector buffer {{{
" Last Update:	10th feb 2003
"------------------------------------------------------------------------
" Description:	Defines the mappings and menus for the Corrector buffer.
"------------------------------------------------------------------------
" TODO:		«missing features»
"=============================================================================

"===========================================================================
" Help                                 {{{
"------------------------------------------------------------------------
function! s:Add2help(msg, help_var) " {{{
  if (!exists(a:help_var))
    exe 'let ' . a:help_var . '   = a:msg'
    exe 'let ' . a:help_var . 'NB = 0'
  else
    exe 'let ' . a:help_var . ' = ' . a:help_var . '."\n" . a:msg'
  endif
  ""let g:vsgui_help_maxNB = g:vsgui_help_maxNB+1
  exe 'let ' . a:help_var . 'NB = ' . a:help_var . 'NB + 1 '
endfunction " }}}
"------------------------------------------------------------------------
if !exists(":VSAHM") " {{{
  command! -nargs=1 VSAHM call s:Add2help(<args>,"s:vsgui_help")
  VSAHM  "@| <cr>, <double-click> : Replace with current word"
  VSAHM  "@| <A>                  : Replace every occurrence of the misspelled word "
  VSAHM  "@|                        within the checked buffer"
  VSAHM  "@| <B>                  : Replace every occurrence of the misspelled word "
  VSAHM  "@|                        within all buffers"
  VSAHM  "@| <esc>                : Abort"
  VSAHM  "@| *, &                 : Add word to the dictionary (may be in lower case)"
  VSAHM  "@| <i>                  : Ignore the word momentarily"
  VSAHM  "@| <cursors>, <tab>     : Move between entries"
  VSAHM  "@|"
  VSAHM  "@| <u>/<C-R>            : Undo/Redo last change"
  VSAHM  "@| <M-n>, <M-p>         : Move between misspelled words in the checked buffer"
  VSAHM  "@| h                    : Don't display this help"
  VSAHM  "@+-----------------------------------------------------------------------------"

  command! -nargs=1 VSAHM call s:Add2help(<args>,"s:vsgui_short_help")
  VSAHM  "@| h                    : Display the help"
  VSAHM  "@+-----------------------------------------------------------------------------"
endif " }}}
"------------------------------------------------------------------------
function! s:G_help() " {{{
  if g:VS_display_long_help	| return s:vsgui_help
  else				| return s:vsgui_short_help
  endif
endfunction " }}}
"------------------------------------------------------------------------
function! s:G_help_NbL() " {{{
  " return 1 + nb lignes of BuildHelp
  if g:VS_display_long_help	| return 1 + s:vsgui_helpNB
  else				| return 1 + s:vsgui_short_helpNB
  endif
endfunction " }}}
"------------------------------------------------------------------------
function! s:Toggle_gui_help() " {{{
  let g:VS_display_long_help = 1 - g:VS_display_long_help
  silent call s:G_MakeAlternatives(b:word)
endfunction " }}}
"------------------------------------------------------------------------
" }}}
" ======================================================================
" Mappings and menus                   {{{
"------------------------------------------------------------------------
" Function: s:G_AltLoadMaps()                            {{{
function! s:G_AltLoadMaps()
  nnoremap <silent> <buffer> <cr>	:call <sid>SA_return(line('.'))<cr>
  nnoremap <silent> <buffer> <2-LeftMouse> :call <sid>SA_return(line('.'))<cr>
  nnoremap <silent> <buffer> A		:call <sid>SA_all(line('.'))<cr>
  nnoremap <silent> <buffer> B		:call <sid>SA_all_buffers(line('.'))<cr>
  nnoremap <silent> <buffer> *		:call <sid>G_AddWord(0)<cr>
  nnoremap <silent> <buffer> &		:call <sid>G_AddWord(1)<cr>
  nnoremap <silent> <buffer> i		:call <sid>G_IgnoreWord()<cr>
  nnoremap <silent> <buffer> <esc>	:call <sid>SA_return(-1)<cr>

  nnoremap <silent> <buffer> <s-tab>	:call <sid>G_NextChoice(0)<cr>
  nnoremap <silent> <buffer> <tab>	:call <sid>G_NextChoice(1)<cr>

  nnoremap <silent> <buffer> <M-n>	:call <sid>G_NextError()<cr>
  nnoremap <silent> <buffer> <M-p>	:call <sid>G_PrevError()<cr>

  nnoremap <silent> <buffer> u		:call <sid>G_UndoCorrection(1)<cr>
  nnoremap <silent> <buffer> <c-r>	:call <sid>G_UndoCorrection(0)<cr>
  nnoremap <silent> <buffer> <M-s>E	:call <sid>ExitSpell()<CR>
  nnoremap <silent> <buffer> h		:call <sid>Toggle_gui_help()<cr>
  nnoremap <silent> <buffer> ?		:call <sid>Toggle_gui_help()<cr>

  nnoremap <buffer> <k0>		:VSChooseWord 0
  nnoremap <buffer> <k1>		:VSChooseWord 1
  nnoremap <buffer> <k2>		:VSChooseWord 2
  nnoremap <buffer> <k3>		:VSChooseWord 3
  nnoremap <buffer> <k4>		:VSChooseWord 4
  nnoremap <buffer> <k5>		:VSChooseWord 5
  nnoremap <buffer> <k6>		:VSChooseWord 6
  nnoremap <buffer> <k7>		:VSChooseWord 7
  nnoremap <buffer> <k8>		:VSChooseWord 8
  nnoremap <buffer> <k9>		:VSChooseWord 9
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
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:G_AltLoadMenus()                           " {{{
function! s:G_AltLoadMenus()
  let s:menu_start= 'menu <silent>'.s:menu_prio.'.200 '.s:menu_name
  call s:AddMenuItem('a', 200, '-3-', '', '<c-l>')
  call s:AddMenuItem('n', 200, 'Add to &dictionary', '*', '*')
  call s:AddMenuItem('n', 200, 'Idem low&case',      '&', '&')
  call s:AddMenuItem('n', 200, '&Ignore word',       'i', 'i')

  call s:AddMenuItem('a', 210, '-4-', '', '<c-l>')

  call s:AddMenuItem('n', 500, '&Undo', 'u', 'u')
  call s:AddMenuItem('n', 500, 'Re&do', '<c-r>', '<c-r>')

  call s:AddMenuItem('n', 510, '&Next misspelling', s:map_leader.'n', ':call <sid>G_NextError()<cr>')
  call s:AddMenuItem('n', 510, '&Prev misspelling', s:map_leader.'n', ':call <sid>G_PrevError()<cr>')

  let name = substitute(s:menu_name, '&', '', 'g')
  exe 'menu disable '.escape(name.'Run spell checker', ' \')
  exe 'menu disable '.escape(name.'Show misspellings', ' \')
  exe 'menu disable '.escape(name.'Show alternatives', ' \')
  IfTriggers 
	\ exe 'menu disable '.escape(name.'Change Language', ' \')
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:G_AltUnloadMenus()                         "{{{
function! s:G_AltUnloadMenus()
  let name = escape(s:menu_name, '\ ')
  exe 'aunmenu '.name.'-3-'
  exe 'nunmenu '.name.'Add\ to\ &dictionary<tab>*'
  exe 'nunmenu '.name.'Idem\ low&case<tab>\&'
  exe 'nunmenu '.name.'&Ignore\ word<tab>i'
  exe 'aunmenu '.name.'-4-'
  exe 'nunmenu '.name.'&Undo<tab>u'
  exe 'nunmenu '.name.'Re&do<tab><c-r>'

  call s:AddMenuItem('n', 510, '&Next misspelling', s:map_leader.'n', '<Plug>VS_nextE')
  call s:AddMenuItem('n', 510, '&Prev misspelling', s:map_leader.'p', '<Plug>VS_prevE')

  let name = substitute(s:menu_name, '&', '', 'g')
  exe 'menu enable '.escape(name.'Run spell checker', ' \')
  exe 'menu enable '.escape(name.'Show misspellings', ' \')
  exe 'menu enable '.escape(name.'Show alternatives', ' \')
  IfTriggers 
	\ exe 'menu enable '.escape(name.'Change Language', ' \')
endfunction
" }}}
"------------------------------------------------------------------------
" }}}

" Part:		lhVimSpell/mappings for the corrector buffer }}}
"=============================================================================
" Part:		lhVimSpell/corrector buffer functions {{{
" Last Update:	10th feb 2003
"------------------------------------------------------------------------
" Description:	Syntax and functions for VIM-spell GUI
"------------------------------------------------------------------------
" Note:
" (*) Whenever it is possible, add the single-quote to the keyword thanks
"     to set isk+='
"     Could be done with no harm with LaTeX, mail, and other text formats
" TODO:		«missing features»
"=============================================================================

"===========================================================================
" Syntax
"===========================================================================
" Function: s:G_AltSyntax()                              {{{
function! s:G_AltSyntax()
  if has("syntax")
    syn clear

    syntax region AltLine  start='\d' end='$' contains=AltNumber,AltName
    syntax region AltNbOcc  start='^--' end='$' contains=AltNumber,AltName
    syntax match AltNumer /^\t\d\+/ contained
    syntax match AltName /\S\+$/ contained

    syntax region AltExplain start='@' end='$' contains=AltStart
    syntax match AltStart /@/ contained
    syntax match Statement /--abort--/

    highlight link AltExplain Comment
    highlight link AltStart Ignore
    highlight link AltLine Normal
    highlight link AltName Identifier
    highlight link AltNumber Number
  endif
endfunction 
" }}}
"===========================================================================
" Functions
"===========================================================================
" Function: s:G_Open_Corrector()                         {{{
function! s:G_Open_Corrector()
  " open the corrector gui (split window)
  let gui = s:F_corrector_file(expand('%:p:h'))
  call FindOrCreateBuffer(gui,1)	" from a.vim
endfunction 
" }}}
"------------------------------------------------------------------------
" Function: s:Current_Word()                             {{{
function! s:Current_Word()
  let save_isk = &isk
  " Plus: for French, may be Italian and some other languages
  set isk+='
  set isk+=-
  " Minus: all the programmation stuff... not working -> TODO
  " set isk-=&~#{[()]}`_=$*%!:/;.?\\
  " set isk-=|
  " set isk-=,
  " set isk-=^
  let word     = expand("<cword>")
  let &isk     = save_isk
  return word
endfunction

function! s:IsWord(word)
  let save_isk = &isk
  " Plus: for French, may be Italian and some other languages
  set isk+='
  set isk+=-
  " Minus: all the programmation stuff...not working -> TODO
  " set isk-=&~#{[()]}`_^=$*%!:/;.?\\
  " set isk-=|
  " set isk-=,
  let res = (a:word =~ '^\K\+$')
  " call confirm('word='.a:word."\n isk=".&isk."\n res=".res, '&ok', 1)
  let &isk     = save_isk
  return res
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:G_Launch_Corrector()                       {{{
function! s:G_Launch_Corrector()
  " Means that the current window is not the Corrector window.
  let word     = s:Current_Word()
  let filename = expand("%")
  let W1       = winnr()
  let lang     = s:Language()

  call s:G_Open_Corrector()

  " transfert variables
  ""let b:word	 = word
  let b:filename    = filename
  let b:mainfile    = filename
  let b:W1	    = W1
  let b:W2	    = winnr()
  let b:VS_language = lang

  " Display the alternatives for the current word
  call s:G_AltSyntax()
  call s:G_MakeAlternatives(word)
endfunction 
" }}}
"------------------------------------------------------------------------
" Function: s:G_MakeAlternatives(word)                   {{{
" Build the alternatives for the current word
function! s:G_MakeAlternatives(word)
  " Note: :redraw is needed in order to let the upcoming echoings correclty
  " happen. It seems that otherwise, :split delays a :redraw just before the
  " user have the focus.
  redraw
  VSgEchoMsg ''

  " 0- Purge vsgui
  silent! %delete _

  " 1- Find word in errors-list
  let elf = s:F_error_list_file(fnamemodify(b:filename,':p:h'))
  if ("" == elf ) || !filereadable(elf)
    VSgErrorMsg "You need to parse some files first...  \nArborted!"
    silent bd!
    return 
  endif
  silent exe ':0r '.elf
  silent! exe '2,$v/^[&#*] '.a:word.'\s\+/d'
  let b:word = a:word

  " 2- Convert the list
  " 2.a- The help string
  if "" == b:word
    silent! 2,$g/^[@#&*]/d
    silent! 2,$g/^$/d
  endif
  let NbL = s:G_help_NbL()
  silent 1put = s:G_help()

  " 2.b- Special case: no word under the cursor 
  if "" == a:word
    silent $put ='-- No word selected'
    silent $put =''
    silent $put ='  --abort--'
    VSgEchoMsg 'No word selected...'
    return
  " elseif !s:IsWord(a:word)
  elseif (a:word !~ '\K\+') || (line('$') > NbL+1)
    " Some dawm characters are keywords, and are such than several entries in
    " the errors-list file are kept (instead of only one entry).
    if line('$') > NbL+1
      exe 'silent '.(NbL+1).',$delete _'
    endif
    silent $put ='-- <'.a:word.'> is not a word'
    silent $put =''
    silent $put ='  --abort--'
    VSgEchoMsg 'Incorrect word selected...'
    return
  endif

  " 2.c- The suggested alternatives
  let test = 0
  silent! g/^& .* \d\+ \d\+:/ let test = 1
  if test == 1
    let NbL = NbL + 1
    silent call s:G_mk_Alternatives(NbL)
    silent exe NbL."put = ''"
    silent put = '  --abort--'

  " 2.d- Just an known misspelling, but with no alternatives to propose
  else
    let test = 0
    silent g/^# .* \d\+/ let test = 1
    if test == 1
      silent $delete _
      silent $put ='-- No suggestion available for <'.a:word.'>'
      silent $put =''
      silent $put ='  --abort--'
      VSgEchoMsg "No suitable alternative for <".a:word.">..."

  " 2.e- This is a correct word
    else
      let test = 0
      silent g/^\*/ let test = 1
      if test == 1
	silent $delete _
	silent $put ='-- <'.a:word.'> is correct...'
	silent $put =''
	silent $put ='  --abort--'
	VSgEchoMsg "The word <".a:word."> is correct..."
	" TODO: must ask for sound-like words

  " 2.f- The word has never been checked by iaspell
      else " there are no alternative ; word never checked
	silent $put ='-- No suggestion available for <'.a:word.'>'
	silent $put =''
	silent $put ='  --abort--'
	VSgEchoMsg "The word <".a:word."> has been not checked yet..."
	" TODO: process a:word on the fly.

  " 2.end-
      endif
    endif
  endif

  ""call SpellAltMaps()

  " 3- Move the cursor to the first alternative
  call s:G_NextChoice(1)

  " 4- A little message ...
  if !exists('b:VS_first_time_in_correction_mode')
    VSgEchoMsg "\rCorrection mode activated..."
    let b:VS_first_time_in_correction_mode = 1
    " automatically unlet when the buffer is dismissed (:bd)
  endif
endfunction " }}}
"------------------------------------------------------------------------
" Function: s:G_mk_Alternatives(NbL)                     {{{
" -> known misspellings for which we can suggest corrections
" Note: must be called with `:silent'
function! s:G_mk_Alternatives(NbL)
  " Number the entries
  s/[:,]/\r##\t/g
  %g/##/exe "normal! cw\<tab>".(line('.')-a:NbL)."\<esc>"
  " Number of entries
  :g/^&.\D\+/ exe "normal! WWyw" | exe 'let NbAlt='.@"
  " toto: change previous line by a calculus based on line('$')
  :s/& \(.\{-}\) \(\d\+\) \d\+$/-- \2 alternatives to <\1>/
endfunction
" }}}
"------------------------------------------------------------------------
"===========================================================================
"===========================================================================
" Choose from a number {{{
"
" Does not work very well ...
command! -nargs=1 VSChooseWord :call s:G_ChooseWord(<q-args>)

" Function: s:G_ChooseWord(nb)
function! s:G_ChooseWord(nb)
  let nb = a:nb+3+s:G_help_NbL()
  if a:nb < 0 || nb>line('$')
    VSgErrorMsg "Invalid number, no alternative word corresponding"
  elseif nb == 0
    silent bd!
    VSgErrorMsg "Abort"
  else
    call s:SA_return(nb)
    " silent exe ":".nb
    " silent exe "normal \<cr>"
  endif
endfunction 
" }}}
"===========================================================================
" Choose from gui -- <cr> or <2-leftclick>
"------------------------------------------------------------------------
" Function: s:SA_GetAlternative(line)                    {{{
function! s:SA_GetAlternative(line)
  let NbL = s:G_help_NbL()+3
  if (a:line == NbL) || (a:line == -1)
    return ""
  elseif a:line > NbL
    return substitute(getline(a:line), '^.*\s\+', '', '')
  else
    return -1
  endif
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:SA_return(line)                            {{{
function! s:SA_return(line)
  let alt = s:SA_GetAlternative(a:line)
  if (strlen(alt) != 0) 
    if (alt != -1)
      ""let b_ID = bufnr('%')
      let W_ID = b:W1+1
      let word = b:word
      "swap windows
      let this = expand('%:p')
      call FindOrCreateBuffer(b:mainfile,1)
      let go = s:Current_Word() == word
      if !go
	VSgErrorMsg "<".word."> lost! Use <M-n> to go to next occurrence\n"
      else
	" Use a temporary mapping to change the word without enabling
	" embedded mappings to expand.
	"exe "normal! viwc" . alt . "\<esc>"
	exe "nnoremap =}= viwc".alt."\<esc>"
	silent exe "normal =}="
	unmap =}=
      endif
      "swap windows
      call FindOrCreateBuffer(this,1)
      if go
	VSgEchoMsg '<'.word.'> has been replaced with <'.alt.'>'
	VSgNextError
      endif
    endif
  else
    silent bd!
    VSgEchoMsg "\rAbort"
  endif
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:SA_all(line)                               {{{
function! s:SA_all(line)
  let alt = s:SA_GetAlternative(a:line)
  if (strlen(alt) != 0) 
    if (alt != -1)
      let b_ID = bufnr('%')
      ""let W_ID = b:W1+1
      let word = b:word
      "swap windows
      ""exe "normal! ".W_ID."\<c-W>x"
      silent exe 'b '.b:mainfile
      silent exe '%s/'.word.'/'. alt.'/g' 
      silent normal! "\<c-v>\<c-l>"
      "swap windows
      ""exe "normal! ".W_ID."\<c-W>x"
      silent exe ' b'.b_ID
      VSgEchoMsg 'Every occurences of <'.word.'> have been replaced with <'.alt.'>'
      VSgNextError
    endif
  endif
endfunction
" }}}
"------------------------------------------------------------------------
" Function: s:SA_all_buffers(line)                       {{{
function! s:SA_all_buffers(line)
  let alt = s:SA_GetAlternative(a:line)
  if (strlen(alt) != 0) 
    if (alt != -1)
      let word = b:word
      let b_ID = bufnr('%')
      let b_last = bufnr('$')
      let i = 1
      while i != b_last
	if i != b_Id
	  silent exe 'b '.i
	  silent exe '%s/'.word.'/'. alt.'/g' 
	endif
	let i = i + 1
      endwhile
      " reload the good buffer
      silent exe ' b'.b_ID
      VSgEchoMsg 'Every occurences of <'.word.'> have been replaced with <'
	    \ .alt.'> in every buffer'
      VSgNextError
    endif
  endif
endfunction
" }}}
"------------------------------------------------------------------------

"===========================================================================
" Move to choice {{{
function! s:G_NextChoice(isForward)
  call search('^\s*\d\+\s\+\zs', a:isForward ? '' : 'b')
endfunction
" }}}
"===========================================================================
" Move to errors {{{
function! s:G_NextError()
  let this = expand('%:p')
  call FindOrCreateBuffer(b:mainfile,1)
  call s:SpchkNext()
  let word = s:Current_Word()
  call FindOrCreateBuffer(this,1)
  call s:G_MakeAlternatives(word)
endfunction

function! s:G_PrevError()
  let this = expand('%:p')
  call FindOrCreateBuffer(b:mainfile,1)
  call s:SpchkPrev()
  let word = s:Current_Word()
  call FindOrCreateBuffer(this,1)
  call s:G_MakeAlternatives(word)
endfunction

command -nargs=0 VSgNextError 
      \ :if g:VS_jump_to_next_error_after_validation |
      \    call s:G_NextError() |
      \ endif

" }}}
"===========================================================================
" Undo {{{
function! s:G_UndoCorrection(isUndo)
  let this = expand('%:p')
  call FindOrCreateBuffer(b:mainfile,1)
  if a:isUndo == 1 | undo
  else             | redo
  endif
  let word = s:Current_Word()
  call FindOrCreateBuffer(this,1)
  call s:G_MakeAlternatives(word)
endfunction
" }}}
"===========================================================================
" Add words to the dictionary & Ignore words {{{
"===========================================================================
"
function! s:G_AddWord(lowCase)
  let word=b:word
  " 1- Request to the spell checker
  call s:I_add_word_to_dict(b:word,a:lowCase)
  " 2- Update the cached files
  let elf = s:F_error_list_file(fnamemodify(b:filename,':p:h'))
  if "" == elf | return | endif
  silent exe "split ".elf
  silent exe 'g/^[&#*]\s*'.word.'\s*/d'
  silent w | silent bd
  call s:G_ReShowErrors()
  redraw
  VSgEchoMsg '<'.word.'> has been added to the personal dictionary'
  VSgNextError
endfunction

function! s:G_IgnoreWord()
  let this = expand('%:p')
  let word = b:word
  call FindOrCreateBuffer(b:mainfile,1)
  exe 'syn match Normal /'.word.'/'
  call s:F_add_word_to_ignore_file(word)
  call FindOrCreateBuffer(this,1)
  redraw
  VSgEchoMsg '<'.word.'> will be ignored for the files in this directory'
  VSgNextError
endfunction

function! s:G_ReShowErrors()
  let this = expand('%:p')
  call FindOrCreateBuffer(b:mainfile,1)
  call s:Show_errors()
  call FindOrCreateBuffer(this,1)
endfunction
" }}}
"===========================================================================
" Load the maps {{{
"===========================================================================
"
" Rem: name of the file type must be simple ; for instance VS_gui does not
" fit, but vsgui does.
"
" Could and must be converted to vim6 -- alternative

aug VS_g_Alternative_AU
  au!
  au BufNewFile,BufRead spell-corrector* set ft=vsgui
aug END
if has('gui_running') && has('menu')
  aug VS_g_Alternative_AU
    au BufEnter           spell-corrector* silent call s:G_AltLoadMenus()
    au BufLeave           spell-corrector* silent call s:G_AltUnloadMenus()
  aug END
endif
au Syntax vsgui silent call s:G_AltLoadMaps()
" }}}

" Part:		lhVimSpell/corrector buffer functions }}}
"=============================================================================
"
"------------------------------------------------------------------------
"=============================================================================
" vim600: set fdm=marker:
