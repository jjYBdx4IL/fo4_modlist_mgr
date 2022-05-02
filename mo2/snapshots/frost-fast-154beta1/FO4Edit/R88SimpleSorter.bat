@echo off

set hasXedit=0
set hasR88Script=0
set hasMXPF==0
set hasMTEFunctions==0
set hasRequiredFiles==0

IF EXIST "FO4Edit.exe" set hasXedit=1
IF EXIST "Edit Scripts\R88_SimpleSorter.pas" set hasR88Script=1
IF EXIST "Edit Scripts\lib\mxpf.pas" set hasMXPF=1
IF EXIST "Edit Scripts\lib\mteFunctions.pas" set hasMTEFunctions=1

echo::: "Ruddy88's Simple Sorter"
echo :
echo :
echo ::: Checking for required files :::
echo :

IF %hasXedit%==1 (
  echo : FO4Edit found
) ELSE (
    echo : WARNING: FO4Edit.exe not found
)
IF %hasR88Script%==1 (
    echo : R88_SimpleSorter.pas found
) ELSE (
    echo : WARNING: R88SimpleSorter.pas not found
)
IF %hasMXPF%==1 (
    echo : mxpf.pas found
) ELSE (
    echo : WARNING: mxpf.pas not found
)
IF %hasMTEFunctions%==1 (
    echo : mteFunctions.pas found
) ELSE (
    echo : WARNING: mteFunctions.pas not found
)

IF %hasXedit%==1 IF %hasR88Script%==1 IF %hasMXPF%==1 IF %hasMTEFunctions%==1 set hasRequiredFiles=1
IF %hasRequiredFiles%==1 (
    echo :
    echo :
) ELSE (
    echo :
    echo :
    echo : Required files not found. Terminating process.
    echo :
    echo :
    pause
    exit
)


:runPatch
.\FO4Edit.exe -D:"..\Fallout 4\Data" -nobuildrefs -script:"R88_SimpleSorter.pas"

del *_log.txt

:exitPatch
exit


