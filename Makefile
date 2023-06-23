

# -*- Makefile -*-
# Makefile -- A generic script for building, signing, installing, and uninstalling Genshiken
# Copyright © 2015-2016 Michael Pagan
#
# Author: Michael Pagan
# E-Mail: michael.pagan@member.fsf.org
# Jabber: pegzmasta@member.fsf.org
#
# This file is part of Genshiken.
#
# Genshiken is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Genshiken is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Genshiken. If not, see http://www.gnu.org/licenses/.
ADMIN=pegzmasta
AUTHOR="Michael Pagan"
NAME=genshiken
PROJ=Genshiken
VERSION=0.5.2
HOMEPAGE=http://www.nongnu.org/$(NAME)

SAVANNAH=savannah.nongnu.org
SOURCES=cvs.$(SAVANNAH):/sources
WEB=cvs.$(SAVANNAH):/web
RELEASES=dl.sv.nongnu.org
FEED=https://$(SAVANNAH)/news/atom.php?group=$(NAME)
LATEST_VERSION=$(shell lynx -source $(FEED) | sed -n "1,/<title>Announcing $(PROJ)/ s/.*[ ]\([0-9]\.[0-9].*\)<.*/\1/p")
LATEST_TARBALL=http://download-mirror.$(SAVANNAH)/releases/$(NAME)/$(NAME)-$(LATEST_VERSION).tar.gz
GPL=http://www.gnu.org/licenses/gpl.txt
FDL=http://www.gnu.org/licenses/fdl.txt

PREFIX         ?= /usr/local
CVSROOT        := $(shell echo $${CVSROOT:-$${PWD}/..})
BASH_COMP      := $(shell echo $$BASH_COMPLETION_COMPAT_DIR | grep $(PREFIX)/etc/bash_completion.d/)
SUDO_USER      := $(shell echo ~ | gawk -F/ '{ print $$3 }')
COPYRIGHT_CMD  := "sed -n '/\*.*etc$$/,$$ p' TODO"

DIRS=etc lib bin sbin share
INSTALL_DIRS  := `find $(DIRS) -type d 2> /dev/null`
INSTALL_FILES := `find $(DIRS) -type f 2> /dev/null`

PKG_NAME=$(NAME)-$(VERSION)
PKG_DIR=$(CVSROOT)/$(NAME)
PKG=$(CVSROOT)/$(PKG_NAME).tar.gz
SIG=$(PKG).sig

checkout-soft:
        export CVS_RSH=ssh
        cvs -z3 -d:ext:$(ADMIN)@$(SOURCES)/$(NAME) co -P $(NAME)

checkout-web:
        export CVS_RSH=ssh
        cvs -z3 -d:ext:$(ADMIN)@$(WEB)/$(NAME) co -P $(NAME)

