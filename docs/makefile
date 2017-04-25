# Edit these variables if more directories are needed.
SRCDIRS		:=	src

export VPATH	:=	$(foreach DIR,$(SRCDIRS),$(CURDIR)/$(DIR))

SRCFILES:=$(foreach DIR,$(SRCDIRS),$(notdir $(wildcard $(DIR)/*.gpp)))
OUTFILES:=$(SRCFILES:%.gpp=%.txt)

all : $(OUTFILES)

$(OUTFILES) : %.txt : %.gpp
	gpp $< > $@

.PHONY : clean
clean:  
	rm -fv $(OUTFILES)
