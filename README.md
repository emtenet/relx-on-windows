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

## [Issue 3](issue-3.md)

Issue 3 relates to modifications of the system installed erlang file `erl.ini`
being `Access is denied.`

## [Issue 4](issue-4.md)

Issue 4 relates to the correct symlinks being created for files vs folders.

## [Issue 5](issue-5.md)

Issue 5 relates to the $ERTS_LIB_DIR boot variable not being provided by the
windows management scripts.

## TODO

1. [Issue 4](issue-4.md) -
   In my opinion, *hard links* are not visible on Windows through the 
   command line or Windows explorer.

   For this reason I would suggest fix option 1 as the best option.
   NOTE: [Avoiding the issue](#avoiding-issue-3)
   and using *symbolic links* gives the best *visibility*.

2. The code in [Issue 4](issue-4.md) may need to be revised in future issues
   relating to the re-creation of a release and associated symlinks.

   The two future issues are:

   1. Re-creating a symlink results in a *aleady exists* error.

   2. Ignoring the *already exists* error when the {vm_args, _} configuration
      has changed may result in a *stale* link to the *wrong* file.