endprog: $(PKG_DIR)/ChangeLog
        cp $(shell find . -maxdepth 1 -name '[ACMNTn]*' -type f -print | sed 's_./__') $(CVSROOT)
        cp $(PKG_DIR)/share/doc/$(NAME)/HACKING $(CVSROOT)
        cp $(PKG_DIR)/share/doc/$(NAME)/readme.org $(CVSROOT)
        cp $(PKG_DIR)/share/doc/$(NAME)/manual.org $(CVSROOT)
        rm $(CVSROOT)/COPYING*
        if [ -d $(PKG_DIR)/share/icons/hicolor/128x128/apps ]; then cp $(PKG_DIR)/share/icons/hicolor/128x128/apps/*png $(CVSROOT); fi
        if [ -d $(PKG_DIR)/share/icons/hicolor/512x512/apps ]; then cp $(PKG_DIR)/share/icons/hicolor/512x512/apps/*png $(CVSROOT); fi
        if [ -f $(PKG_DIR)/share/man/man1/$(NAME).1 ]; then cp $(PKG_DIR)/share/man/man1/$(NAME).1 $(CVSROOT); fi
        if [ -d $(PKG_DIR) ]; then cvs release -d $(PKG_DIR); fi

# Fontifying Org files and top-level scripts with html, so that they can be viewed in their original form online
fontify:
        sed -i 's/#+STARTUP:  content/#+STARTUP:  showeverything/' NEWS
        sed -i 's/#+STARTUP:  showall/#+STARTUP:  showeverything/' readme.org
        sed -i 's/#+STARTUP:  overview/#+STARTUP:  showeverything/' HACKING
        emacs --eval "(htmlize-file \"readme.org\")" --eval "(htmlize-file \"HACKING\")" --eval "(htmlize-file \"NEWS\")" --eval "(htmlize-file \"TODO\")" --eval "(htmlize-file \"Makefile\")" --eval "(htmlize-file \"ChangeLog\")" --eval "(htmlize-file \"manual.org\")" --eval "(htmlize-file \"news-maker.sh\")" -f save-buffers-kill-terminal
        rename 's/\.html$$/\.org.html/' *.html
        mv manual.org.org.html manual.org.html
        mv readme.*html index.org.html
        mv MANIFEST.org.html MANIFEST.html

htmlize:
        # `img' dir is where all my PNG/SVG icons will be stored in the web repository
        sed -i 's_\[\[file:.*/icons.*using-$(NAME)-big.png\]\]_\[\[file:img/using-$(NAME)-big.png\]\]_' readme.org
        sed -i 's_\[\[file:.*/icons.*sos-gear.png\]\]_\[\[file:img/sos-gear.png\]\]_' readme.org
        sed -i 's_\[\[file:.*/icons.*\]\]_\[\[file:img/sos-gear.png\]\]_' HACKING
        # Org radio targets can't be followed in HTML.  Remove them while preserving the original text
        sed -i -e 's/\([^<]\)mailing-list\([^>]\)/\1mailing list\2/g' -e 's/<*\(mailing\)-\(list\)>*/\1 \2/' HACKING
        sed -i -e 's/<*\(project member\)>*/\1/' HACKING
        sed -i -e 's/<*\(the main purpose\)>*/\1/' HACKING
        # These text-search targets no longer work with html info nodes (only single-page html)
        sed -i 's/\[\[#savannah\]\[\([A-Za-z ]*\)\]\]/+\1+/g' HACKING
        sed -i 's/\[\[#free-software\]\[\([A-Za-z ]*\)\]\]/+\1+/g' HACKING
        sed -i "s/\[\[Get access to the $(PROJ) Repository\]\[\([A-Za-z ]*\)\]\]/+\1+/g" HACKING
        # Removing external links to Genshiken's source code, while keeping the references
        sed -i 's/\[\[%[^ ]*\]\[\([A-Za-z ]*\)\]\]/+\1+/g' HACKING
        sed -i 's/\[\[%[^ ]*\]\[\([a-z ]*.\-[^ ]*\)\]\]/+\1+/g' HACKING
        # Removing License Notice for website
        sed -i '/\* License Notice/,$$ d' HACKING
        sed -i "/This file is part of \*$(PROJ)\*./ d" readme.org
        # Renaming to `.html' extension, with section numbers added
        sed -i 's/file:COPYING/GPL/' readme.org
        sed -i 's/file:manual.org/file:manual.org.html/' readme.org
        sed -i 's/=manual.html=/\[\[file:manual.html\]\[manual.html\]\]/' readme.org
        sed -i 's/gpl.txt/gpl.html/' readme.org
        sed -i 's/file:COPYING.manual/FDL/' HACKING
        sed -i 's/fdl.txt/fdl.html/' HACKING
        sed -i 's/\[free-software\]/\[file:what-is-fs-new.pdf\]/' HACKING
        sed -i 's/file:readme.org/file:index.html/' HACKING
        sed -i 's|file:index.html::Contact Information|$(HOMEPAGE)/$(NAME)/#orgheadline30|' HACKING
        sed -i 's|file:index.html::License Notice|$(HOMEPAGE)/$(NAME)/#orgheadline33|' HACKING
        sed -i 's/file:HACKING/file:HACKING.html/' readme.org
        sed -i 's|file:HACKING.html::the%20main%20purpose|$(HOMEPAGE)/$(NAME)/HACKING.html#orgheadline3|' readme.org
        sed -i 's/file:ChangeLog/file:ChangeLog.org.html/' HACKING
        sed -i 's/file:ChangeLog/file:ChangeLog.org.html/' readme.org
        sed -i 's/file:Makefile/file:Makefile.org.html/g' HACKING
        sed -i 's/file:Makefile/file:Makefile.org.html/g' readme.org
        sed -i 's/=MANIFEST.html=/\[\[file:MANIFEST.html\]\[the MANIFEST\]\]/' readme.org
        sed -i 's/file:NEWS/file:NEWS.html/g' HACKING
        sed -i 's/file:NEWS/file:NEWS.html/g' readme.org
        sed -i 's/file:TODO/file:TODO.html/g' HACKING
        sed -i 's/file:news-maker.sh/file:news-maker.sh.org.html/g' HACKING
        # Converting local documentation links to refer to the online documentation, instead
        sed -i 's|man:man|http://man.he.net/?topic=man\&section=all|g' HACKING
        sed -i 's|man:bash|http://man.he.net/?topic=bash\&section=all|g' HACKING
        sed -i 's|man:gawk|http://man.he.net/?topic=gawk\&section=all|g' HACKING
        sed -i 's|man:cvs2cl|http://man.cx/cvs2cl%281%29|' HACKING
        sed -i 's/man:$(NAME)/file:manual.html/g' HACKING
        sed -i 's|info:sed|https://www.gnu.org/software/sed/manual/html_node/index.html|' HACKING
        sed -i 's|info:cvs|https://web.archive.org/web/20140209043007/http://ximbiot.com/cvs/manual/cvs-1.12.13/cvs.html|' HACKING
        sed -i 's|info:grep|https://www.gnu.org/software/grep/manual/html_node/index.html|' HACKING
        sed -i 's|info:coreutils|https://www.gnu.org/software/coreutils/manual/html_node/index.html|' HACKING
        sed -i -e 's|info:standards|https://www.gnu.org/prep/standards/html_node/|g' -e 's|\(html_node/\)#\([^ ]*\)\(\]\[\)|\1\2#\2\3|g' -e '/standards/ { s/\([A-Za-z]\)-\([A-Za-z]\)/\1_002d\2/g }' -e '/standards/ { s/%20/-/g }' HACKING
        sed -i -e 's|info:maintain|https://www.gnu.org/prep/maintain/html_node/|g' -e 's|\(html_node/\)#\([^ ]*\)\(\]\[\)|\1\2#\2\3|g' -e '/maintain/ { s/\([A-Za-z]\)-\([A-Za-z]\)/\1_002d\2/g }' -e '/maintain/ { s/%20/-/g }' HACKING
        sed -i -e 's|info:org|http://orgmode.org/manual/index.html|' -e 's|\(manual/\)index\(.html\)#\([^ ]*\)\(\]\[\)|\1\3\2#\3\4|g' -e '/orgmode.org.manual/ { s/\([A-Za-z]\)-\([A-Za-z]\)/\1_002d\2/g }' -e '/orgmode.org.manual/ { s/%20/-/g }' HACKING
        sed -i 's|(\(https://www.gnu.org/prep/standards/html_node/\) |(\[\[\1\]\[standards\]\] |' HACKING
        sed -i 's| \(https://www.gnu.org/prep/maintain/html_node/\))| \[\[\1\]\[maintain\]\])|' HACKING
        # Converting Org files to html
        emacs --eval "(kill-this-buffer)" --visit readme.org HACKING NEWS TODO manual.org --eval "(switch-to-buffer \"readme.org\")" --eval "(org-html-export-to-html)" --eval "(switch-to-buffer \"HACKING\")" --eval "(org-html-export-to-html)" --eval "(switch-to-buffer \"NEWS\")" --eval "(org-html-export-to-html)" --eval "(switch-to-buffer \"TODO\")" --eval "(org-html-export-to-html)" --eval "(switch-to-buffer \"manual.org\")" --eval "(org-html-export-to-html)" -f save-buffers-kill-terminal
        # Adding JavaScript for the "Show Org source" button
        sed -i '/CDATA/,$$ { /function CodeHighlightOn/ s|.*| function rpl(expr,a,b)\n \{\n   var i=0\n   while (i!=-1)\n   \{\n      i=expr.indexOf(a,i);\n      if (i>=0)\n      \{\n         expr=expr.substring(0,i)+b+expr.substring(i+a.length);\n         i+=b.length;\n      \}\n   \}\n   return expr\n \}\n function show_org_source()\n \{\n   document.location.href = rpl(document.location.href,"html","org.html");\n \}\n&| }' NEWS.html
        sed -i '/CDATA/,$$ { /function CodeHighlightOn/ s|.*| function rpl(expr,a,b)\n \{\n   var i=0\n   while (i!=-1)\n   \{\n      i=expr.indexOf(a,i);\n      if (i>=0)\n      \{\n         expr=expr.substring(0,i)+b+expr.substring(i+a.length);\n         i+=b.length;\n      \}\n   \}\n   return expr\n \}\n function show_org_source()\n \{\n   document.location.href = rpl(document.location.href,"html","org.html");\n \}\n&| }' TODO.html
        # Converting Genshiken man page to html
        groffer --local-file $(NAME).1 --html --html-viewer='lynx -source' > manual.html
        # Creating homepage
        mv readme.*html index.html
        # Moving files to local web repository
        mv *.html $(PKG_DIR)
        mv AUTHORS $(PKG_DIR)
        mv Makefile $(PKG_DIR)
        # Housecleaning
        rm ChangeLog
        find . -maxdepth 1 -name '[HMNrTgmn]*' -type f -print | xargs rm

