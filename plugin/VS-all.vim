" -*- VIM -*-
" Loads the different components of VIm-Spell.
"
" File:		VS-all.vim
" Author:	Luc Hermitte <EMAIL:hermitte@free.fr>
" 		<URL:http://hermitte.free.fr/vim>
" Ver:		0.2b
" Last Update:	31st jan 2002
"
"===========================================================================
"
" PURPOSE:
" ---------
" VS-all.vim is intended to be used only if you don't want VIm-Spell to be
" loaded systematically. 
"
" My approach is to consider it as a bunch of macros to load if the
" filetype of the current document suit spellchecking -- like TeX, HTML,
" etc.
"
"
" OPTION 1: load on request only
" -------------------------------
" In this case, be sure that all the files from this plugin are in
" $VIM(RUNTIME)/macros for instance (or $VIM/macros/vim-spell), and source
" this file from your ftplugins. It will then load all the components from
" this "plugin".
"
"
" OPTION 2: always load
" ----------------------
" If you'd rather load VIm-Spell systematically, you could commentify the
" lines of this file, rename it, erase it or whatever you want. And be sure
" the other files are in $VIM(RUNTIME)/plugin.
"
" Another option : extract the plugin into $VIM/plugin/vim-spell, move this
" file to $VIM/plugin, and change the path to the other files of the plugin
" -> :%s,:p:h:,\0/vim-spell,
"
"  ======================================================================

" First : load the different scripts composing the VIm-Spell plugin
  source <sfile>:p:h/VS_deps.vim
  source <sfile>:p:h/VS_int-fun.vim
  source <sfile>:p:h/VS_fm-fun.vim
  source <sfile>:p:h/VS_gui.vim
  source <sfile>:p:h/VS_map.vim


" Then, request some other plugins not sytematically loaded  
" It is highly probable you will delete this line if you have put this file
" into your $VIM/plugin folder.
  ""source $VIM/macros/a.vim
