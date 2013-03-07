@echo off
setlocal EnableDelayedExpansion
setlocal EnableExtensions
:: common usage : xcrfmulti.cmd input.avs
:: full syntax  : xcrfmulti.cmd <.avs script for input> <crf if below 51, bitrate otherwise> <number of passes> <x264 preset> <output video file> <SAR> <colormatrix>
:: bitrate for 2nd and following passes is calculated from first if CRFBIT/TARGET value is below 51
:: if invoked without parameters will encode all .avs found in current folder using parameters below
:: shellgen © 2009
color 0f
rem ========== CONFIG =============
SET CRFBIT=18
SET PRESET=placebo
SET TUNE=--psy-rd 1.0:0.0
SET FIRSTSLOW=--slow-firstpass
SET PASSES=2
SET BFRAMES=-b 6
SET REFFRAMES=-r 9
SET DEBLOCK=-f -2,-1
SET SAR=1:1
SET CM=bt709
SET VBV=--vbv-maxrate 50000 --vbv-bufsize 62500
SET XCONFIG=%BFRAMES% %REFFRAMES% %DEBLOCK% -A p8x8,b8x8,i8x8,i4x4 --me umh --merange 18 --b-pyramid normal --qcomp 0.65 --aq-mode 2 --aq-strength 1.0 --psnr --ssim
SET BIN=.
SET X264x64="%BIN%\x264.1698kMod.generic.x86_64.exe"
SET X264="%BIN%\x264.1698kMod.generic.x86.exe"
SET AVS2YUV="%BIN%\avs2yuv.exe"
rem ======== END CONFIG ===========
if [%1]==[] goto selfparam
call :getwdir %1
cd /d "%WORKDIR%"
SET FLOG="%WORKDIR%%~n1.final.xlog.txt"
call :xcrfmulti %1 %2 %3 %4 %5 %6 %7 %8 %9
for %%l in ("%WORKDIR%*.pass*.*.log.txt") do (
type "%%~l"
type "%%~l" >> %FLOG%
del "%%~l")
endlocal
rem exit
goto :eof
:selfparam
for %%m in (*.avs) do (
echo [%time% %date%] encoding %%m
call :getwdir %%m
call :xcrfmulti %%m
for %%l in ("%WORKDIR%*.pass*.*.log.txt") do (
type "%%~l"
type "%%~l" >> "%%~nm.final.xlog.txt"
del "%%~l"
)
echo [%time% %date%] done
)
echo all done
echo.
color 07
endlocal
rem exit
goto :eof
:xcrfmulti
ver>>%FLOG%
echo.CPUs: %NUMBER_OF_PROCESSORS% >>%FLOG%
echo.CPU Architecture: %PROCESSOR_ARCHITECTURE% >>%FLOG%
echo.CPU ID:%PROCESSOR_IDENTIFIER% >>%FLOG%
echo.CPU Level: %PROCESSOR_LEVEL% >>%FLOG%
echo.CPU Rev.: %PROCESSOR_REVISION% >>%FLOG%
echo.OS: %OS%>>%FLOG%
echo.PATH=%Path%>>%FLOG%
SET FINALOUT=
if not [%2]==[] SET CRFBIT=%2
if not [%3]==[] SET PASSES=%3
if not [%4]==[] SET PRESET=%4
if not [%5]==[] (
SET FINALOUT=%5
:: Uncomment 6 lines below in case you need to fetch full paths containing brackets
rem SET FINALOUT=%FINALOUT:^(=^^^(%
rem SET FINALOUT=%FINALOUT:^)=^^^)%
rem SET FINALOUT=###%FINALOUT%###
rem SET FINALOUT=%FINALOUT:"###=%
rem SET FINALOUT=%FINALOUT:###"=%
rem SET FINALOUT=%FINALOUT:###=%
) else (
SET FINALOUT=%~1.%CRFBIT%.%PASSES%pass.%PRESET%.mkv
)
echo !FINALOUT!
if "%FINALOUT%"=="" (
SET FINALOUT="%~1.%CRFBIT%.%PASSES%pass.%PRESET%.mkv"
)
echo !FINALOUT!
if not [%6]==[] SET SAR=%6
if not [%7]==[] SET CM=%7
SET PASS=1
:_nxt_pass
if %PASS% GTR %PASSES% goto :eof
set STARTTIME=%time%
set STARTDATE=%date%
SET FIRST=
SET _VBV=
set CRFON=no
if %PASS%==1 (
if %PASS%==%PASSES% (
set FIRST=--slow-firstpass
) else (
set FIRST=%FIRSTSLOW%
)
set _p=%PASS%
if %CRFBIT% LEQ 50 (
set BITCONTROL=--crf %CRFBIT%
set CRFON=yes
set FIRST=--slow-firstpass
) else (set BITCONTROL=-B %CRFBIT%)
) else (
set _VBV=%VBV%
set BITCONTROL=-B %CRFBIT%
set _p=3
)
SET LOGFILE=".\%~n1.pass%PASS%.%CRFBIT%.log.txt"
SET XLOGFILE=".\%~n1.pass%PASS%.%CRFBIT%.xlog.txt"
SET OUTFILE=".\%~n1.pass%PASS%.%CRFBIT%.264"
if "%PASS%" EQU "%PASSES%" if not "%FINALOUT%"=="" SET OUTFILE="%FINALOUT%"
echo [%STARTTIME% %STARTDATE%] Encoding %1 : pass %PASS% of %PASSES% at %BITCONTROL%>> %LOGFILE%
echo [%STARTTIME% %STARTDATE%] Encoding %1 : pass %PASS% of %PASSES% at %BITCONTROL%
SET XCLI=%BITCONTROL% -p %_p% --stats "%WORKDIR%%~n1.crfmulti.stats" --preset %PRESET% %TUNE% %FIRST% %XCONFIG% %_VBV% --sar %SAR% --colormatrix "%CM%" -o %OUTFILE%
echo %XCLI%
echo.%XCLI% >> %LOGFILE%
if exist ".\logs\%~n1.pass%PASS%.%CRFBIT%.xlog.txt" (
for /F "tokens=*" %%L in ('findstr /i encoded ".\logs\%~n1.pass%PASS%.%CRFBIT%.xlog.txt"') do (
set DONE=%%L
if "%PASS%" EQU "%PASSES%" if not exist %OUTFILE% (
goto :arcdetect
)
echo %~n1.pass%PASS%.%CRFBIT% most probably was encoded earlier, skipping this pass...
echo (delete "%WORKDIR%logs\%~n1.pass%PASS%.%CRFBIT%.xlog.txt" to disable skipping this pass)
echo [%time% %date%] %OUTFILE% already exists, probably encoded earlier, skipping this pass.. >> %LOGFILE%
if "%CRFON%" EQU "yes" for /F "tokens=7 delims=. " %%B in ('findstr encoded ".\logs\%~n1.pass%PASS%.%CRFBIT%.xlog.txt"') do set CRFBIT=%%B
goto :_skipencode
)
)
for %%s in (".\logs\%~n1.pass%PASS%.*.xlog.txt") do (
SET PRLOG=%%s
if exist !PRLOG! (
for /F "tokens=7 delims=. " %%B in ('findstr encoded "%%~s"') do (
set DONE=%%B
echo %~n1.pass%PASS%.%CRFBIT% most probably was encoded earlier, skipping this pass...
echo (delete "!PRLOG!" to disable skipping this pass)
echo [%time% %date%] "%~n1.pass%PASS%.%CRFBIT% already exists, probably encoded earlier, skipping this pass.. >> %LOGFILE%
goto :_skipencode
)
)
)
:arcdetect
if DEFINED PROCESSOR_ARCHITEW6432 goto x64
if DEFINED ProgramW6432 goto x64
if DEFINED COMMONPROGRAMW6432 goto x64
if DEFINED CommonProgramFiles(x86) goto x64
if DEFINED ProgramFiles(x86) goto x64
goto x86
:x64
echo 64bit OS detected: %PROCESSOR_ARCHITECTURE% %PROCESSOR_ARCHITEW6432%
echo 64bit OS detected: %PROCESSOR_ARCHITECTURE% %PROCESSOR_ARCHITEW6432% >> %LOGFILE%
%AVS2YUV% "%~1" - 2>> %LOGFILE% | %X264x64% %XCLI% --demuxer y4m - 2>> %XLOGFILE%
for /F "tokens=*" %%L in ('findstr /i /l "yuv4mpeg" %XLOGFILE%') do (echo.%%L>> %LOGFILE%)
for /F "tokens=*" %%L in ('findstr /i /l "y4m" %XLOGFILE%') do (echo.%%L>> %LOGFILE%)
for /F "tokens=2* delims=[" %%L in ('findstr /l /c:"frame I:" %XLOGFILE%') do (echo.x264 [%%L)
goto _pass_finalize
:x86
echo 32bit OS detected: %PROCESSOR_ARCHITECTURE%
echo 32bit OS detected: %PROCESSOR_ARCHITECTURE% >> %LOGFILE%
%X264% %XCLI% "%~1" 2>> %XLOGFILE%
for /F "tokens=*" %%L in ('findstr /i /l "avis" %XLOGFILE%') do (echo.%%L>> %LOGFILE%)
for /F "tokens=*" %%L in ('findstr /i /b /l "avs" %XLOGFILE%') do (echo.%%L>> %LOGFILE%)
for /F "tokens=2* delims=x" %%L in ('findstr /l /c:"frame I:" %XLOGFILE%') do (echo.x%%L
echo.x%%L>> %LOGFILE%)
:_pass_finalize
set ENDTIME=%time%
set ENDDATE=%date%
set DONE=failure
for /F "tokens=2* delims=[" %%L in ('findstr /i /l /c:"x264 [info]:" %XLOGFILE%') do (echo.x264 [%%L>> %LOGFILE%)
for /F "tokens=2* delims=[" %%L in ('findstr /i /l /c:"x264 [error]:" %XLOGFILE%') do (echo.x264 [%%L>> %LOGFILE%)
for /F "tokens=*" %%L in ('findstr /i encoded %XLOGFILE%') do set DONE=%%L
for /F "tokens=*" %%L in ('findstr /l /c:"frame P:" %XLOGFILE%') do (echo %%L)
for /F "tokens=*" %%L in ('findstr /l /c:"frame B:" %XLOGFILE%') do (echo %%L)
for /F "tokens=*" %%L in ('findstr /l /c:"SSIM Mean" %XLOGFILE%') do (echo %%L)
set STARTTIME=%time%
set STARTDATE=%date%
if "%CRFON%" EQU "yes" for /F "tokens=7 delims=. " %%B in ('findstr encoded %XLOGFILE%') do set CRFBIT=%%B
mkdir "%WORKDIR%logs" 2> nul > nul
move /y %XLOGFILE% "%WORKDIR%logs\%~n1.pass%PASS%.%CRFBIT%.xlog.txt" > nul
:_skipencode
echo [%ENDTIME% %ENDDATE%] ======== %DONE%
echo.[%ENDTIME% %ENDDATE%] ======== %DONE% ======== >> %LOGFILE%
set /A PASS+=1
goto _nxt_pass
goto :eof
:getwdir
SET WORKDIR="%~dp1"
SET WORKDIR=%WORKDIR:^(=^^^(%
SET WORKDIR=%WORKDIR:^)=^^^)%
SET WORKDIR=###%WORKDIR%###
SET WORKDIR=%WORKDIR:"###=%
SET WORKDIR=%WORKDIR:###"=%
SET WORKDIR=%WORKDIR:###=%
SET WORKDIR=%WORKDIR%###
SET WORKDIR=%WORKDIR:\###=%
SET WORKDIR=%WORKDIR:###=%\
goto :eof
