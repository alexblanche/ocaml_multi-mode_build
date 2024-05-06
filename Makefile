all:
	@mkdir build
	@ocamlopt -c test_build.ml -o build/test_build.cmx
	@ocamlopt -o builder build/test_build.cmx

clean:
	@rm -r build 2>/dev/null
	@rm builder 2>/dev/null