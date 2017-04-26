# Edit these variables if more directories are needed.
SRCDIRS		:=	src


PROG:=gpp
SRCEXT:=.gpp
OUTEXT:=.txt
export VPATH	:=	$(foreach DIR,$(SRCDIRS),$(CURDIR)/$(DIR))

SRCFILES:=$(foreach DIR,$(SRCDIRS),$(notdir $(wildcard $(DIR)/*$(SRCEXT))))
OUTFILES:=$(SRCFILES:%$(SRCEXT)=%$(OUTEXT))

all : $(OUTFILES)

$(OUTFILES) : %$(OUTEXT) : %$(SRCEXT)
	$(PROG) $< > $@

.PHONY : clean
clean:  
	rm -fv $(OUTFILES)
