# relx-on-windows

I have had issues getting rebar3 releases / relx to work on Windows.

So this respository is a container for my notes and the apps used for testing.

## [Sample applications](relx-app.md)

Two sample applications, rebar-app and relx-app,
have been made for testing the `rebar` and `relx` commands.

## [Issue 1](issue-1.md)

Issue 1 relates to the generation and renaming of configuration 
files (`sys.config` and `vm.args`) with the `.orig` extension.

## [Issue 2](issue-2.md)

Issue 2 relates to erts path discovery on Windows.

## Issue 3

Running the test again:

```
> _rel\simple\bin\simple.cmd
Access is denied.
Access is denied.
Access is denied.
Access is denied.
usage: simple (install|uninstall|start|stop|restart|upgrade|downgrade|console|ping|list|attach)
```

The `Access is denied.` errors come from the `:write_ini` section trying to write to `C:\Program Files\erl7.3\erts-7.3\bin\erl.ini`

Windows 10 (and earlier?) locks down modifications to `Program Files` requiring 'run as Administrator'

This issue arrises when {include_erts, false} but the erl.ini file should not need to be modifed. When {include_erts, true} the script should have modification rights and updating the ini file may be necessary if the release directory structure is moved.

So, how to disable :write_ini when {include_erts, false}?

FIX: only :write_ini if the erts_dir is found within the release dir.

Or the inverse; in :set_erts_dir_from_erl set skip_write_ini=yes, then use that to skip the :write_ini section.

Add these fixes to GitHub repository emtenet/relx branch [skip-write-ini](https://github.com/emtenet/relx/tree/skip-write-ini)

## Issue 4

Nothing happens when you run `simple.cmd console`, not even a erl_crash.dump

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

Another test:

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

Reading [MSDN Hard Links and Junctions](https://msdn.microsoft.com/en-au/library/windows/desktop/aa365006(v=vs.85).aspx) suggests junctions are only useable for folders, not files.

The junction is made in rlx_util:win32_symlink by

```
"cmd /c mklink /j " ++ Target ++ " " ++ Source
```

Testing mklink's options with `issue-4\issue-4.cmd`:

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

Only option "/H" generates the target file and allows reading from that file.

Opdate `rlx_util.erl` to use different `mklink` options for files and folders.

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

## Issue 5

With issues 1 to 4 wrapped up in emtenet/relx branch [windows-friendly](https://github.com/emtenet/relx/tree/windows-friendly) run:

```
> _rel\simple\bin\simple.cmd console
```

which produces `erl_crash.dump` that contains:

```
Slogan: init terminating in do_boot (cannot expand $ERTS_LIB_DIR in bootfile)
```

Commit [f89df2f](https://github.com/erlware/relx/commit/f89df2f4d693c8522fc9b911a6fc5bef31f338fc) added a boot variable ERTS_LIB_DIR with updates to `bin` and `extended_bin` scripts to provide that variable. The Windows scripts did not include those updates.

Add boot variable to Windows scripts in emtenet/relx branch [add-boot-var](https://github.com/emtenet/relx/tree/add-boot-var)
