" -*- VIM -*-
" File Management functions for Vim-Spell to [ia]spell
"
" File:		VS_fm-fun.vim
" Author:	Luc Hermitte <EMAIL:hermitte@free.fr>
" 		<URL:http://hermitte.free.fr/vim>
" Ver:		0.1d
" Last Update:	08th nov 2001
"
"===========================================================================
"


function! VS_FileExist(filename)
  if !filereadable(a:filename)
    echohl ErrorMessage
    echo "Error! " . a:filename . " does not exist!"
    echohl None
    return 0
  endif
  return 1
endfunction

" call VS_parse_file(expand('%:p')) : need the complete path
function! VS_parse_file(filename)
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
endfunction

"===========================================================================
" 
function! VS_ExitSpell()
  if &ft != "vsgui"
    call VS_g_Open_Corrector()
  endif
  bd!
  " clear the mispelled words
  syn clear
  syntax on
endfunction

"===========================================================================
" Clear errors
function! VS_show_errors()
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
    "syn cluster Spell contains=Misspelling,SpellCorrected
    if &ft == "tex"
      syn cluster texCommentGroup	add=SpellCorrected,SpellErrors
      syn cluster texMatchGroup		add=SpellCorrected,SpellErrors
    endif
    hi link SpellErrors Error
endfunction


"===========================================================================
"===========================================================================
" Name of the file listing the errors
" -> <spath>/.spell/errors-list
" Format: by line : the one produced by : echo 'word' | aspell -a

function! VS_f_error_list_file(path)
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
  return a:path . '/.spell/errors-list'
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
    let new = ""
    if !filereadable(elf) 
      let new = a:errors
    else
      let new = VS_f_compare(elf,a:errors)
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
  let g:toto = VS_i_get_alternatives(a:errors)
  return g:toto
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
" Functions stolen in DavidCampbell's engspchk.vim
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
        if curcol == prvcol
          break
        endif
      endif
    endwhile

    " cleanup
    unlet curcol
    unlet errid
    unlet lastline
    if exists("prvcol")
      unlet prvcol
    endif
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
        if curcol == prvcol
          break
        endif
      endif
    endwhile

    " cleanup
    unlet curcol
    unlet errid
    if exists("prvcol")
      unlet prvcol
    endif
  endfunction
