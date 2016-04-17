@echo off
if not exist "erl_crash.dump" goto skip_erl_crash_dump
del erl_crash.dump
:skip_erl_crash_dump
if not exist "_rel" goto skip_rel
rmdir /q /s _rel
:skip_rel
