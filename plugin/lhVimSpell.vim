"=============================================================================
" File:		lhVimSpell.vim {{{
" Author:	Luc Hermitte <EMAIL:hermitte@free.fr>
"		<URL:http://hermitte.free.fr/vim>
" Version:	0.3
" Created:	One day in 2001
" Last Update:	03rd jul 2002
" }}}
"------------------------------------------------------------------------
" Description:	Spellcheck plugin for VIM. {{{
"               This plugin wraps call to ispell (/aspell) and have *many*
"               other features. cf. |VS_help.txt|
"               }}}
"------------------------------------------------------------------------
" Installation:	 {{{
" The plugin is composed of several files. I suppose here that you have the
" end user version (otherwise, run make!) that contains :
"   - lhVimSpell.vim	: the main file of the plugin
"   - VS_gui-map.vim	: mappings for the corrector mode buffer
"   - a.vim		: an old version of Michael Sharpe plugin
"   - ChangeLog		: changes history
"   - VS_help.txt	: the documentation of the plugin in VIM help format
"   - VS_help.html	: the same documentation but in HTML.
"
" (*) With VIM 5.x versions: {{{
"   - drop the three .vim files into your $VIM/macros/ directory
"   - keep the documentation around -- I don't know if there is a better
"     method
"   - and source lhVimSpell.vim whenever you need the plugin (manually,
"     automatically from .vimrc, automatically thanks to ftplugin-like
"     facilities)
"   }}}
" (*) With VIM 6.x version : {{{
"   I use the notation $$ as a shortcut to $HOME/.vim/ (for *NIX systems) or
"   $HOME/vimfiles/ (for Ms-Windows systems) ; check ":help 'runtimepath'" for
"   other systems.
"   - drop the documentation files into $$/doc and execute (from VIM)
"     ':helptags' once.
"   - If you want the plugin to be systematically run: drop the three vim
"     files into your $$/plugin/ directory
"     Or, if you want the plugin to be run only in specific situations: drop
"     them into your $$/macros/ directory, and source it whenever you need it.
"     For instance, I execute ":runtime macros/lhVimSpell.vim" from my TeX
"     ftplugin.
"   }}}
" In all cases, VS_gui-map.vim and lhVimSpell.vim *MUST* be in the same
" directory.
" For other dependencies aspects, check |VS_help.txt|
" 
" N.B.: there also exist my developper version of the plugin : lhVimSpell.vim
" is actually the concatenation of several thematic files. If you want to hack
" the plugin, it could be easier to check
"      <http://hermitte.free.fr/vim/ressources/vim-spell-dev.tar.gz>
" }}}
" History:	cf. Changelog
" TODO:		cf. |VS_help.txt|
"=============================================================================
"
"------------------------------------------------------------------------
" Avoid reinclusion
if !exists("g:loaded_lhVimSpell_vim") 
let g:loaded_lhVimSpell_vim = 1

"=============================================================================
" Part:		lhVimSpell/options {{{
" Last Update:	03rd jul 2002
"------------------------------------------------------------------------
" Description:	Options for lhVimSpell
"------------------------------------------------------------------------
" Installation:	If you'd rather have other default values for the options, do
" the assignments into your .vimrc.
" TODO:		«missing features»
"=============================================================================

function! VS_set_if_null(var, value)
  if (!exists(a:var)) | exe "let ".a:var." = a:value" | endif
endfunction
command -nargs=+ VSDefaultValue :call VS_set_if_null(<f-args>)

VSDefaultValue g:VS_stripaccents		0
VSDefaultValue g:VS_spell_prog			aspell
VSDefaultValue g:VS_aspell_add_directly_to_dict	0
VSDefaultValue g:VS_jump_next_error_after	1
VSDefaultValue g:VS_display_long_help		0

delcommand VSDefaultValue

function! VS_default_language() " {{{
  if exists('g:VS_language') && strlen('g:VS_language') | return | endif
  let lang = $LANG
  if lang =~? '^FR\|fr_FR'           | let g:VS_language = 'francais'
  elseif lang =~ '^uk_UK\|^us_US'    | let g:VS_language = 'english'
  elseif lang =~ '^de_DE'            | let g:VS_language = 'de'
  else 
    :echoerr "The language $LANG=".lang." is not reconized. Assuming English.  ".
	  \ "Please check the functions VS_default_language() ".
	  \ "and VS_personal_dict()"
    let g:VS_language = 'english'
  endif
