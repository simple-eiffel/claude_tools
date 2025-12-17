note
	description: "UUID operations - scan and fix duplicate ECF UUIDs in ecosystem"
	author: "Claude (with Larry Rix)"

class
	UUID_COMMAND

create
	make

feature {NONE} -- Initialization

	make (a_api: FOUNDATION_API)
		do
			api := a_api
		end

feature -- Execution

	execute (args: ARRAY [STRING_32])
			-- Execute uuid subcommand.
		local
			l_subcmd: STRING_32
		do
			if args.count < 2 then
				print_error ("uuid: missing subcommand")
				print_uuid_usage
			else
				l_subcmd := args [2]
				if l_subcmd.same_string ("scan") then
					do_scan (args, False)
				elseif l_subcmd.same_string ("fix") then
					do_scan (args, True)
				else
					print_error ("uuid: unknown subcommand: " + l_subcmd.to_string_8)
					print_uuid_usage
				end
			end
		end

feature {NONE} -- Subcommands

	do_scan (args: ARRAY [STRING_32]; a_fix: BOOLEAN)
			-- Scan ecosystem for duplicate UUIDs, optionally fix them.
		local
			l_path: STRING_32
			l_dir: DIRECTORY
			l_uuid_map: HASH_TABLE [ARRAYED_LIST [STRING], STRING]
			l_dupes_found: BOOLEAN
			l_fixed_count: INTEGER
			l_uuid: STRING
			l_files: ARRAYED_LIST [STRING]
		do
			-- Default to D:\prod for simple_* ecosystem
			if args.count >= 3 then
				l_path := args [3]
			else
				l_path := {STRING_32} "D:\prod"
			end

			create l_uuid_map.make (100)
			io.put_string ("Scanning ECF files in: " + l_path.to_string_8 + "%N")

			-- Scan all simple_* directories
			create l_dir.make_open_read (l_path.to_string_8)
			if l_dir.exists then
				scan_directory (l_dir, l_uuid_map)
			end

			-- Report results
			io.put_string ("%N=== UUID Scan Results ===%N")
			io.put_string ("Total unique UUIDs: " + l_uuid_map.count.out + "%N")
			
			l_dupes_found := False
			from
				l_uuid_map.start
			until
				l_uuid_map.after
			loop
				l_uuid := l_uuid_map.key_for_iteration
				l_files := l_uuid_map.item_for_iteration
				if l_files.count > 1 then
					l_dupes_found := True
					io.put_string ("%NDUPLICATE UUID: " + l_uuid + "%N")
					across l_files as file_ic loop
						io.put_string ("  - " + file_ic + "%N")
					end
					
					if a_fix then
						l_fixed_count := l_fixed_count + fix_duplicates (l_uuid, l_files)
					end
				end
				l_uuid_map.forth
			end

			if not l_dupes_found then
				io.put_string ("%NNo duplicate UUIDs found. All clear!%N")
			else
				io.put_string ("%NWARNING: Duplicate UUIDs cause VD89 dependency cycle errors!%N")
				if a_fix then
					io.put_string ("Fixed " + l_fixed_count.out + " ECF files with new UUIDs.%N")
				else
					io.put_string ("Run 'uuid fix' to automatically generate new UUIDs.%N")
				end
			end
		end

	fix_duplicates (a_uuid: STRING; a_files: ARRAYED_LIST [STRING]): INTEGER
			-- Fix duplicate UUIDs - keep first, generate new for rest.
		local
			l_first: BOOLEAN
			l_new_uuid: STRING
			l_content: detachable STRING
			l_new_content: STRING
			l_file: STRING
		do
			l_first := True
			across a_files as ic loop
				l_file := ic
				if l_first then
					io.put_string ("  Keeping: " + l_file + "%N")
					l_first := False
				else
					l_new_uuid := generate_uuid
					l_content := api.read_file (l_file)
					if attached l_content as c then
						l_new_content := c.twin
						l_new_content.replace_substring_all (a_uuid, l_new_uuid)
						api.write_file (l_file, l_new_content)
						io.put_string ("  Fixed: " + l_file + " -> " + l_new_uuid + "%N")
						Result := Result + 1
					end
				end
			end
		end

	generate_uuid: STRING
			-- Generate a new UUID.
		do
			Result := api.new_uuid
		end

	scan_directory (a_dir: DIRECTORY; a_uuid_map: HASH_TABLE [ARRAYED_LIST [STRING], STRING])
			-- Scan directory for simple_* subdirectories.
		local
			l_entries: ARRAYED_LIST [STRING_32]
			l_entry: STRING_32
			l_subdir: DIRECTORY
			l_full_path: STRING
		do
			create l_entries.make (50)
			across a_dir.entries as ic loop
				l_entries.extend (ic.name.to_string_32)
			end

			across l_entries as ic loop
				l_entry := ic
				if not l_entry.same_string (".") and not l_entry.same_string ("..") then
					l_full_path := a_dir.path.name.to_string_8 + "\" + l_entry.to_string_8
					if l_entry.starts_with ("simple_") or l_entry.same_string ("claude_tools") then
						create l_subdir.make_open_read (l_full_path)
						if l_subdir.exists and then l_subdir.is_readable then
							scan_for_ecf (l_subdir, a_uuid_map)
						end
					end
				end
			end
		end

	scan_for_ecf (a_dir: DIRECTORY; a_uuid_map: HASH_TABLE [ARRAYED_LIST [STRING], STRING])
			-- Scan directory for ECF files and extract UUIDs.
		local
			l_entries: ARRAYED_LIST [STRING_32]
			l_entry: STRING_32
			l_full_path: STRING
			l_uuid: detachable STRING
			l_list: ARRAYED_LIST [STRING]
		do
			create l_entries.make (20)
			across a_dir.entries as ic loop
				l_entries.extend (ic.name.to_string_32)
			end

			across l_entries as ic loop
				l_entry := ic
				if l_entry.ends_with (".ecf") then
					l_full_path := a_dir.path.name.to_string_8 + "\" + l_entry.to_string_8
					l_uuid := extract_uuid (l_full_path)
					if attached l_uuid as u then
						if a_uuid_map.has (u) then
							if attached a_uuid_map.item (u) as existing_list then
								existing_list.extend (l_full_path)
							end
						else
							create l_list.make (2)
							l_list.extend (l_full_path)
							a_uuid_map.put (l_list, u)
						end
					end
				end
			end
		end

	extract_uuid (a_file_path: STRING): detachable STRING
			-- Extract UUID from ECF file.
		local
			l_content: detachable STRING
			l_start, l_end: INTEGER
		do
			l_content := api.read_file (a_file_path)
			if attached l_content as c then
				l_start := c.substring_index ("uuid=%"", 1)
				if l_start > 0 then
					l_start := l_start + 6  -- Skip 'uuid="'
					l_end := c.index_of ('"', l_start)
					if l_end > l_start then
						Result := c.substring (l_start, l_end - 1)
					end
				end
			end
		end

feature {NONE} -- Output

	print_error (a_message: STRING)
		do
			io.error.put_string ("ERROR: " + a_message + "%N")
		end

	print_uuid_usage
		do
			io.put_string ("uuid commands:%N")
			io.put_string ("  uuid scan [<dir>]  - Scan for duplicate UUIDs (default: D:\prod)%N")
			io.put_string ("  uuid fix [<dir>]   - Fix duplicates by generating new UUIDs%N")
		end

feature {NONE} -- Implementation

	api: FOUNDATION_API

end
