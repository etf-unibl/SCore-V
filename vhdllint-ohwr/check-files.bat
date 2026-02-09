@echo off

set ARGS=

for /r %2\%1 %%x in (*.vhd) do call set "ARGS=%%ARGS%% %%x"

vhdllint-ohwr %ARGS%
