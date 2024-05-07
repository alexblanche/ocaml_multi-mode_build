let _ =
  generate_makefile (Sys.argv.(1)) (List.tl (List.tl (Array.to_list Sys.argv)))
;;