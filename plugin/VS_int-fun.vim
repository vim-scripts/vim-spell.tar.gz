" -*- VIM -*-
" Interface functions for Vim-Spell to [ia]spell
"
" File:		VS_int-fun.vim
" Author:	Luc Hermitte <EMAIL:hermitte@free.fr>
" 		<URL:http://hermitte.free.fr/vim>
" Ver:		0.2
" Last Update:	27th jan 2002
"
" Inspiration:	VIMspell.vim by Claudio Fleiner <claudio@fleiner.com>
"
"===========================================================================
"

"===========================================================================
" Options
"
function! VS_set_if_null(var, value)
  if (!exists(a:var)) 
    exe "let ".a:var." = a:value"
  endif
endfunction

call VS_set_if_null("g:VS_language", 'francais')
call VS_set_if_null("g:VS_stripaccents", 0)
call VS_set_if_null("g:VS_spell_prog", 'aspell')
call VS_set_if_null("g:VS_aspell_add_directly_to_dict", 0)
"let g:VS_language='francais'
"let g:VS_stripaccents=0
"let g:VS_spell_prog = 'aspell'

:function! CheckSpellLanguage() 
:  if !exists("b:spell_options") 
:    let b:spell_options=""
:  endif
:endfunction

" Function to compute the name of the personal dictionary for ASPELL
" You may have to customize it to your own needs.
function! VS_personal_dict()
  if     g:VS_language == "francais" | return expand("$ASPELL/fr.pws")
  elseif g:VS_language == "english"  | return expand("$ASPELL/english.pws")
  elseif g:VS_language == "american"  | return expand("$ASPELL/english.pws")
  else
    return expand("$ASPELL/").g:VS_language.".pws"
  endif
endfunction

"===========================================================================
" Programs calls
function! VS_i_Call_Spell_type(type,...)
  if a:type == "tex"
    let mode = ' --mode='. a:type 
  elseif a:type =~'htm\|xml\|php\|incl'
    let mode = ' --mode=sgml'
  else
    let mode = ''
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
  if exists("g:VS_stripaccents") && g:VS_stripaccents == 1
    let cmd = cmd . " --strip-accents "
  endif
  
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
  exe "normal $\<c-a>"
  " 2.c/ Add the word to the last line
  $put=a:word
  " 2.d/ chage it to lower case if required
  if a:lowcase == 1
    normal guu
  endif
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
    if a:lowcase == 1 | let cmd = "&" | else | let cmd = "*" 
    endif
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
