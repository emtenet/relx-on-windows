# Issue 1

## Reproduce issue 1

This issue can be reproduced with 
[erlware/relx](https://github.com/erlware/relx)
commit
[1e15397](https://github.com/emtenet/relx/commit/1e15397a4924804f248facc18ccd07076baef7a4)

Bootstrap relx as normal an make the `relx.cmd` and `relx` scripts available in your `PATH`.

Run relx on the sample app, [relx-app](relx-app.md)

```
> cd relx-app
> relx.cmd
===> Starting relx build process ...
===> Resolving OTP Applications from directories:
          d:/Source/Erlang/relx-on-windows/relx-app/apps
          c:/Program Files/erl7.3/lib
===> Resolved simple-0.1.0
===> Dev mode enabled, release will be symlinked
===> release successfully created!
```

Run the release management script:

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

## Symptoms of issue 1

This issue relates to the two error messages:

```
FINDSTR: Cannot open ...\_rel\simple\releases\0.1.0\vm.args
```

## Background of issue 1

Config files `system.config` and `vm.args` are generated in the release folder as
`system.config.orig` and `vm.args.orig`

```
> dir /b _rel\simple\releases\0.1.0
simple.boot
simple.rel
simple.script
start.boot
start_clean.boot
sys.config.orig
vm.args.orig
```

This behaviour was added in erlware/relx commit
[447df92](https://github.com/erlware/relx/commit/447df9204eddb92e3ce8ace581add4e7bba040e1)
"use .orig files to prevent overwriting".

Part of that commit contained an update to the management scripts that 
renamed these configuration files.

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

## Proposed fixes to issue 1

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

   The renaming was added to 3 out of the 4 script templates 
   `bin`, `bin_windows` & `extended_bin` (in `priv/templates`).
   Script template `extended_bin_windows` is missing those rename commands, 
   it is this template that was used in this usage of relx.

4. FIX: Copy the rename commands from `bin_windows` to `extended_bin_windows`

## Actions taken to issue 1

Generate [issue #467](https://github.com/erlware/relx/issues/467)

Add fixes to GitHub repository emtenet/relx branch [issue-467](https://github.com/emtenet/relx/tree/issue-467)