endfunction 
call VS_default_language()
" }}}

" Function to compute the name of the personal dictionary for ASPELL
" You may have to customize it to your own needs.
function! VS_personal_dict()  " {{{
  if     g:VS_language == "francais" | return expand("$ASPELL/fr.pws")
  elseif g:VS_language == "english"  | return expand("$ASPELL/english.pws")
  elseif g:VS_language == "american" | return expand("$ASPELL/english.pws")
  elseif g:VS_language == "de"       | return expand("$ASPELL/de.pws")
  elseif exists('g:VS_language') && strlen('g:VS_language')
    return expand("$ASPELL/").g:VS_language.".pws"
  else
    :echoerr "The language option is not set.  "
	  \ "Please check the function VS_personal_dict()"
  endif
endfunction " }}}

function! CheckSpellLanguage() " {{{
  if !exists("b:spell_options") | let b:spell_options="" | endif
endfunction " }}}


" Part:		lhVimSpell/options}}}
"=============================================================================
" Part:		lhVimSpell/dependencies {{{
" Last Update:	31st jan 2002
"------------------------------------------------------------------------
" Description:	Check for other non essential VIM plugins.
"------------------------------------------------------------------------
" TODO:		«missing features»
"=============================================================================
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
else " silent comment
  command! -nargs=* IfTriggers Silent :"<args>
endif

if !exists("*FindOrCreateBuffer")
  let ff = expand('<sfile>:p:h'). '/a.vim'
  let msg=''
  if filereadable(ff) | exe 'source '.ff
  elseif version >= 600
    runtime macros/a.vim plugin/a.vim
  else
    msg = '<a.vim> is not visible from '.expand('<sfile>:p:h')."/\n"
  endif

  if !exists("*FindOrCreateBuffer")
    echohl ErrorMsg
    echo msg.'Make sure <a.vim> correctly exports the function '.
	  \ 'FindOrCreateBuffer()'
    echohl None
  endif
endif

" Part:		lhVimSpell/dependencies }}}
"=============================================================================
" Part:		lhVimSpell/corrected buffer functions {{{
" Last Update:	03rd jul 2002
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
  noremap ¡VS_check!	:update<cr>:call VS_parse_file(expand('%:p'))<cr>
  noremap ¡VS_showE!	:call VS_show_errors()<cr>
  noremap ¡VS_nextE!	:call VS_SpchkNext()<cr>
  noremap ¡VS_prevE!	:call VS_SpchkPrev()<cr>

  noremap ¡VS_alt!	:call VS_g_Launch_Corrector()<cr>
  
  noremap ¡VS_addW!	:call VS_add_word()<cr>
  noremap ¡VS_ignW!	:call VS_ignore_word()<cr>

  IfTriggers
	\ noremap ¡VS_swapL!	:call Trigger_DoSwitch('¡VS_swapL!', 
			\ 'let g:VS_language="american"', 
			\ 'let g:VS_language="'.g:VS_language.'"', 1, 1)<cr>
  noremap ¡VS_exit!	:let @_=VS_ExitSpell()<CR>
" }}}
" ========================================================================
if version < 600 
  function! VS_Maps_4_file_edited() " {{{
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
  endfunction " }}}
else
" ------------------------------------------------------------------------
  function! VS_Maps_4_file_edited() " {{{
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
  endfunction " }}}
endif

  call VS_Maps_4_file_edited()

" Part:		lhVimSpell/corrected buffer functions }}}
"=============================================================================
" Part:		lhVimSpell/interface to [ia]spell {{{
" Last Update:	03rd jul 2002
"------------------------------------------------------------------------
" Description:	Interface functions for Vim-Spell to [ia]spell
"------------------------------------------------------------------------
" Inspiration:	VIMspell.vim by Claudio Fleiner <claudio@fleiner.com>
" TODO:		«missing features»
"=============================================================================
"

"===========================================================================
" Programs calls
function! VS_i_Call_Spell_type(type,...)
  if a:type == "tex"                    | let mode = ' --mode='. a:type 
  elseif a:type =~'htm\|xml\|php\|incl' | let mode = ' --mode=sgml'
  else                                  | let mode = ''
  endif

  let ret = g:VS_spell_prog . ' -d ' . g:VS_language . mode . ' '
  if a:0 == 1	" direct parameters
    let ret = ret . a:1
  endif
  return ret
