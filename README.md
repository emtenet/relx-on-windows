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
