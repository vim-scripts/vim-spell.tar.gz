#
# Makefile for the Vim-Spell documentation 
# Last update: 08th nov 2001
#

# include the config.mk from the source directory.  It's only needed to set
# AWK, used for "make html".  Comment this out if the include gives problems.
#include ../../src/config.mk
AWK = gawk

FILES = \
	VS_help

DOCS  = $(FILES:%=%.txt)
HTMLS = $(FILES:%=%.html)

.SUFFIXES:
.SUFFIXES: .c .o .txt .html

all: tags html tarball

tags: $(DOCS)
	@echo -n "Build tags ."
	@doctags $(DOCS) | sort >tags
	@uniq -d -2 tags
	@echo ". OK"

# Awk version of .txt to .html conversion.
html: msg_html noerrors tags tags.ref $(HTMLS) Arch_footer
	@if test -f errors.log; then less errors.log; fi

noerrors:
	@echo "+ Delete [errors.log]"
	@-rm -f errors.log

msg_html:
	@echo
	@echo "==============================================================="
	@echo "= Build HTML help files ..."
	@echo "==============================================================="

VS_help.html:VS_help.txt	
	@echo -n "+ Build [$@] ."
	@$(AWK) -f makehtml2.awk -v ALONE=1 -v TITLE="Vim-Spell documentation" $< >$@
	@echo ". OK"

.txt.html:
	@echo -n "+ Build [$@] ."
	@$(AWK) -f makehtml2.awk $< >$@
	@echo ". OK"

tags.ref tags.html: tags
	@$(AWK) -f maketags.awk tags >tags.html

# Perl version of .txt to .html conversion.
# There can't be two rules to produce a .html from a .txt file.
# Just run over all .txt files each time one changes.  It's fast anyway.
perlhtml: tags $(DOCS)
	./vim2html.pl tags $(DOCS)

clean:
	-rm *.html tags.ref

# ===========================================================================
# ===========================================================================
MODULES   = vim-spell
MAIN_DIR  = vim-spell
BACKUPDIR = ..
BACKUPS   = $(MODULES:%=$(BACKUPDIR)/%.tar.gz)	

tarball: Arch_header $(BACKUPS) Arch_footer 
#tarall: Arch_header $(BACKUPS) ../hlp/zip/$(MODULE).gz Arch_footer 

VS_FILES  = VS_int-fun.vim VS_map.vim				\
	    VS-all.vim VS_fm-fun.vim VS_gui-map.vim VS_gui.vim	\
	    VS_help.html VS_help.txt tags			\
	    Makefile makehtml2.awk maketags.awk ChangeLog
VS_FILES_DIR = $(VS_FILES:%=$(MAIN_DIR)/%)

Arch_header: 
	@echo
	@echo "==============================================================="
	@echo "= Archiving...                                                ="
	@echo "==============================================================="

Arch_footer:
	@echo "+--"
	@echo "| Done !"
	@echo "==============================================================="
	@echo 

$(BACKUPDIR)/vim-spell.tar.gz: $(VS_FILES)
	@echo -n "+ Archiving vim-spell plugin [$@] ."
	@cd .. ; tar -ch $(VS_FILES_DIR) | gzip -c > toto.tar.gz
	@rm  $@
	@mv ../toto.tar.gz $@ 
	@echo ". OK"
