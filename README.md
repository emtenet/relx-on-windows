# relx-on-windows

I have had issues getting rebar3 releases / relx to work on Windows.

So this respository is a container for my notes and the apps used for testing.

## Project structure

### rebar3-app

Directory `rebar3-app` created by rebar3

```
> rebar3 new release simple
> ren simple rebar3-app
```

### relx-app

Directory `relx-app` copied from `rebar3-app` removing references to rebar so that **relx** can be tested separately from rebar.

```
> mkdir relx-app
> copy rebar3-app\apps relx-app
> copy rebar3-app\config relx-app
> edit relx-app\relx.config
```

Relx configuration was extracted from the rebar configuration.

A minimul `compile.cmd` compiles the simple OTP app ready for **relx**.

## Test runs

### Test run #1

Run relx and test the management script

Release is successfuly created:

```
> cd relx-app
> relx
===> Starting relx build process ...
===> Resolving OTP Applications from directories:
          d:/Source/Erlang/relx-on-windows/relx-app/apps
          c:/Program Files/erl7.3/lib
===> Resolved simple-0.1.0
===> Dev mode enabled, release will be symlinked
===> release successfully created!
```

Errors occur asking the management script for usage:

```
> _rel\simple\bin\simple.cmd
FINDSTR: Cannot open d:\Source\Erlang\relx-on-windows\relx-app\_rel\simple\releases\0.1.0\vm.args
FINDSTR: Cannot open d:\Source\Erlang\relx-on-windows\relx-app\_rel\simple\releases\0.1.0\vm.args
The system cannot find the path specified.
The system cannot find the path specified.
The system cannot find the path specified.
The system cannot find the path specified.
usage: simple (install|uninstall|start|stop|restart|upgrade|downgrade|console|ping|list|attach)
```

#### Issue #1

Config files system.config and vm.args are named system.config.orig and vm.args.orig

```
> dir _rel\simple\releases\0.1.0
 Volume in drive D is Data
 Volume Serial Number is 3404-CF8D

 Directory of d:\Source\Erlang\relx-on-windows\relx-app\_rel\simple\releases\0.1.0

15/04/2016  14:02    <DIR>          .
15/04/2016  14:02    <DIR>          ..
15/04/2016  11:36             6,980 simple.boot
15/04/2016  11:36               125 simple.rel
15/04/2016  11:36             8,428 simple.script
15/04/2016  11:36             6,980 start.boot
15/04/2016  11:36             5,332 start_clean.boot
15/04/2016  11:36    <JUNCTION>     sys.config.orig [d:\Source\Erlang\relx-on-windows\relx-app\config\sys.config]
15/04/2016  11:36    <JUNCTION>     vm.args.orig [d:\Source\Erlang\relx-on-windows\relx-app\config\vm.args]
               5 File(s)         27,845 bytes
               4 Dir(s)  448,822,448,128 bytes free
```

This behaviour was added in erlware/relx
[commit 447df92](https://github.com/erlware/relx/commit/447df9204eddb92e3ce8ace581add4e7bba040e1)
"use .orig files to prevent overwriting".

Part of that commit contained an update to the management scripts that renamed these configuration files.

```
@if exist "%possible_sys%".orig (
  ren "%possible_sys%".orig "%possible_sys%" 
  set sys_config=-config "%possible_sys%"
)
@if exist "%rel_dir%\vm.args".orig (
  ren "%rel_dir%\vm.args" ".orig %rel_dir%\vm.args"
)
```

The rename commands have errors in them.

1. FIX: Rename vm.args command prepends `.orig` to second arguement rather than appending to the first argument.

  Replace:
  * `ren` `"%rel_dir%\vm.args"` `".orig %rel_dir%\vm.args"`
  
  with:
  * `ren` `"%rel_dir%\vm.args.orig"` `"%rel_dir%\vm.args"`
  
2. FIX: Windows' `ren` command expects the second argument to be just a file name (not contain drive or path components).

  Replace these:
  * `ren "%possible_sys%".orig "%possible_sys%"`
  * `ren "%rel_dir%\vm.args.orig" "%rel_dir%\vm.args"`

  with these:
  * `ren "%possible_sys%".orig sys.config`
  * `ren "%rel_dir%\vm.args.orig" vm.args`

3. FIX: Tidy up `.orig` appending, include inside double quotes rather than after

  Replace:
  * `@if exist "%possible_sys%".orig (`
  * `  ren "%possible_sys%".orig "%possible_sys%"`

  with:
  * `@if exist "%possible_sys%.orig" (`
  * `  ren "%possible_sys%.orig" "%possible_sys%"`

The renaming was added to 3 out of the 4 script templates `bin`, `bin_windows` & `extended_bin` (in `priv/templates`).
Script template `extended_bin_windows` is missing those rename commands, it is this template that was used in this usage of relx.

4. FIX: Copy the rename commands from `bin_windows` to `extended_bin_windows`

Generate [issue #467](https://github.com/erlware/relx/issues/467)

Add these fixes to GitHub repository emtenet/relx branch [issue-467](https://github.com/emtenet/relx/tree/issue-467)

#### Issue 2

The `The system cannot find the path specified.` errors come from the `:write_ini` section trying to write to `c:\Program\erts-7.3\bin\erl.ini` instead of `C:\Program Files\erl7.3\erts-7.3\bin\erl.ini`

This issue is already raised as [erlware/relx#464](https://github.com/erlware/relx/pull/464)

### Test run #2

#### Issue 3

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

### Test run #4

#### Issue 4

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

### Test run #5

#### Issue 5

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
