# Issue 4

## Reproduce issue 4

With fixes to issues 1..3 applied running the manage script as:

```
> _rel\simple\bin\simple.cmd console
```

Nothing happens!! Not even a erl_crash.dump

## Trouble shooting issue 4

Replacing:

```
@start "%rel_name% console" %werl% -boot "%boot_script%" %sys_config% -args_file "%vm_args%"
```

with:

```
@erl.exe -boot "%boot_script%" %sys_config% -args_file "%vm_args%"
```

results in:

```
d:\Source\Erlang\relx-on-windows\relx-app>_rel\simple\bin\simple.cmd console
Failed to open arguments file "d:\Source\Erlang\relx-on-windows\relx-app\_rel\simple\releases\0.1.0\vm.args": Permission denied
Usage: erl [-version] [-sname NAME | -name NAME] [-noshell] [-noinput] [-env VAR VALUE] [-compile file ...] [-start_erl [datafile]] [-smp [enable|auto|disable]] [-make] [-man [manopts] MANPAGE] [-x] [-emu_args] [-args_file FILENAME] [+A THREADS] [+a SIZE] [+B[c|d|i]] [+c [BOOLEAN]] [+C MODE] [+h HEAP_SIZE_OPTION] [+K BOOLEAN] [+l] [+M<SUBSWITCH> <ARGUMENT>] [+P MAX_PROCS] [+Q MAX_PORTS] [+R COMPAT_REL] [+r] [+rg READER_GROUPS_LIMIT] [+s SCHEDULER_OPTION] [+S NO_SCHEDULERS:NO_SCHEDULERS_ONLINE] [+SP PERCENTAGE_SCHEDULERS:PERCENTAGE_SCHEDULERS_ONLINE] [+TLEVEL] [+V] [+v] [+W<i|w|e>] [+z MISC_OPTION] [args ...]
```

Testing access to vm.args finds the problem:

```
> type config\vm.args
-sname simple

-setcookie simple_cookie

+K true
+A30
> dir _rel\simple\releases\0.1.0\vm.*
15/04/2016  15:57    <JUNCTION>     vm.args [d:\Source\Erlang\relx-on-windows\relx-app\config\vm.args]
> type _rel\simple\releases\0.1.0\vm.args
Access is denied.
```

The `vm.args` file is not accessable via the JUNCTION.

## Background to issue 4

Reading 
[MSDN Hard Links and Junctions](https://msdn.microsoft.com/en-au/library/windows/desktop/aa365006(v=vs.85).aspx)
suggests junctions should only be used for folders, not files.

The junction is made in rlx_util:win32_symlink/2 by

```
"cmd /c mklink /j " ++ Target ++ " " ++ Source
```

Testing mklink's options with [issue-4\issue-4.cmd]():

```
> cd issue-4
> issue-4.cmd
== TEST no-option ==

- Linking to "target\no-option.txt" with option ""
You do not have sufficient privilege to perform this operation.

- Typing "target\no-option.txt"
The system cannot find the file specified.

== TEST option-d ==

- Linking to "target\option-d.txt" with option "/D"
You do not have sufficient privilege to perform this operation.

- Typing "target\option-d.txt"
The system cannot find the file specified.

== TEST option-h ==

- Linking to "target\option-h.txt" with option "/H"
Hardlink created for target\option-h.txt <<===>> source\file.txt

- Typing "target\option-h.txt"
source

== TEST option-j ==

- Linking to "target\option-j.txt" with option "/J"
Junction created for target\option-j.txt <<===>> source\file.txt

- Typing "target\option-j.txt"
Access is denied.

== TARGET ==
 Volume in drive D is Data
 Volume Serial Number is 3404-CF8D

 Directory of d:\Source\Erlang\relx-on-windows\issue-4\target

15/04/2016  18:50    <DIR>          .
15/04/2016  18:50    <DIR>          ..
15/04/2016  18:50                 9 option-h.txt
15/04/2016  18:50    <JUNCTION>     option-j.txt [d:\Source\Erlang\relx-on-windows\issue-4\source\file.txt]
               1 File(s)              9 bytes
               3 Dir(s)  447,872,917,504 bytes free
```

Symbolic links (with no option or option /D) result in
`You do not have sufficient privilege to perform this operation.`
which documentation for
[file:make_symlink/2](http://erlang.org/doc/man/file.html#make_symlink-2)
describes as `eperm` 
"User does not have privileges to create symbolic links (SeCreateSymbolicLinkPrivilege on Windows)"

Option "/H" generates the target file as a hark link and allows reading from 
that file.

## Avoiding issue 4

This issue can be avoided by setting up Windows with a user account not in 
the *Administrators* group and giving *SeCreateSymbolicLinkPrivilege*.

Part of my exploration of this alternative resulted in
[emtenet/local-security-policy](https://github.com/emtenet/local-security-policy).

## Suggested fixes to issue 4

There are two options to fixing this issue:

1. Create a hard link in `win32_symlink/2` when the source is a file.
2. Copy the source file rather than creating a symlink

Both options rely on detecting the type of the source in
`rlx_util:symlink_or_copy/2` or `rlx_util:win32_symlink/2`.

Fixing by option 1 results in the following update to `rlx_util.erl`:

```
win32_symlink(Source, Target) ->
    win32_symlink_for_type(Source, Target, file:read_file_info(Source)).

win32_symlink_for_type(Source, Target, {ok, #file_info{type = regular}}) ->
    os:cmd("cmd /c mklink /h " ++ Target ++ " " ++ Source),
    ok;
win32_symlink_for_type(Source, Target, {ok, #file_info{type = directory}}) ->
    os:cmd("cmd /c mklink /j " ++ Target ++ " " ++ Source),
    ok.
```

## Actions taken to issue 4

The suggested fix was implemented in emtenet/relx branch 
[win32-include_erts-false](https://github.com/emtenet/relx/tree/win32-include_erts-false).
