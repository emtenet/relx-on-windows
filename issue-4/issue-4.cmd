@echo off

if exist source rmdir /q /s source
mkdir source
echo source > source\file.txt

if exist target rmdir /q /s target
mkdir target

call :test no-option
call :test option-d /D
call :test option-h /H
call :test option-j /J

@echo == TARGET ==
dir target
goto :EOF

:test
echo == TEST %1 ==
echo.
echo - Linking to "target\%1.txt" with option "%2"
mklink %2 target\%1.txt source\file.txt
echo.
echo - Typing "target\%1.txt"
type target\%1.txt
echo.
goto :EOF