endfunction

function! VS_i_Call_Spell(...)
  if a:0 == 1
    ""return VS_i_Call_Spell_type(&ft,a:1)
    return VS_i_Call_Spell_type("",a:1)
  else
    ""return VS_i_Call_Spell_type(&ft)
    return VS_i_Call_Spell_type("")
  endif
endfunction


"===========================================================================
" List errors

function! VS_i_list_errors(filename)
  let type = matchstr(a:filename, '[^.]\{-}$')
  "echo  'system('.VS_i_Call_Spell_type(type).' -l < '.a:filename.' | sort -u)'
  return system(VS_i_Call_Spell_type(type).' -l < '.a:filename.' | sort -u')
endfunction

"
"===========================================================================
" Get alternatives
function! VS_i_get_alternatives(errors)
"   if exists("g:VS_stripaccents") && g:VS_stripaccents == 1
"     return system('echo "'.a:errors.'" \| '.
"       \ VS_i_Call_Spell('--strip-accents -a'))
"   else
"     return system('echo "'.a:errors.'" \| '. VS_i_Call_Spell(' -a') )
"   endif
  let tmp = tempname()
  let cmd = 'r!cat ' . tmp . ' | ' . VS_i_Call_Spell(' -a')
  if g:VS_stripaccents == 1 | let cmd = cmd . " --strip-accents " | endif
  
  exe "split "  . tmp
  0put = a:errors
  g/^$/d
  w | v//d
  exe cmd
  " delete empty lines
  g/^$/d
  " delete '^*$'
  g/\*/d
  w
  return tmp
  ""call delete(tmp)
endfunction

function! VS_i_get_alternatives_by_file(filename)
  if exists("g:VS_stripaccents") && g:VS_stripaccents == 1
    return system('cat '.a:filename.' \| '.
      \ VS_i_Call_Spell('--strip-accents -a'))
  else
    return system('cat ' .a:filename . ' \| '. VS_i_Call_Spell(' -a') )
  endif
endfunction

"===========================================================================
" Maintenance
" 
function! VS_i_aspell_directly_to_dict(word,lowcase)
  " 1- Check we are using ASpell
  if (g:VS_spell_prog != "aspell")
    echohl ErrorMsg
    echo   "Can not add «".a:word."» directly into the dictionary.\n"
    echo   "This option is only available with aspell.\n"
    echohl None
    return
  endif
  " 2- Add it
  " 2.a/ Open the ASPELL local-dictionary
  exe 'split '.VS_personal_dict() 
  " 2.b/ Increment the number of word
  exe "normal! $\<c-a>"
  " 2.c/ Add the word to the last line
  $put=a:word
  " 2.d/ chage it to lower case if required
  if a:lowcase == 1 | normal guu | endif
  " 2.e/ save and close
  w | bd
endfunction
" 
" If the word to add contains accents, the function offer the choice to
" directly add the word to the dictionary, without using ASPELL. 
" Reason : aspell (under windows/MinGW-build only ?) is not able to add
" accentuated words to the dictionary. Hence, I've chosen to add this kind
" of words directly in the dictionary file.
function! VS_i_add_word_to_dict(word,lowcase)
  if g:VS_aspell_add_directly_to_dict == 1
    return VS_i_aspell_directly_to_dict(a:word, a:lowcase)
  endif
  if (g:VS_spell_prog=="aspell") && match(a:word, "[^A-Za-z']") != -1 
    " accentuated word
    let c = confirm("The word «".a:word."» contains accentuated characters.\n"
	  \ . "Are you sure you want to add it to the dictionary ?",
	  \ "&Yes\n&Abort", 1, "Warning")
    if c == 1 
      call VS_i_aspell_directly_to_dict(a:word, a:lowcase)
    endif
    return
  else
    " Classical method
    if a:lowcase == 1 | let cmd = "&" | else | let cmd = "*" | endif
    let cmd = cmd . a:word 
    " Save the dictionary
    let cmd = cmd . "\n#"
    let tmp = tempname()
    exe "split ".tmp
    0put=cmd
    w | bd
    call VS_i_get_alternatives_by_file(tmp)
    call delete(tmp)
  endif