set-img:
        mkdir -p $(PKG_DIR)/img
        mv $(CVSROOT)/*png $(PKG_DIR)/img

# No more exhaustive typing for updating Genshiken's Project Homepage
web-repository:
        make endprog && cd .. && make checkout-web && make fontify && make htmlize && cd $(PKG_DIR) && make set-img && cvs update && cvs commit

remove-old-docs:
        if [ -f $(PKG_DIR)/COPYING -o -f $(PKG_DIR)/COPYING.manual ]; then rm $(PKG_DIR)/COPYING*; fi
        if [ -f $(PKG_DIR)/NEWS ]; then rm $(PKG_DIR)/NEWS; fi

# Org underlines don't appear in info files hence this hack
org-export-info:
        [ ! -f $(PKG_DIR)/share/doc/readme.org ] && mv $(PKG_DIR)/share/doc/$(NAME)/readme.org $(PKG_DIR)/share/doc/ || :
        cp $(PKG_DIR)/share/doc/readme.org readme.org
        sed -i -e 's/\([^A-Za-z]\)_\([A-Za-z ][A-Za-z ]*\)_\([^A-Za-z]\)/\1\2\3/' -e 's/([0-9])//' readme.org
        sed -i 's_\.\./\.\._share_' readme.org
        sed -i 's_file:\($(NAME)-example-session.html\)_$(HOMEPAGE)/\1_' readme.org
        # Removing license designed only for the web version
        sed -i '/Last modified on/,/Code blocks are licensed/ d' readme.org

# Org definitions are not aligned properly in ASCII files hence this hack
org-export-text:
        [ ! -f $(PKG_DIR)/share/doc/readme.org ] && mv $(PKG_DIR)/share/doc/$(NAME)/readme.org $(PKG_DIR)/share/doc/ || :
        cp $(PKG_DIR)/share/doc/readme.org readme.org
        sed -i 's/:://' readme.org
        sed -i 's_\.\./\.\._share_' readme.org
        sed -i 's_file:\($(NAME)-example-session.html\)_$(HOMEPAGE)/\1_' readme.org
        # Removing license designed only for the web version
        sed -i '/Last modified on/,/Code blocks are licensed/ d' readme.org

$(PKG_DIR)/COPYING:
        wget -O $(PKG_DIR)/COPYING $(GPL)

$(PKG_DIR)/COPYING.manual:
        wget -O $(PKG_DIR)/COPYING.manual $(FDL)

license: remove-old-docs $(PKG_DIR)/COPYING $(PKG_DIR)/COPYING.manual
        cp --preserve $(PKG_DIR)/COPY* $(PKG_DIR)/share/doc/$(NAME)

#  That's right!  I publish it once on GNU Savannah, and
#+ this little script takes care of the rest.  Parameter 4 is either: `--add-comments` OR `--del-comments`
$(PKG_DIR)/NEWS:
        cd $(PKG_DIR); ./news-maker.sh $(PROJ) $(AUTHOR) $(COPYRIGHT_CMD) --add-comments

# For tarball users only
# NOTE: The first sed script fixes lines that start and end with an asterisk
#+      The second one adds an all-permissive copyright notice
$(PKG_DIR)/ChangeLog:
        cd $(PKG_DIR); cvs2cl --usermap AUTHORS
        cd $(PKG_DIR); eval 'sed -i "/\*[ ]*\$$/ { N; s/\n\t[ ]// }" ChangeLog'
        cd $(PKG_DIR); eval $(COPYRIGHT_CMD) >> ChangeLog; sed -i '/^\* etc.*/,+2 d' ChangeLog
        tac ChangeLog | sed '1,3 d' | tac > ChangeLog.1; mv ChangeLog.1 ChangeLog

