" -*- VIM -*-
" Syntax and functions for VIM-spell GUI
"
" File:		VS_gui.vim	
" Author:	Luc Hermitte <EMAIL:hermitte@free.fr>
" 		<URL:http://hermitte.free.fr/vim>
" Ver:		0.2c
" Last Update:	25th feb 2002
"
" Note:
" (*) Whenever it is possible, add the single-quote to the keyword thanks
"     to set isk+='
"     Could be done with non harm with LaTeX, mail, and other text formats
"===========================================================================
"

"===========================================================================
" Syntax
"===========================================================================
function! VS_g_AltSyntax()
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

"===========================================================================
" Functions
"===========================================================================
function! VS_g_Open_Corrector()
  " open the corrector gui (split window)
  let gui = VS_f_corrector_file(expand('%:p:h'))
  call FindOrCreateBuffer(gui,1)	" from a.vim
endfunction
"
function! VS_g_Launch_Corrector()
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
endfunction


function! VS_g_Make(word)
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
endfunction

function! VS_g_mk_Alternatives(NbL)
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
endfunction

function! VS_g_mk_NoAlternative()
    " Number the entries
    :s/^#\s*\(\S\+\).*$/-- No alternative to "\1"/
    normal "zdd
    /--abort/
    normal k"zP
endfunction


"===========================================================================
"===========================================================================
" Choose from a number
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
endfunction

"===========================================================================
" Choose from gui -- <cr> or <2-leftclick>

function! SA_GetAlternative(line)
  let NbL = VS_g_help_NbL()+3
  if (a:line == NbL) || (a:line == -1)
    return ""
  elseif a:line > NbL
    return substitute(getline(a:line), '^.*\s\+', '', '')
  else
    return -1
  endif
endfunction

function! SA_return(line)
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
      ""exe "normal ".W_ID."\<c-W>x"
      ""exe ' b'.b_ID
    endif
  else
    bd!
    echo "\rAbort"
  endif
endfunction

function! SA_all(line)
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
    endif
  endif
endfunction

function! SA_all_buffers(line)
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
    endif
  endif
endfunction


"===========================================================================
" Move to choice
function! VS_g_NextChoice(isForward)
  if a:isForward == 1
    /^\s*\d\+\s\+/
  else
    ?^\s*\d\+\s\+?
  endif
endfunction

"===========================================================================
" Move to errors
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

"===========================================================================
" Undo
function! VS_g_UndoCorrection(isUndo)
  let this = expand('%:p')
  call FindOrCreateBuffer(b:mainfile,1)
  if a:isUndo == 1
    undo
  else
    redo
  endif
  let word = expand("<cword>")
  call FindOrCreateBuffer(this,1)
endfunction

"===========================================================================
" Add words to the dictionary & Ignore words
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
endfunction

function! VS_g_IgnoreWord()
  let this = expand('%:p')
  let word = b:word
  call FindOrCreateBuffer(b:mainfile,1)
  exe 'syn match Normal /'.word.'/'
  call VS_f_add_word_to_ignore_file(word)
  call FindOrCreateBuffer(this,1)
endfunction

function! VS_g_ReShowErrors()
  let this = expand('%:p')
  call FindOrCreateBuffer(b:mainfile,1)
  call VS_show_errors()
  call FindOrCreateBuffer(this,1)
endfunction

"===========================================================================
" Load the maps
"===========================================================================
"
" Planned to be used through buffoptions2.vim
" Rem: name of the file type must be simple ; for instance VS_gui does not
" fit, but vsgui doed.
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
    aug VS_g_Alternative_AU
	au!
	au BufEnter spell-corrector* call VS_g_AltMaps()
	au BufLeave spell-corrector* call VS_g_AltUnMaps()
    aug END
    source <sfile>:p:h/VS_gui-map.vim
endif


