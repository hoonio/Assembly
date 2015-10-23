@echo off

REM The following lines are needed for sound
pushd v:\ece291\utils\vdms2
dosdrv
popd

REM The following line is needed for ex291
REM Remove the -s if you don't want your project displayed in full-screen mode
ex291 -s

main.exe