endfunction

" Part:		lhVimSpell/interface to [ia]spell }}}
"=============================================================================
" Part:		lhVimSpell/files management function {{{
" Last Update:	03rd jul 2002
"------------------------------------------------------------------------
" Description:	Files Management functions for Vim-Spell to [ia]spell
"------------------------------------------------------------------------
" TODO:		«missing features»
"=============================================================================

function! VS_FileExist(filename) " {{{
  if !filereadable(a:filename)
    echohl ErrorMessage
    echo "Error! " . a:filename . " does not exist!"
    echohl None
    return 0
  endif
  return 1
endfunction " }}}

" call VS_parse_file(expand('%:p')) : need the complete path
function! VS_parse_file(filename) " {{{
  " 1- Retrieve the list of errors
    if !VS_FileExist(a:filename) | return | endif
    let @_=CheckSpellLanguage()
    let spell_options = b:spell_options
    w
    let lst = VS_i_list_errors(a:filename)

  " 2- Check for new errors
    ""let path = substitute(a:filename, '\(.*\)[/\\]\(\\ \|[^/\\]\)*', '\1', '')
    let path = fnamemodify(a:filename,':p:h')
    call VS_CheckNewErrors(path,lst)

  " 3- Build the Syntax for error and the regex search.
    call VS_show_errors()

  " 4- ...
    call VS_Maps_4_file_edited()
endfunction " }}}

"===========================================================================
" 
function! VS_ExitSpell() " {{{
  if &ft != "vsgui" | call VS_g_Open_Corrector() | endif
  bd!
  " clear the mispelled words
  syn clear
  syntax on
  " Restore cmd height {{{
  if exists('g:VS_line_height')
    let &cmdheight=g:VS_line_height
    unlet g:VS_line_height
  endif " }}}
endfunction " }}}

