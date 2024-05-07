(* Main function, generates the makefile in the given directory (first draft) *)
let generate_makefile (directory : string) (packages : string list) : unit =

	if not (Sys.is_directory directory) then
		failwith ("generate_makefile: Error, "^directory^" is not a directory");
	let out_ch = Out_channel.open_text (* TO BE CHANGED TO: (directory^"Makefile") *) "TEST/Makefile" in

	(* Alias for writing function *)
	let out s = Out_channel.output_string out_ch s in

	out "OCAMLOPT = @ocamlopt -principal\n";
	out "OCAMLFINDOPT = @ocamlfind opt -principal\n";
	out "OCAMLC = @ocamlc -principal\n";
	out "MKDIR = @mkdir\n";
	out "PRINT = @echo $<\n\n";
	out "SUFFIXES ?= .ml .o .cmx .cmi\n";
	out ".SUFFIXES: $(SUFFIXES) .\n\n";
	out "EXEC_FILE = main\n";
	out "BUILDDIR = ./build\n";
	out ".PHONY: all clean\n\n";
	out "OBJS = \\\n";

	let _ = extract_project_files directory in
	let files = get_file_name_list () in

	(* Should they be in order of dependency? *)
	List.iter
		(fun fn ->
			out "\t$(BUILDDIR)/";
			out fn.base_name;
			out ".cmx \\\n")
		files;

	out "\n";
	out "###########################################################\n";
	out "# Main targets\n\n";
	out "all: $(EXEC_FILE)\n\n";
	out "clean:\n";
	out "\t@rm -r $(BUILDDIR)\n";
	out "\t@rm $(EXEC_FILE)\n\n";
	out "$(BUILDDIR):\n";
	out "\t$(MKDIR) $@\n\n";
	out "###########################################################\n\n";

	(* Generate all intermediate targets: to do *)
	();

	out "# Main executable\n";
	out "$(EXEC_FILE): $(OBJS)\n";
	out "\t@echo $@\n";
	out "$(OCAMLFINDOPT) -o $(EXEC_FILE) $(OBJS) \\\n";

	List.iter (fun s -> out "\t\t-package "; out s; out " \\\n") packages;
	out "\t\t-linkpkg \\\n";
	out "\n";

	Out_channel.close out_ch;;