note
	description: "Git operations command handler"
	author: "Claude (with Larry Rix)"

class
	GIT_COMMAND

create
	make

feature {NONE} -- Initialization

	make (a_api: FOUNDATION_API)
		do
			api := a_api
		end

feature -- Execution

	execute (args: ARRAY [STRING_32])
			-- Execute git subcommand.
		local
			l_subcmd: STRING_32
		do
			if args.count < 2 then
				print_error ("git: missing subcommand")
				print_git_usage
			else
				l_subcmd := args [2]
				if l_subcmd.same_string ("status") then
					do_status (args)
				elseif l_subcmd.same_string ("add") then
					do_add (args)
				elseif l_subcmd.same_string ("commit") then
					do_commit (args)
				elseif l_subcmd.same_string ("push") then
					do_push (args)
				elseif l_subcmd.same_string ("diff") then
					do_diff (args)
				elseif l_subcmd.same_string ("log") then
					do_log (args)
				else
					print_error ("git: unknown subcommand: " + l_subcmd.to_string_8)
					print_git_usage
				end
			end
		end

feature {NONE} -- Subcommands

	do_status (args: ARRAY [STRING_32])
			-- git status [<dir>]
		local
			l_dir: STRING_32
			l_output: STRING_32
		do
			if args.count >= 3 then
				l_dir := args [3]
			else
				l_dir := "."
			end
			l_output := run_git_in_dir ("status", l_dir)
			io.put_string (l_output.to_string_8)
		end

	do_add (args: ARRAY [STRING_32])
			-- git add [<dir>] [--all]
		local
			l_dir: STRING_32
			l_all: BOOLEAN
			i: INTEGER
			l_cmd: STRING
			l_output: STRING_32
		do
			l_dir := "."
			from i := 3 until i > args.count loop
				if args [i].same_string ("--all") then
					l_all := True
				elseif not args [i].starts_with ("--") then
					l_dir := args [i]
				end
				i := i + 1
			end
			if l_all then
				l_cmd := "add -A"
			else
				l_cmd := "add ."
			end
			l_output := run_git_in_dir (l_cmd, l_dir)
			io.put_string ("OK: git " + l_cmd + "%N")
			if not l_output.is_empty then
				io.put_string (l_output.to_string_8)
			end
		end

	do_commit (args: ARRAY [STRING_32])
			-- git commit <message> [<dir>]
		local
			l_message: detachable STRING_32
			l_dir: STRING_32
			l_cmd: STRING
			l_output: STRING_32
		do
			if args.count < 3 then
				print_error ("git commit: missing message")
			else
				l_message := args [3]
				if args.count >= 4 then
					l_dir := args [4]
				else
					l_dir := "."
				end
				-- Escape quotes in message
				l_cmd := "commit -m %"" + escape_quotes (l_message.to_string_8) + "%""
				l_output := run_git_in_dir (l_cmd, l_dir)
				io.put_string (l_output.to_string_8)
			end
		end

	do_push (args: ARRAY [STRING_32])
			-- git push [<dir>]
		local
			l_dir: STRING_32
			l_output: STRING_32
		do
			if args.count >= 3 then
				l_dir := args [3]
			else
				l_dir := "."
			end
			l_output := run_git_in_dir ("push", l_dir)
			io.put_string (l_output.to_string_8)
		end

	do_diff (args: ARRAY [STRING_32])
			-- git diff [<dir>]
		local
			l_dir: STRING_32
			l_output: STRING_32
		do
			if args.count >= 3 then
				l_dir := args [3]
			else
				l_dir := "."
			end
			l_output := run_git_in_dir ("diff", l_dir)
			io.put_string (l_output.to_string_8)
		end

	do_log (args: ARRAY [STRING_32])
			-- git log [<dir>] [--count <n>]
		local
			l_dir: STRING_32
			l_count: INTEGER
			i: INTEGER
			l_cmd: STRING
			l_output: STRING_32
		do
			l_dir := "."
			l_count := 10
			from i := 3 until i > args.count loop
				if args [i].same_string ("--count") and i + 1 <= args.count then
					if args [i + 1].is_integer then
						l_count := args [i + 1].to_integer
					end
					i := i + 1
				elseif not args [i].starts_with ("--") then
					l_dir := args [i]
				end
				i := i + 1
			end
			l_cmd := "log --oneline -n " + l_count.out
			l_output := run_git_in_dir (l_cmd, l_dir)
			io.put_string (l_output.to_string_8)
		end

feature {NONE} -- Helpers

	run_git_in_dir (a_cmd: STRING; a_dir: STRING_32): STRING_32
			-- Run git command in specified directory.
		local
			l_full_cmd: STRING_32
		do
			create l_full_cmd.make (100)
			l_full_cmd.append ("cd %"")
			l_full_cmd.append (a_dir)
			l_full_cmd.append ("%" && git ")
			l_full_cmd.append_string_general (a_cmd)
			Result := api.execute_command (l_full_cmd)
		end

	escape_quotes (a_str: STRING): STRING
			-- Escape double quotes for shell.
		do
			Result := a_str.twin
			Result.replace_substring_all ("%"", "\%"")
		end

	print_error (a_msg: STRING)
		do
			io.error.put_string ("ERROR: " + a_msg + "%N")
		end

	print_git_usage
		do
			io.put_string ("Usage: claude_tools git <subcommand> [options]%N")
			io.put_string ("  status [<dir>]%N")
			io.put_string ("  add [<dir>] [--all]%N")
			io.put_string ("  commit <message> [<dir>]%N")
			io.put_string ("  push [<dir>]%N")
			io.put_string ("  diff [<dir>]%N")
			io.put_string ("  log [<dir>] [--count <n>]%N")
		end

	api: FOUNDATION_API

end
