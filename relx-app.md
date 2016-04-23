# Sample applications for testing

The following sample applications have been made to test the `rebar` and `relx` tools.

## rebar3-app

Directory `rebar3-app` created by rebar3

```
> rebar3 new release simple
> ren simple rebar3-app
```

## relx-app

Directory `relx-app` copied from `rebar3-app` removing references to `rebar` so that `relx` can be tested separately from `rebar`.

```
> mkdir relx-app
> copy rebar3-app\apps relx-app
> copy rebar3-app\config relx-app
> edit relx-app\relx.config
```

`relx` configuration was extracted from the `rebar` configuration.

A minimul `compile.cmd` compiles the simple OTP app ready for `relx`.
