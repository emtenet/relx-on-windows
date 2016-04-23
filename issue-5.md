# Issue 5

## Reproduce issue 1

With fixes issues 1 to 4 applied, running:

```
> _rel\simple\bin\simple.cmd console
```

produces `erl_crash.dump` that contains:

```
Slogan: init terminating in do_boot (cannot expand $ERTS_LIB_DIR in bootfile)
```

## Background to issue 5

## Suggested fixes to issue 5

Commit [f89df2f](https://github.com/erlware/relx/commit/f89df2f4d693c8522fc9b911a6fc5bef31f338fc) added a boot variable ERTS_LIB_DIR with updates to `bin` and `extended_bin` scripts to provide that variable. The Windows scripts did not include those updates.

Add boot variable to Windows scripts in emtenet/relx branch [add-boot-var](https://github.com/emtenet/relx/tree/add-boot-var)
