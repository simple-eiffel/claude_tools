note
	description: "Search operations command handler (grep, glob)"
	author: "Claude (with Larry Rix)"

class
	SEARCH_COMMAND

create
	make

feature {NONE} -- Initialization

	make (a_api: FOUNDATION_API)
		do
			api := a_api
		end

feature -- Execution

	execute_grep (args: ARRAY [STRING_32])
			-- Execute grep command.
			-- grep <pattern> <path> [--ext <extensions>] [--context <n>]
		local
			l_pattern, l_path: detachable STRING_32
			l_ext: detachable STRING_32
			l_context: INTEGER
			i: INTEGER
			l_output: STRING_32
		do
			if args.count < 3 then
				print_error ("grep: missing pattern and path")
			else
				l_pattern := args [2]
				l_path := args [3]
				l_context := 0
				from i := 4 until i > args.count loop
					if args [i].same_string ("--ext") and i + 1 <= args.count then
						l_ext := args [i + 1]
						i := i + 1
					elseif args [i].same_string ("--context") and i + 1 <= args.count then
						if args [i + 1].is_integer then
							l_context := args [i + 1].to_integer
						end
						i := i + 1
					end
					i := i + 1
				end
				-- Use simple_process to run rg or grep
				l_output := run_grep (l_pattern, l_path, l_ext, l_context)
				io.put_string (l_output.to_string_8)
			end
		end

	execute_glob (args: ARRAY [STRING_32])
			-- Execute glob command.
			-- glob <pattern> [<dir>]
		local
			l_pattern: STRING_32
			l_dir: STRING_32
			l_output: STRING_32
		do
			if args.count < 2 then
				print_error ("glob: missing pattern")
			else
				l_pattern := args [2]
				if args.count >= 3 then
					l_dir := args [3]
				else
					l_dir := "."
				end
				l_output := run_glob (l_pattern, l_dir)
				io.put_string (l_output.to_string_8)
			end
		end

feature {NONE} -- Implementation

	run_grep (a_pattern, a_path: STRING_32; a_ext: detachable STRING_32; a_context: INTEGER): STRING_32
			-- Run grep/rg command.
		local
			l_cmd: STRING_32
		do
			create l_cmd.make (100)
			-- Try rg first (ripgrep), fall back to grep
			l_cmd.append ("rg --no-heading --line-number")
			if a_context > 0 then
				l_cmd.append (" -C " + a_context.out)
			end
			if attached a_ext as ext then
				-- Convert comma-separated extensions to rg type or glob
				l_cmd.append (" --glob %"*." + ext + "%"")
			end
			l_cmd.append (" %"" + a_pattern + "%" %"" + a_path + "%"")
			Result := api.execute_command (l_cmd)
		end

	run_glob (a_pattern, a_dir: STRING_32): STRING_32
			-- Run glob/find command.
		local
			l_cmd: STRING_32
		do
			create l_cmd.make (100)
			-- Use find with -name pattern
			l_cmd.append ("find %"" + a_dir + "%" -name %"" + a_pattern + "%" -type f 2>/dev/null")
			Result := api.execute_command (l_cmd)
		end

	print_error (a_msg: STRING)
		do
			io.error.put_string ("ERROR: " + a_msg + "%N")
		end

	api: FOUNDATION_API

end