tarball: license $(PKG_DIR)/NEWS $(PKG_DIR)/ChangeLog
        cp --preserve $(PKG_DIR)/[AHNRTm]* $(PKG_DIR)/share/doc/$(NAME)
        cp --preserve ChangeLog $(PKG_DIR)/share/doc/$(NAME)
        # Let's ensure the version # is up-to-date, as well
        sed -i "s_VERSION=.*_VERSION=$(VERSION)_" $(PKG_DIR)/share/$(NAME)/$(NAME)-main.sh
        cd $(CVSROOT); tar --exclude=CVS -czvf $(PKG) $(NAME)/*

$(PKG):
        if [ ! -d $(PKG_DIR) ]; then make checkout-soft; fi
        make tarball

build: $(PKG)

$(SIG):
        gpg -b --use-agent $(PKG)

sign: $(SIG)

clean:
        rm -f $(PKG) $(SIG) $(PKG_DIR)/ChangeLog $(PKG_DIR)/share/doc/$(NAME)/ChangeLog *~ 2> /dev/null

all: $(PKG) $(SIG)

# None yet
test:

# Only used when releasing a new version
# NOTE: The most up to date mirror is always $(LATEST_TARBALL)
release: $(PKG) $(SIG)
        scp $(PKG) $(SIG) $(ADMIN)@$(RELEASES):/releases/$(NAME)
        make clean

# Genshiken Hackers will have the tarball downloaded in $(CVSROOT)
# Normal users will have the tarball downloaded to the parent of the source directory
grab-pkg:
        if [ -d $(PKG_DIR) ]; then cd $(PKG_DIR)/..; else cd ..; fi; wget $(LATEST_TARBALL)
        if [ -d $(PKG_DIR) ]; then cd $(PKG_DIR)/..; else cd ..; fi; wget $(LATEST_TARBALL).sig
        if [ -d $(PKG_DIR) ]; then cd $(PKG_DIR); fi; gpg --verify ../$(PKG_NAME).tar.gz.sig

# These user commands are designed to be run inside the source directory
new-config:
        mkdir -p ~/.config/$(NAME)-$(SUDO_USER)
        echo '--colorize=dark' > ~/.config/$(NAME)-$(SUDO_USER)/config
        echo '--impatient=1'  >> ~/.config/$(NAME)-$(SUDO_USER)/config

remove-config:
        rm -r ~/.config/$(NAME)-*/*
        rmdir ~/.config/$(NAME)-*/

