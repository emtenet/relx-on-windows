# Issue 5

## Reproduce issue 5

With fixes issues 1 to 4 applied, running:

```
> _rel\simple\bin\simple.cmd console
```

produces `erl_crash.dump` that contains:

```
Slogan: init terminating in do_boot (cannot expand $ERTS_LIB_DIR in bootfile)
```

## Background to issue 5

Boot variables (-boot_var) are used in boot scritps when not all release 
applications are under the one directory ($ROOT/lib). This is what relx needs
when creating a release with {include_erts, false}, the local applications
(including deps) are copied/symlinked into the release directory but the
erlang applications such as kernel and stdlib remain in the erlang installation
directory.

So relx wants to use applications from two places, the release directory and
the erts directory.  The $ROOT variable is built-in so a second variable is 
needed. Should this point to the release directory or the erts directory?

The non-Windows scripts set the ROOTDIR environment variable to the release
directory and this becomes the $ROOT boot variable, so on non-Windows the
second variable ($ERTS_LIB_DIR) needs to point to the erts directory.
This variable is defined in
[rlx_prv_assembler:make_boot_scritp/4](https://github.com/erlware/relx/blob/master/src/rlx_prv_assembler.erl#L528)

The $ERTS_LIB_DIR variable was introduced in
erlware/relx commit 
[f89df2f](https://github.com/erlware/relx/commit/f89df2f4d693c8522fc9b911a6fc5bef31f338fc).
The `bin` and `extended_bin` scripts where updated to provide that variable but
the Windows scripts did not get updated.

So the Windows scripts need to provide a boot variable when they start erl.

A secondary issue exists on Windows systems.
For the case with {include_erts, false} and erlang installed in Program Files
and the erl.ini read-only, there is no way to change the $ROOT variable which
by defaults to the erts directory. So on Windows systems the secondary boot
variable needs to point to the release directory.

## Suggested fixes to issue 5

Add boot variable $RELEALSE_DIR when building the boot script and update
the Windows scripts to provide the variable when starting erlang.

These changes have been made in emtenet/relx branch 
[add-boot-var](https://github.com/emtenet/relx/tree/add-boot-var).

## Actions taken

Issue raised on erlware/relx as [#478](https://github.com/erlware/relx/issues/478).

Pull request submitted to erlware/relx as [#479](https://github.com/erlware/relx/pull/479).