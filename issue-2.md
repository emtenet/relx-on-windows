# Issue 2

## Reproduce issue 1

Issue 2 is reproduce with the same steps as [Issue 1](issue-1.md) 
with fixes applied.

```
> _rel\simple\bin\simple.cmd
The system cannot find the path specified.
The system cannot find the path specified.
The system cannot find the path specified.
The system cannot find the path specified.
usage: simple (install|uninstall|start|stop|restart|upgrade|downgrade|console|ping|list|attach)
```

## Symptoms of issue 2

Issue 2 relates to the errors `The system cannot find the path specified.`

## Existing fix to issue 2

This issue is already raised as erlware/relx pull request 
[#464](https://github.com/erlware/relx/pull/464).