install:
        sed -i "s_^main=.*_main=$(PREFIX)/share/$(NAME)/$(NAME)-main.sh_" bin/$(NAME)
        sed -i "s_^doc=.*_doc=$(PREFIX)/share/doc/$(NAME)_" share/$(NAME)/$(NAME)-main.sh
        sed -i "s_^readonly PROGNAME=.*_readonly PROGNAME=$(PROJ)_" share/$(NAME)/$(NAME)-main.sh
        sed -i "s_^readonly VERSION=.*_readonly VERSION=$(VERSION)_" share/$(NAME)/$(NAME)-main.sh
        sed -i "s_^functions=.*_functions=$(PREFIX)/share/$(NAME)/functions/*_" share/$(NAME)/$(NAME)-main.sh
        # Desktop files are provided for the command-line inept users.  You will find new gnome-icons under the `Internet' category
        sed -i "s:^Icon=.*:Icon=$(PREFIX)/share/icons/hicolor/128x128/apps/using-gnu.svg:" share/applications/$(NAME)-anime.desktop
        sed -i "s:^Icon=.*:Icon=$(PREFIX)/share/icons/hicolor/128x128/apps/sos-gear.svg:" share/applications/$(NAME)-manual.desktop
        for dir in $(INSTALL_DIRS); do mkdir -p $(PREFIX)/$$dir; done
        for file in $(INSTALL_FILES); do cp $$file $(PREFIX)/$$file; done
        sed -i -e "s/USER/$(SUDO_USER)/g" -e "s_HOME/_$$HOME/_g" -e "s/$(NAME).1/$(NAME).1.gz/" $(PREFIX)/share/man/man1/$(NAME).1
        if [ -z $(BASH_COMP) ]; then cp $(PREFIX)/etc/bash_completion.d/$(NAME).bash-completion /etc/bash_completion.d/; fi
        gzip $(PREFIX)/share/man/man1/$(NAME).1

uninstall:
        for file in $(INSTALL_FILES); do rm -f $(PREFIX)/$$file; done
        for dir in $(INSTALL_DIRS); do echo $(PREFIX)/$$dir | grep ".*$(NAME).*" | xargs rm -rf; done
        if [ -f $(PREFIX)/share/man/man1/$(NAME).1.gz ]; then rm $(PREFIX)/share/man/man1/$(NAME).1.gz; fi
        if [ -f /etc/bash_completion.d/$(NAME).bash-completion ]; then rm /etc/bash_completion.d/$(NAME).bash-completion; fi

.PHONY: all build checkout-soft checkout-web clean endprog fontify grab-pkg htmlize install license new-config org-export-readme release remove-config remove-old-docs set-img sign tarball test uninstall web-repository

