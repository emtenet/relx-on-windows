# Issue 3

## Reproduce issue 3

Issue 3 is reproduced with the same steps as [Issue 2](issue-2.md) 
with fixes applied.

```
> _rel\simple\bin\simple.cmd
Access is denied.
Access is denied.
Access is denied.
Access is denied.
usage: simple (install|uninstall|start|stop|restart|upgrade|downgrade|console|ping|list|attach)
```

## Symptoms of issue 3

Issue 3 relates to the errors `Access is denied.`

## Background to issue 3

These errors come from the `:write_ini` section of the management script 
trying to write to `C:\Program Files\erl7.3\erts-7.3\bin\erl.ini`

Windows 10 (and earlier?) locks down modifications to `Program Files` 
requiring *Run as Administrator*.

The `erl.ini` file is being modified for when the release folder is moved or
installed on a system in a different location than generated.
When the release folder is moved the `erl.ini` files contents need to be 
modified to match the new location.

This issue occurs when `{include_erts, false}` and the system installed erlang
is used. But in that case the erts folder will not move and there is no need
to modify the `erl.ini` file.
In the mirror case with `{include_erts, true}`, the script will have modification 
rights to the local copy of the erts folder and there will be no issue 
modifying the ini file.

So, only the case with `{include_erts, false}` needs to be fixed.

## Proposed fixes to issue 3

Detect when the `erts_dir` is found from the system installed erlang and
skip the `:write_ini` section.

## Actions taken to issue 3

Add these fixes to GitHub repository emtenet/relx branch 
[skip-write-ini](https://github.com/emtenet/relx/tree/skip-write-ini).