"===========================================================================
" Clear errors
function! VS_show_errors() " {{{
    let @_=CheckSpellLanguage()
    let spell_options = b:spell_options
    " load errors-list
    let elf = VS_f_error_list_file(expand("%:p:h"))
    if strlen(elf)==0 | return | endif
    if !filereadable(elf) | return | endif

    " prepare a temp. file
    let tmp = tempname()
    exe "split ".tmp
    exe ':r '.elf

    "Delete header
    g/^@(#)/d
    """ Delete Ignore words
    ""g/^I .*/d
    " Build the SpellErrors syntax "pattern"
    "exe '%s/^[&*#] \(\S\+\).*$/syntax keyword SpellErrors \1'.spell_options
    exe '%s/^[&*#] \(\S\+\).*$/syntax match SpellErrors "\\<\1\\>"'.spell_options
    wq

    syn case match
    syn match SpellErrors "xxxxx"
    syn clear SpellErrors
    "syn region Misspelling start="\k" end="\W*" contains=SpellErrors transparent
    exe "source ".tmp
    exe "bd! ".tmp
    call delete(tmp)
    "
    let ilf = VS_f_ignore_list_file(expand("%:p:h"))
    if strlen(ilf)!=0 && filereadable(ilf)
      exe "so ".ilf
    endif

    "syn cluster Spell contains=Misspelling,SpellCorrected
    if &ft == "tex"
      syn cluster texCommentGroup	add=SpellErrors,Normal
      syn cluster texMatchGroup		add=SpellErrors,Normal
    endif
    hi link SpellErrors Error

    " cmd line at least 2 ... {{{
    if !exists('g:VS_line_height')
      if &cmdheight < 2
	let g:VS_line_height = &cmdheight
	set cmdheight=2
      endif
    endif " }}}
endfunction " }}}


"===========================================================================
"===========================================================================
" Name of the file listing the errors
" -> <spath>/.spell/errors-list
" Format: by line : the one produced by : echo 'word' | aspell -a

function! VS_f_check_for_VS_path(path)
    let path = fnamemodify(a:path,':p:h')
  let path = fnamemodify(a:path . '/.spell', ':p')
  if !isdirectory(path)
    if filereadable(path)
      echohl ErrorMsg
      echo   "A file is found were a folder is expected : " . path
      echohl None
      return
      ""exit
    endif
    let v:errmsg=""
    echo "Create <".path.">\n"
    if has("unix") 
      call system('mkdir '.path)
    elseif has("win32")
      let path = substitute(path,'/','\\','g')
      call system('md '.path)
    endif
    if strlen(v:errmsg) != 0
      echohl ErrorMsg
      echo   v:errmsg
      echohl None
    endif
  endif
endfunction

function! VS_f_error_list_file(path)
  call VS_f_check_for_VS_path(a:path)
  return a:path . '/.spell/errors-list'
endfunction

function! VS_f_ignore_list_file(path)
  call VS_f_check_for_VS_path(a:path)
  return a:path . '/.spell/ignore-list'
endfunction

function! VS_f_corrector_file(path)
  let path = fnamemodify(a:path . '/.spell', ':p:h')
  return a:path . '/.spell/spell-corrector'
endfunction


"===========================================================================
" Check for New Errors
function! VS_CheckNewErrors(path,errors)
  " 0- File name of the list-errors file
    let elf = VS_f_error_list_file(a:path)

  " 1- Comparaison
  "    i-  If did not exist => add everything
  "    ii- add what is new
  " 1.1- Determine what the new errors are
    if !filereadable(elf) | let new = a:errors
    else                  | let new = VS_f_compare(elf,a:errors)
    endif
  " 1.2- Build their alternatives
    let tmp = VS_f_build_alternatives(new)
  " 1.3- Add them to elf
    call FindOrCreateBuffer(elf,1)	" from a.vim
    exe "$r ".tmp
    g/^$/d
    " Merge the header lignes produced by aspell in only one.
    g/^@(#)/d
    0put=@"
    " Write and quit errors-list
    w! | bd
    " Purge intermediary buffer
    exe "bd ".tmp
    call delete(tmp)
endfunction

"===========================================================================
" Build Alternatives for a list of errors

function! VS_f_build_alternatives(errors)
  return VS_i_get_alternatives(a:errors)
endfunction

"===========================================================================
" Compare new errors to errors-list 
function! VS_f_compare(elf,errors)
    call FindOrCreateBuffer(a:elf,1)	" from a.vim
    let g:err = a:errors
    let new="" | let er=a:errors
    while strlen(er) != 0
      let word = matchstr(er, "[^\n]*")
      ""echo "word  -- " . word . "\n"
      let er   = substitute(er, "[^\n]*\n".'\(.*\)$', '\1', '')
      ""echo "er    -- " . er . "\n"
      let found=0
      exe 'g/^[#*&] \<'.word.'\>/ let found=1'
      if found == 0
	let new = new . "\n" . word
      endif
      ""echo "found -- " . found . "\n"
    endwhile
    bd
    return new
endfunction
"
"===========================================================================
" Functions to manage ignored words
function! VS_f_search(pat)
  if version < 600
    let old_ = v:errmsg
    let v:errmsg=""
    exe '/\/'.a:pat.'\/$'
    let r = strlen(v:errmsg) != 0
    let v:errmsg=old_
    return r
  else
    return search(a:pat) == 0
  endif
endfunction

function! VS_f_add_word_to_ignore_file(word)
    let ilf = VS_f_ignore_list_file(expand("%:p:h"))
    if strlen(ilf)==0 | return | endif

    " Add the pattern to the "ignore" file
    exe "split ".ilf
    if VS_f_search(a:word)
      $put='syn match Normal /'.a:word.'/'
    endif
    w | bd
endfunction

"===========================================================================
" Functions stolen in David Campbell's engspchk.vim
"
  function! VS_SpchkNext()
    ""let errid   = synIDtrans(hlID("Error"))
    let errid = hlID("SpellErrors")
    let lastline= line("$")
    let curcol  = 0

    norm w

    " skip words until we find next error
    ""while synIDtrans(synID(line("."),col("."),1)) != errid
    while synID(line("."),col("."),1) != errid
      norm w
      if line(".") == lastline
        let prvcol=curcol
        let curcol=col(".")
        if curcol == prvcol | break | endif
      endif
    endwhile

    " cleanup
    unlet curcol
    unlet errid
    unlet lastline
    if exists("prvcol") | unlet prvcol | endif
  endfunction

  " -------------------------------------------------------------------
  function! VS_SpchkPrev()
    "let errid = synIDtrans(hlID("Error"))
    let errid = hlID("SpellErrors")
    let curcol= 0

    norm b

    " skip words until we find previous error
    "while synIDtrans(synID(line("."),col("."),1)) != errid
    while synID(line("."),col("."),1) != errid
      norm b
      if line(".") == 1
        let prvcol=curcol
        let curcol=col(".")
        if curcol == prvcol | break | endif
      endif
    endwhile

    " cleanup
    unlet curcol
    unlet errid
    if exists("prvcol") | unlet prvcol | endif
  endfunction

" Part:		lhVimSpell/file management function }}}
"=============================================================================
" Part:		lhVimSpell/corrector buffer functions {{{
" Last Update:	03rd jul 2002
"------------------------------------------------------------------------
" Description:	Syntax and functions for VIM-spell GUI
"------------------------------------------------------------------------
" Note:
" (*) Whenever it is possible, add the single-quote to the keyword thanks
"     to set isk+='
"     Could be done with non harm with LaTeX, mail, and other text formats
" TODO:		«missing features»
"=============================================================================

" {{{
function! VS_g_EchoMsg(text)
  echohl ErrorMsg
  echo a:text
  echohl None
endfunction
command -nargs=1 VSgEchoMsg :call VS_g_EchoMsg(<args>)
" }}}
"===========================================================================
" Syntax
"===========================================================================
function! VS_g_AltSyntax() " {{{
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
endfunction " }}}

"===========================================================================
" Functions
"===========================================================================
function! VS_g_Open_Corrector() " {{{
  " open the corrector gui (split window)
  let gui = VS_f_corrector_file(expand('%:p:h'))
  call FindOrCreateBuffer(gui,1)	" from a.vim
endfunction " }}}
"
function! VS_g_Launch_Corrector() " {{{
  " Means that the current window is not the Corrector window.
  let word     = expand("<cword>")
  let filename = expand("%")
  let W1       = winnr()
  ""let lang     = g:VS_language

  call VS_g_Open_Corrector()

  " transfert variables
  ""let b:word	 = word
  let b:filename    = filename
  let b:mainfile    = filename
  let b:W1	    = W1
  let b:W2	    = winnr()
  ""let g:VS_language = lang

  " Make the gui the current word
  call VS_g_AltSyntax()
  call VS_g_Make(word)
endfunction " }}}

function! VS_g_Make(word) " {{{
  " 0- Purge
  v//d
  " 1- Find word in errors-list
  let elf = VS_f_error_list_file(fnamemodify(b:filename,':p:h'))
  if strlen(elf)==0 | return | endif
  exe ':r '.elf
  :2
  normal "zyy
  exe 'v/& '.a:word.'\s\+/d'
  normal "zP
  if line('$') == 1
    echohl WarningMsg
    echo   "Word <".a:word."> correct or not yet processed..."
    echohl None
    ""let alter = system('echo "' .a:word . '" \| '. CS . ' -a')
    ""0put = alter
    ""bd!
    return
  endif
  "
  let b:word = a:word
  " 2- Convert the list
  " 2.b- The help string
  if strlen(b:word) == 0
    ""v//d
    g/^[@#&]/d
    g/^$/d
    normal "zP
  endif
  let NbL = VS_g_help_NbL()
  1put = VS_g_help()
  if strlen(a:word) == 0
    normal Gdd
    put ='-> No word selected'
    put =''
    put ='  --abort--'
    return
  endif

  exe NbL."put = ''"
  put = '  --abort--'

  let NbL = NbL + 3
  " 2.a- The suggested alternatives
  let test = 0
  g/^& .* \d\+ \d\+:/ let test = 1
  if test == 1
    call VS_g_mk_Alternatives(NbL)
  endif

  " 2.b- Just an error
  let test = 0
  g/^# .* \d\+/ let test = 1
  if test == 1
    call VS_g_mk_NoAlternative()
  endif

  " 2.c- Correct words
  let test = 0
  g/^\*/ let test = 1
  if test == 1
    s/^\*/-- Correct word/
    " Move up the line 
    normal "zdd
    /--abort/
    normal k"zP
    " TODO: must ask for sound-like words
  endif

  if line('$') == NbL
    exe (NbL-3)."put = '-> <".a:word."> is present in the dictionary'"
  endif

  ""call SpellAltMaps()
  exe ':'.(NbL+1)
  echo "\rCorrection mode activated..."
endfunction " }}}

function! VS_g_mk_Alternatives(NbL) " {{{
  " Number the entries
  s/[:,]/\r##\t/g
  %g/##/exe "normal cw\<tab>".(line('.')-a:NbL)."\<esc>"
  " Number of entries
  :g/^&.\D\+/ exe "normal WWyw" | exe 'let NbAlt='.@"
  :s/& \(.\{-}\) \(\d\+\) \d\+$/-- \2 alternatives to "\1"/
  " Move up the line 
  normal "zdd
  /--abort/
  normal k"zP
endfunction " }}}

function! VS_g_mk_NoAlternative() " {{{
  " Number the entries
  :s/^#\s*\(\S\+\).*$/-- No alternative to "\1"/
  normal "zdd
  /--abort/
  normal k"zP
endfunction " }}}


"===========================================================================
"===========================================================================
" Choose from a number {{{
"

" Does not work well ...
command! -nargs=1 VSChooseWord :call VS_g_ChooseWord(<q-args>)

function! VS_g_ChooseWord(nb)
  let nb = a:nb+3+VS_g_help_NbL()
  if a:nb < 0 || nb>line('$')
    echohl ErrorMsg
    echo "\rInvalid number, no alternative word corresponding"
    echohl None
  elseif nb == 0
    bd!
    echo "\rAbort"
  else
    exe ":".nb
    exe "normal \<cr>"
  endif
endfunction " }}}

"===========================================================================
" Choose from gui -- <cr> or <2-leftclick>

function! SA_GetAlternative(line) " {{{
  let NbL = VS_g_help_NbL()+3
  if (a:line == NbL) || (a:line == -1)
    return ""
  elseif a:line > NbL
    return substitute(getline(a:line), '^.*\s\+', '', '')
  else
    return -1
  endif
endfunction " }}}

function! SA_return(line) " {{{
  let alt = SA_GetAlternative(a:line)
  if (strlen(alt) != 0) 
    if (alt != -1)
      ""let b_ID = bufnr('%')
      let W_ID = b:W1+1
      let word = b:word
      "swap windows
      let this = expand('%:p')
      call FindOrCreateBuffer(b:mainfile,1)
      ""exe "normal ".W_ID."\<c-W>x"
      if expand("<cword>") != word
	echohl WarningMsg
	echo "\r<".word."> lost! Use <M-n> to get to next occurrence\n"
	echohl None
      else
	" Use a temporary mapping to change the word without enabling
	" embedded mappings to expand.
	"exe "normal viwc" . alt . "\<esc>"
	exe "nnoremap =}= viwc".alt."\<esc>"
	exe "normal =}="
	unmap =}=
	""exe "normal 0/".word."\<cr>"
	""exe "normal c/".word."/e\<cr>".alt. "\<esc>"
      endif
      "swap windows
      call FindOrCreateBuffer(this,1)
      VSgEchoMsg '<'.word.'> has been replaced with <'.alt.'>'
      VSgNextError
      ""exe "normal ".W_ID."\<c-W>x"
      ""exe ' b'.b_ID
    endif
  else
    bd!
    echo "\rAbort"
  endif
endfunction " }}}

function! SA_all(line) " {{{
  let alt = SA_GetAlternative(a:line)
  if (strlen(alt) != 0) 
    if (alt != -1)
      let b_ID = bufnr('%')
      ""let W_ID = b:W1+1
      let word = b:word
      "swap windows
      ""exe "normal ".W_ID."\<c-W>x"
      exe 'b '.b:mainfile
      exe '%s/'.word.'/'. alt.'/g' 
      normal "\<c-v>\<c-l>"
      "swap windows
      ""exe "normal ".W_ID."\<c-W>x"
      exe ' b'.b_ID
      VSgEchoMsg 'Every occurences of <'.word.'> have been replaced with <'.alt.'>'
      VSgNextError
    endif
  endif
endfunction " }}}

function! SA_all_buffers(line) " {{{
  let alt = SA_GetAlternative(a:line)
  if (strlen(alt) != 0) 
    if (alt != -1)
      let word = b:word
      let b_ID = bufnr('%')
      let b_last = bufnr('$')
      let i = 1
      while i != b_last
	if i != b_Id
	  exe 'b '.i
	  exe '%s/'.word.'/'. alt.'/g' 
	endif
	let i = i + 1
      endwhile
      " reload the good buffer
      exe ' b'.b_ID
      VSgEchoMsg 'Every occurences of <'.word.'> have been replaced with <'
	    \ .alt.'> in every buffer'
      VSgNextError
    endif
  endif
endfunction " }}}


"===========================================================================
" Move to choice {{{
function! VS_g_NextChoice(isForward)
  if a:isForward == 1
    /^\s*\d\+\s\+/
  else
    ?^\s*\d\+\s\+?
  endif
endfunction
" }}}

"===========================================================================
" Move to errors {{{
function! VS_g_NextError()
  let this = expand('%:p')
  call FindOrCreateBuffer(b:mainfile,1)
  call VS_SpchkNext()
  let word = expand("<cword>")
  call FindOrCreateBuffer(this,1)
  call VS_g_Make(word)
endfunction

function! VS_g_PrevError()
  let this = expand('%:p')
  call FindOrCreateBuffer(b:mainfile,1)
  call VS_SpchkPrev()
  let word = expand("<cword>")
  call FindOrCreateBuffer(this,1)
  call VS_g_Make(word)
endfunction

command -nargs=0 VSgNextError 
      \ :if g:VS_jump_next_error_after | call VS_g_NextError() | endif

" }}}
"===========================================================================
" Undo {{{
function! VS_g_UndoCorrection(isUndo)
  let this = expand('%:p')
  call FindOrCreateBuffer(b:mainfile,1)
  if a:isUndo == 1 | undo
  else             | redo
  endif
  let word = expand("<cword>")
  call FindOrCreateBuffer(this,1)
endfunction
" }}}
"===========================================================================
" Add words to the dictionary & Ignore words {{{
"===========================================================================
"
function! VS_g_AddWord(lowCase)
  let word=b:word
  " 1- Request to the spell checker
  call VS_i_add_word_to_dict(b:word,a:lowCase)
  " 2- Update the cached files
  let elf = VS_f_error_list_file(fnamemodify(b:filename,':p:h'))
  if strlen(elf)==0 | return | endif
  exe "split ".elf
  exe 'g/^[&#*]\s*'.word.'\s*/d'
  w | bd
  call VS_g_ReShowErrors()
  VSgEchoMsg '<'.word.'> has been added to the personal dictionary'
  VSgNextError
endfunction

function! VS_g_IgnoreWord()
  let this = expand('%:p')
  let word = b:word
  call FindOrCreateBuffer(b:mainfile,1)
  exe 'syn match Normal /'.word.'/'
  call VS_f_add_word_to_ignore_file(word)
  call FindOrCreateBuffer(this,1)
  VSgEchoMsg '<'.word.'> will be ignored for the files in this directory'
  VSgNextError
endfunction

function! VS_g_ReShowErrors()
  let this = expand('%:p')
  call FindOrCreateBuffer(b:mainfile,1)
  call VS_show_errors()
  call FindOrCreateBuffer(this,1)
endfunction
" }}}
"===========================================================================
" Load the maps {{{
"===========================================================================
"
" Planned to be used through buffoptions2.vim
" Rem: name of the file type must be simple ; for instance VS_gui does not
" fit, but vsgui does.
"
" Could and must be converted to vim6 -- alternative

if version >= 600
  source <sfile>:p:h/VS_gui-map.vim
  aug VS_g_Alternative_AU
    au!
    au BufNewFile,BufRead spell-corrector* set ft=vsgui
  aug END
  au Syntax vsgui call VS_g_AltMaps_v6()
elseif exists("g:BuffOptions2Loaded")
  let ff = expand('<sfile>:p:h'). '/VS_gui-map.vim'
  aug VS_g_Alternative_AU
    au!
    au BufNewFile,BufRead spell-corrector* set ft=vsgui
  aug END
  au Syntax vsgui call ReadFileTypeMap( "vsgui", ff) | call VS_g_AltMaps()
else
  source <sfile>:p:h/VS_gui-map.vim
  aug VS_g_Alternative_AU
    au!
    au BufEnter spell-corrector* call VS_g_AltMaps()
    au BufLeave spell-corrector* call VS_g_AltUnMaps()
  aug END
endif
" }}}

" Part:		lhVimSpell/corrector buffer functions }}}
"=============================================================================
"
"------------------------------------------------------------------------
" end of avoid reinclusion
endif
"=============================================================================
" vim600: set fdm=marker:
