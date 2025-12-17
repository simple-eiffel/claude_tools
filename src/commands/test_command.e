note
	description: "Test runner command handler"
	author: "Claude (with Larry Rix)"

class
	TEST_COMMAND

create
	make

feature {NONE} -- Initialization

	make (a_api: FOUNDATION_API)
		do
			api := a_api
		end

feature -- Execution

	execute (args: ARRAY [STRING_32])
			-- Execute test command.
			-- test <exe_path>
		local
			l_exe_path: STRING_32
			l_output: STRING_32
		do
			if args.count < 2 then
				print_error ("test: missing executable path")
				io.put_string ("Usage: claude_tools test <exe_path>%N")
			else
				l_exe_path := args [2]
				if api.file_exists (l_exe_path.to_string_8) then
					l_output := api.execute_command (l_exe_path)
					io.put_string (l_output.to_string_8)
				else
					print_error ("test: executable not found: " + l_exe_path.to_string_8)
				end
			end
		end

feature {NONE} -- Helpers

	print_error (a_msg: STRING)
		do
			io.error.put_string ("ERROR: " + a_msg + "%N")
		end

	api: FOUNDATION_API

end
