DOCTYPE = RTN
DOCNUMBER = 070
DOCNAME = $(DOCTYPE)-$(DOCNUMBER)

tex = $(filter-out $(wildcard *acronyms.tex) , $(wildcard *.tex))

GITVERSION := $(shell git log -1 --date=short --pretty=%h)
GITDATE := $(shell git log -1 --date=short --pretty=%ad)
GITSTATUS := $(shell git status --porcelain)
ifneq "$(GITSTATUS)" ""
	GITDIRTY = -dirty
endif

# All LaTeX make-ry commented out: 

# export TEXMFHOME ?= lsst-texmf/texmf

# Add aglossary.tex as a dependancy here if you want a glossary (and remove acronyms.tex)
# $(DOCNAME).pdf: $(tex) meta.tex local.bib acronyms.tex
# 	latexmk -bibtex -xelatex -f $(DOCNAME)
#	makeglossaries $(DOCNAME)
#	xelatex $(DOCNAME)
# For glossary uncomment the 2 lines above


# Acronym tool allows for selection of acronyms based on tags - you may want more than DM
# acronyms.tex: $(tex) myacronyms.txt
# 	$(TEXMFHOME)/../bin/generateAcronyms.py -t "DM" $(tex)

# If you want a glossary you must manually run generateAcronyms.py  -gu to put the \gls in your files.
# aglossary.tex :$(tex) myacronyms.txt
# 	generateAcronyms.py  -g $(tex)


# Do the Google docs download. Note that we still need to make the meta.tex file, for LSSTthedocs to use.
# We also want to check in plain text and html, for back-up - so we get this first (below), then grab the PDF:

GOOGURL = https://docs.google.com/document/d/1FrwxO9Z0XS46gvEPq1E0Md9i8_e8Gxha2RD1djquGXY

$(DOCNAME).pdf: meta.tex backup
	apt-get update
	apt-get -y install curl
	curl -L "$(GOOGURL)/export?format=pdf" -o $@


.PHONY: clean
clean:
	latexmk -c
	rm -f $(DOCNAME).{bbl,glsdefs,pdf}
	rm -f meta.tex

.FORCE:

meta.tex: Makefile .FORCE
	rm -f $@
	touch $@
	printf '%% GENERATED FILE -- edit this in the Makefile\n' >>$@
	printf '\\newcommand{\\lsstDocType}{$(DOCTYPE)}\n' >>$@
	printf '\\newcommand{\\lsstDocNum}{$(DOCNUMBER)}\n' >>$@
	printf '\\newcommand{\\vcsRevision}{$(GITVERSION)$(GITDIRTY)}\n' >>$@
	printf '\\newcommand{\\vcsDate}{$(GITDATE)}\n' >>$@

# Here's where we download, as back-up in case the Google doc gets lost in future, copies of the Gdoc content in both plain text and html formats, and check them in to the repo.
# Note that GitHub wants to know who is making the commit. See the discussion at https://github.community/t/how-does-one-commit-from-an-action/16127/9

backup:
	apt-get update
	apt-get -y install curl
	curl -L "$(GOOGURL)/export?format=txt" -o $(DOCNAME).txt
	curl -L "$(GOOGURL)/export?format=html" | sed s%"<"%"\n<"%g > $(DOCNAME).html
	if  [ $(GITBRANCH) = "branch" ]; then\
		git config --local user.email github-actions@github.com;\
		git config --local user.name github-actions;\
		git add $(DOCNAME).txt $(DOCNAME).html;\
		git commit -am 'Back-up txt and html downloaded on $(GITDATE) for Revision $(GITVERSION)$(GITDIRTY)';\
		git push;\
	fi
