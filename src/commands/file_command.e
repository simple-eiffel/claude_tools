note
	description: "File operations command handler"
	author: "Claude (with Larry Rix)"

class
	FILE_COMMAND

create
	make

feature {NONE} -- Initialization

	make (a_api: FOUNDATION_API)
		do
			api := a_api
		end

feature -- Execution

	execute (args: ARRAY [STRING_32])
			-- Execute file subcommand.
		local
			l_subcmd: STRING_32
		do
			if args.count < 2 then
				print_error ("file: missing subcommand")
				print_file_usage
			else
				l_subcmd := args [2]
				if l_subcmd.same_string ("write") then
					do_write (args)
				elseif l_subcmd.same_string ("read") then
					do_read (args)
				elseif l_subcmd.same_string ("exists") then
					do_exists (args)
				elseif l_subcmd.same_string ("list") then
					do_list (args)
				elseif l_subcmd.same_string ("delete") then
					do_delete (args)
				elseif l_subcmd.same_string ("replace") then
					do_replace (args)
				elseif l_subcmd.same_string ("insert") then
					do_insert (args)
				else
					print_error ("file: unknown subcommand: " + l_subcmd.to_string_8)
					print_file_usage
				end
			end
		end

feature {NONE} -- Subcommands

	do_write (args: ARRAY [STRING_32])
			-- Write content to file.
		local
			l_path: STRING_32
			l_content: STRING
			l_source_path: detachable STRING_32
			l_use_stdin: BOOLEAN
			i: INTEGER
		do
			if args.count < 3 then
				print_error ("file write: missing path")
			else
				l_path := args [3]
				from i := 4 until i > args.count loop
					if args [i].same_string ("--stdin") then
						l_use_stdin := True
					elseif args [i].same_string ("--from") and i + 1 <= args.count then
						l_source_path := args [i + 1]
						i := i + 1
					end
					i := i + 1
				end
				if l_use_stdin then
					l_content := read_stdin
				elseif attached l_source_path as src then
					if attached api.read_file (src.to_string_8) as fc then
						l_content := fc
					else
						l_content := ""
					end
				else
					l_content := read_stdin
				end
				if attached l_content as c then
					api.write_file (l_path.to_string_8, c)
					io.put_string ("OK: " + l_path.to_string_8 + " (" + c.count.out + " bytes)%N")
				else
					print_error ("file write: no content to write")
				end
			end
		end

	do_read (args: ARRAY [STRING_32])
			-- Read file content.
		local
			l_path: STRING_32
			l_content: detachable STRING
		do
			if args.count < 3 then
				print_error ("file read: missing path")
			else
				l_path := args [3]
				l_content := api.read_file (l_path.to_string_8)
				if attached l_content as c then
					io.put_string (c)
				else
					print_error ("file read: cannot read " + l_path.to_string_8)
				end
			end
		end

	do_exists (args: ARRAY [STRING_32])
			-- Check if file exists.
		local
			l_path: STRING_32
		do
			if args.count < 3 then
				print_error ("file exists: missing path")
			else
				l_path := args [3]
				if api.file_exists (l_path.to_string_8) then
					io.put_string ("true%N")
				else
					io.put_string ("false%N")
				end
			end
		end

	do_list (args: ARRAY [STRING_32])
			-- List directory contents using shell.
		local
			l_dir: STRING_32
			l_pattern: detachable STRING_32
			l_cmd: STRING_32
			l_output: STRING_32
			i: INTEGER
		do
			if args.count < 3 then
				print_error ("file list: missing directory")
			else
				l_dir := args [3]
				from i := 4 until i > args.count loop
					if args [i].same_string ("--glob") and i + 1 <= args.count then
						l_pattern := args [i + 1]
						i := i + 1
					end
					i := i + 1
				end
				create l_cmd.make (100)
				l_cmd.append ("ls -1 %"")
				l_cmd.append (l_dir)
				l_cmd.append ("%"")
				if attached l_pattern as pat then
					l_cmd.append (" | grep -E %"")
					l_cmd.append (glob_to_regex (pat))
					l_cmd.append ("%"")
				end
				l_output := api.execute_command (l_cmd)
				io.put_string (l_output.to_string_8)
			end
		end

	do_delete (args: ARRAY [STRING_32])
			-- Delete a file using shell.
		local
			l_path: STRING_32
			l_cmd: STRING_32
		do
			if args.count < 3 then
				print_error ("file delete: missing path")
			else
				l_path := args [3]
				if api.file_exists (l_path.to_string_8) then
					create l_cmd.make (50)
					l_cmd.append ("rm %"")
					l_cmd.append (l_path)
					l_cmd.append ("%"")
					api.execute_command (l_cmd).do_nothing
					io.put_string ("OK: deleted " + l_path.to_string_8 + "%N")
				else
					print_error ("file delete: file not found: " + l_path.to_string_8)
				end
			end
		end

	do_replace (args: ARRAY [STRING_32])
			-- Replace text in file.
		local
			l_path: STRING_32
			l_match, l_with: detachable STRING_32
			l_all: BOOLEAN
			l_content: detachable STRING
			l_new_content: STRING
			i: INTEGER
		do
			if args.count < 3 then
				print_error ("file replace: missing path")
			else
				l_path := args [3]
				from i := 4 until i > args.count loop
					if args [i].same_string ("--match") and i + 1 <= args.count then
						l_match := args [i + 1]
						i := i + 1
					elseif args [i].same_string ("--with") and i + 1 <= args.count then
						l_with := args [i + 1]
						i := i + 1
					elseif args [i].same_string ("--all") then
						l_all := True
					end
					i := i + 1
				end
				if not attached l_match then
					print_error ("file replace: missing --match")
				elseif not attached l_with then
					print_error ("file replace: missing --with")
				else
					l_content := api.read_file (l_path.to_string_8)
					if attached l_content as c then
						l_new_content := c.twin
						if l_all then
							l_new_content.replace_substring_all (l_match.to_string_8, l_with.to_string_8)
						else
							if l_new_content.has_substring (l_match.to_string_8) then
								l_new_content.replace_substring (l_with.to_string_8, 
									l_new_content.substring_index (l_match.to_string_8, 1),
									l_new_content.substring_index (l_match.to_string_8, 1) + l_match.count - 1)
							end
						end
						api.write_file (l_path.to_string_8, l_new_content)
						io.put_string ("OK: replaced in " + l_path.to_string_8 + "%N")
					else
						print_error ("file replace: cannot read " + l_path.to_string_8)
					end
				end
			end
		end

	do_insert (args: ARRAY [STRING_32])
			-- Insert content after pattern.
		local
			l_path: STRING_32
			l_pattern: detachable STRING_32
			l_content, l_insert_content: detachable STRING
			l_new_content: STRING
			l_pos: INTEGER
			i: INTEGER
			l_use_stdin: BOOLEAN
		do
			if args.count < 3 then
				print_error ("file insert: missing path")
			else
				l_path := args [3]
				from i := 4 until i > args.count loop
					if args [i].same_string ("--after") and i + 1 <= args.count then
						l_pattern := args [i + 1]
						i := i + 1
					elseif args [i].same_string ("--stdin") then
						l_use_stdin := True
					end
					i := i + 1
				end
				if not attached l_pattern then
					print_error ("file insert: missing --after")
				elseif not l_use_stdin then
					print_error ("file insert: missing --stdin")
				else
					l_content := api.read_file (l_path.to_string_8)
					l_insert_content := read_stdin
					if attached l_content as c and attached l_insert_content as ins then
						l_pos := c.substring_index (l_pattern.to_string_8, 1)
						if l_pos > 0 then
							l_new_content := c.twin
							l_new_content.insert_string (ins, l_pos + l_pattern.count)
							api.write_file (l_path.to_string_8, l_new_content)
							io.put_string ("OK: inserted in " + l_path.to_string_8 + "%N")
						else
							print_error ("file insert: pattern not found: " + l_pattern.to_string_8)
						end
					else
						print_error ("file insert: cannot read file or stdin")
					end
				end
			end
		end

feature {NONE} -- Helpers

	read_stdin: STRING
			-- Read all content from stdin.
		do
			create Result.make (4096)
			from
				io.read_line
			until
				io.input.end_of_file
			loop
				Result.append (io.last_string)
				Result.append_character ('%N')
				io.read_line
			end
			if not io.last_string.is_empty then
				Result.append (io.last_string)
			end
			if Result.count > 0 and then Result [Result.count] = '%N' then
				Result.remove_tail (1)
			end
		end

	glob_to_regex (a_pattern: STRING_32): STRING_32
			-- Convert simple glob to regex.
		do
			Result := a_pattern.twin
			Result.replace_substring_all (".", "\.")
			Result.replace_substring_all ("*", ".*")
		end

	print_error (a_msg: STRING)
		do
			io.error.put_string ("ERROR: " + a_msg + "%N")
		end

	print_file_usage
		do
			io.put_string ("Usage: claude_tools file <subcommand> [options]%N")
			io.put_string ("  write <path> [--stdin | --from <file>]%N")
			io.put_string ("  read <path>%N")
			io.put_string ("  exists <path>%N")
			io.put_string ("  list <dir> [--glob <pattern>]%N")
			io.put_string ("  delete <path>%N")
			io.put_string ("  replace <path> --match <old> --with <new> [--all]%N")
			io.put_string ("  insert <path> --after <pattern> --stdin%N")
		end

feature {NONE} -- Implementation

	api: FOUNDATION_API

end
