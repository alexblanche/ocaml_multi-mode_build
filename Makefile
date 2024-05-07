OCAMLOPT = @ocamlopt
OCAMLFINDOPT = @ocamlfind opt
MKDIR = @mkdir
RM = @rm
PRINT = @echo $<

SUFFIXES ?= .ml .o .cmx .cmi
.SUFFIXES: $(SUFFIXES) .

.PHONY: all clean

EXEC = builder
BUILDDIR = ./build

OBJS = $(BUILDDIR)/project_extraction.cmx \
	$(BUILDDIR)/dependency_computation.cmx \
	$(BUILDDIR)/makefile_generation.cmx \
	$(BUILDDIR)/exec.cmx

##################################################################

all: $(EXEC)

clean:
	$(RM) -r $(BUILDDIR) 2>/dev/null
	$(RM) $(EXEC) 2>/dev/null

$(BUILDDIR):
	$(MKDIR) $@

##################################################################

$(BUILDDIR)/project_extraction.cmx: src/project_extraction.ml \
	| $(BUILDDIR)
	$(PRINT)
	$(OCAMLOPT) -c $< -o $@

$(BUILDDIR)/dependency_computation.cmx: src/dependency_computation.ml \
	$(BUILDDIR)/project_extraction.cmx \
	| $(BUILDDIR)
	$(PRINT)
	$(OCAMLOPT) -c $< -o $@ -I $(BUILDDIR) \
		-open Project_extraction

$(BUILDDIR)/makefile_generation.cmx: src/makefile_generation.ml \
	$(BUILDDIR)/project_extraction.cmx \
	$(BUILDDIR)/dependency_computation.cmx \
	| $(BUILDDIR)
	$(PRINT)
	$(OCAMLOPT) -c $< -o $@ -I $(BUILDDIR) \
		-open Project_extraction

$(BUILDDIR)/exec.cmx: src/exec.ml \
	$(BUILDDIR)/makefile_generation.cmx \
	| $(BUILDDIR)
	$(PRINT)
	$(OCAMLOPT) -c $< -o $@ -I $(BUILDDIR) \
		-open Makefile_generation

# Main executable
$(EXEC): $(OBJS)
	@echo $@
	$(OCAMLOPT) -o $@ $(OBJS)

