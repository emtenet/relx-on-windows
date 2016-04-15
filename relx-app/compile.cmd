@echo off
erlc -o apps\simple\ebin apps\simple\src\simple_app.erl
erlc -o apps\simple\ebin apps\simple\src\simple_sup.erl