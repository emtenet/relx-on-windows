{application, simple,
 [{description, "An OTP application"},
  {vsn, "0.1.0"},
  {registered, []},
  {mod, { simple_app, []}},
  {applications,
   [kernel,
    stdlib
   ]},
  {env,[]},
  {modules, [simple_app, simple_sup]},
  {maintainers, []},
  {licenses, []},
  {links, []}
 ]}.
