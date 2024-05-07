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
let get_file_name_list () : file_name list =
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
