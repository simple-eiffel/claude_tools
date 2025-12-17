note
	description: "CLI tools for Claude Code."
	author: "Claude (with Larry Rix)"

class
	CLAUDE_TOOLS_APP

inherit
	ARGUMENTS_32

create
	make

feature {NONE} -- Initialization

	make
		local
			l_api: FOUNDATION_API
		do
			create l_api
			create file_cmd.make (l_api)
			create search_cmd.make (l_api)
			create git_cmd.make (l_api)
			create test_cmd.make (l_api)
			create uuid_cmd.make (l_api)

			if argument_count < 1 then
				print_usage
			else
				dispatch_command
			end
		end

feature -- Commands

	dispatch_command
		local
			l_cmd: STRING_32
		do
			l_cmd := argument (1)
			if l_cmd.same_string ("file") then
				file_cmd.execute (arguments_array)
			elseif l_cmd.same_string ("grep") then
				search_cmd.execute_grep (arguments_array)
			elseif l_cmd.same_string ("glob") then
				search_cmd.execute_glob (arguments_array)
			elseif l_cmd.same_string ("git") then
				git_cmd.execute (arguments_array)
			elseif l_cmd.same_string ("test") then
				test_cmd.execute (arguments_array)
			elseif l_cmd.same_string ("uuid") then
				uuid_cmd.execute (arguments_array)
			else
				io.put_string ("ERROR: Unknown command: " + l_cmd.to_string_8 + "%N")
				print_usage
			end
		end

feature -- Output

	print_usage
		do
			io.put_string ("claude_tools - CLI tools for Claude Code%N%N")
			io.put_string ("COMMANDS:%N")
			io.put_string ("  file write <path> --stdin%N")
			io.put_string ("  file read <path>%N")
			io.put_string ("  file exists <path>%N")
			io.put_string ("  file delete <path>%N")
			io.put_string ("  file replace <path> --match <old> --with <new> [--all]%N%N")
			io.put_string ("  grep <pattern> <path>%N")
			io.put_string ("  glob <pattern> [<dir>]%N%N")
			io.put_string ("  git status [<dir>]%N")
			io.put_string ("  git add [<dir>] [--all]%N")
			io.put_string ("  git commit <message> [<dir>]%N")
			io.put_string ("  git push [<dir>]%N%N")
			io.put_string ("  test <exe_path>%N%N")
			io.put_string ("  uuid scan [<dir>]  - Scan for duplicate ECF UUIDs%N")
			io.put_string ("  uuid fix [<dir>]   - Fix duplicates with new UUIDs%N")
		end

feature {NONE} -- Implementation

	file_cmd: FILE_COMMAND
	search_cmd: SEARCH_COMMAND
	git_cmd: GIT_COMMAND
	test_cmd: TEST_COMMAND
	uuid_cmd: UUID_COMMAND

	arguments_array: ARRAY [STRING_32]
		local
			i: INTEGER
		do
			create Result.make_filled ({STRING_32} "", 1, argument_count)
			from i := 1 until i > argument_count loop
				Result [i] := argument (i)
				i := i + 1
			end
		end

end
