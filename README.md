# relx-on-windows

I have had issues getting rebar3 releases / relx to work on Windows.

So this respository is a container for my notes and the apps used for testing.

## Project structure

### rebar3-app

Directory `rebar3-app` created by rebar3

	$ rebar3 new release simple
	$ ren simple rebar3-app

### relx-app

Directory `relx-app` copied from `rebar3-app` removing references to rebar so that **relx** can be tested separately from rebar.

	$ mkdir relx-app
	$ copy rebar3-app\apps relx-app
	$ copy rebar3-app\config relx-app
	$ edit relx-app\relx.config

Relx configuration was extracted from the rebar configuration.
