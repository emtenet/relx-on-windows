
-include_lib("kernel/include/file.hrl").

main(_) ->
	remove_folder("source"),
	remove_folder("target"),
	ok = file:make_dir("source"),
	ok = file:write_file("source\\file", file_contents()),
	ok = file:make_dir("source\\folder"),
	ok = file:write_file("source\\folder\\inside", inside_contents()),
	ok = file:make_dir("target"),
	ok = win32_symlink("source\\file", "target\\file"),
	ok = win32_symlink("source\\folder", "target\\folder"),
	assert_folder("source", ["file", "folder"]),
	assert_file("source\\file", file_contents()),
	assert_folder("source\\folder", ["inside"]),
	assert_file("source\\folder\\inside", inside_contents()),
	ok.

assert_file(File, Contents) ->
	{ok, Contents} = file:read_file(File).

assert_folder(Folder, List) ->
	{ok, List} = file:list_dir(Folder).

file_contents() ->
	<<"file_contents">>.

inside_contents() ->
	<<"inside_contents">>.

remove_folder(Folder) ->
	remove_folder_if(Folder, file:read_file_info(Folder)).

remove_folder_if(_, {error, enoent}) ->
	ok;
remove_folder_if(Folder, {ok, #file_info{type = directory}}) ->
	os:cmd("cmd /c rmdir /q /s " ++ Folder),
	ok.

win32_symlink(Source, Target) ->
    win32_symlink_for_type(Source, Target, file:read_file_info(Source)).

win32_symlink_for_type(Source, Target, {ok, #file_info{type = regular}}) ->
    os:cmd("cmd /c mklink /h " ++ Target ++ " " ++ Source),
    ok;
win32_symlink_for_type(Source, Target, {ok, #file_info{type = directory}}) ->
    os:cmd("cmd /c mklink /j " ++ Target ++ " " ++ Source),
    ok.
