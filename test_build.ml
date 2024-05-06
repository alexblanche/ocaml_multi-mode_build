(* Type that stores a file name with its full path (/mnt/d/.../file.ml) and the actual file name (file.ml) *)
type file_name = { full_name : string; base_name : string };;

(* Writes in file build/files.txt the names of the .ml files in the given folder *)
let extract_project_files (path : string) : unit =
	if not (Sys.is_directory path) then
		failwith ("extract_project_files: Error, "^path^" does not refer to a directory");
	if not (Sys.file_exists "build") then
		Sys.mkdir "build" 777;
	let _ =
		Sys.command ("find "^path^" -type f -name \\*.ml | xargs realpath > build/files.txt")
	in
	();;

(* Reads into build/files.txt the file names and returns a list of file_name objects *)
let file_name_array () : file_name list =
		if not (Sys.file_exists "build/files.txt") then
			failwith "File build/files.txt does not exist. Execute extract_project_files first";
		let in_ch = In_channel.open_text "build/files.txt" in

		(* Inputs all lines of in_ch *)
		let rec aux sl =
			match In_channel.input_line in_ch with
				| Some s -> aux (s::sl)
				| None -> sl
		in

		let sl = aux [] in
		In_channel.close in_ch;
		List.map
			(fun file_name ->
				{ full_name = file_name;
					base_name = Filename.chop_suffix (Filename.basename file_name) ".ml"}
			)
			sl;;

(* Adds all the values of a .mli file mli_file_name in the hash table values *)
let add_all_values (values : (string * file_name) Hashtbl.t) (mli_file_name : string) (fn : file_name) : unit =
	let in_ch = In_channel.open_text mli_file_name in
	
	let rec aux () =
		match In_channel.input_line in_ch with
			| Some s ->
				(if (String.length s <= 4 || String.sub s 0 4 <> "val ") then
					failwith ("add_all_values: Parsing error in file "^mli_file_name);
				(* Line is "val val_name : type" *)
				let next_space_index = String.index_from s 4 ' ' in
				let val_name = String.sub s 4 (next_space_index - 4) in
				Hashtbl.add values (val_name, fn);
				aux ()
				)
			| None -> ()
	in
	aux ();;

	In_channel.close in_ch;;

(* Given a .mli file (s is the first line, in_ch is the in_channel containing the rest of the file),
	returns the first dependency M (as in "Error: Unbound module M") *)
let rec find_dependency (first_line : string) (in_ch : In_channel.t) : string =
	if String.starts_with ~prefix:"Error: Unbound module " (first_line) then
		(* 22 = String.length "Error: Unbound module " *)
		String.sub first_line 22 (String.length s - 22)
	else
		match In_channel.input_line in_ch with
			| Some s ->
				find_dependency s in_ch
			| None ->
				failwith "find_dependency: no dependency found"
;;

(* For a file_name fn without dependencies, returns the compile instructions to add to the generated makefile *)
let compile_instructions_no_dep (fn : file_name) : string =
	"$(BUILDDIR)/"^fn.base_name^".cmx: "^fn.full_name^" | $(BUILDDIR)\n\t$(PRINT)\n\t$(OCAMLOPT) -c $< -o $@";;


(* Type that contains compilation information:
	- the name of the file
	- the next dependency, waiting for another file to be compiled *)
type compile_info = { name : file_name; next_dependency : string };;

(* First pass: compiles each file in file_name_list with ocamlopt -i and creates an object compile_info for each file that has some dependencies
	- If it compiles: the values (functions, and variables) are added to the hash table values, paired with the file name
	- If it does not compile: the first dependency is added to the field next_dependency
	Returns a pair (compile_instr, compile_info) which contains:
	- compile_instr: a string list of the targets to add to the generated makefile, for the files that compiled without dependencies
	- compile_infos: a compile_info list of the dependencies of the files that did not compile
*)
let first_pass (fl : file_name list) : ((string * file_name) Hashtbl.t * compile_info list) =

	let (values : (string * file_name) Hashtbl.t) = Hashtbl.create (10 * List.length fl) in

	let op (compile_instr, compile_infos : string list * compile_info list) (fn : file_name) : unit =

		let err_name = "build/" ^ fn.base_name ^ ".err" in
		let mli_name = "build/" ^ fn.base_name ^ ".mli" in
		Sys.command ("ocamlopt -i " ^ fn.full_name ^ " > " ^ mli_name ^ "2> " ^ err_name);
		let err_ch = In_channel.open_text err_name in
		
		(match In_channel.input_line err_ch with
			
			| None -> (* File compiled correctly *)
				(add_all_values values mli_name;
				(compile_instructions_no_dep fn :: compile_instr, compile_infos))
			
			| Some s -> (* Error or warning during compilation *)
				let dep = find_dependency s err_ch in
				(compile_instr, { name = fn; next_dependency = dep} :: compile_infos)
		
		);
		In_channel.close err_ch
	in

	List.fold_left op ([], []) fl;;

(* Main function, generates the makefile in the given directory (first draft) *)
let generate_makefile (directory : string) : unit =
	let out_ch = Out_channel.open_text (directory^"Makefile") in
	(* To do *)
	();
	Out_channel.close out_ch;;