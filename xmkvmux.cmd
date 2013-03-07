@echo off
:: short syntax : xmkvmux.cmd
:: full syntax  : xmkvmux.cmd ["<dir with dir.video.mkv and audio+subs tracks>" [<output muxed file> [<video track file> [<log output file>]]]]
:: shellgen © 2009
setlocal EnableDelayedExpansion
setlocal EnableExtensions
call :getmkvdir "%CD%"
if not [%1]==[] (
SET WDIR=%1
) else (
SET WDIR="%CD%"
)
SET WDIR=%WDIR:^(=^^^(%
SET WDIR=%WDIR:^)=^^^)%
SET WDIR=###%WDIR%###
SET WDIR=%WDIR:"###=%
SET WDIR=%WDIR:###"=%
SET WDIR=%WDIR:###=%###
SET WDIR=%WDIR:\###=%
SET WDIR=%WDIR:###=%
if not [%2]==[] (
SET OUTFILE=%2
) else (
SET OUTFILE="%WDIR%\%MKVDIR%.automux.mkv"
)
if not [%3]==[] (
SET VIDEO=%3
) else (
for %%v in ("%WDIR%\*.video.mkv") do SET VIDEO="%%~v"
)
if not [%4]==[] (
SET MKVLOG=%4
) else (
SET MKVLOG="%WDIR%\%MKVDIR%.mkvmux.log.txt"
)
SET MKVLOG=%MKVLOG:^(=^^^(%
SET MKVLOG=%MKVLOG:^)=^^^)%
SET MKVLOG=###%MKVLOG%###
SET MKVLOG=%MKVLOG:"###=%
SET MKVLOG=%MKVLOG:###"=%
SET MKVLOG=%MKVLOG:###=%
if not exist %VIDEO% (
echo %VIDEO% not found, failed
echo.%VIDEO% not found, failed>>"%MKVLOG%"
goto :eof
)

echo.[%time% %date%] Automux: %WDIR% %OUTFILE% %VIDEO% %MKVLOG%>>"%MKVLOG%"
echo [%time% %date%] Automux: %WDIR% %OUTFILE% %VIDEO% %MKVLOG%
title Automuxing %OUTFILE%...
SET MKVCLI=-o %OUTFILE% -r "%MKVLOG%.tmp" --default-language eng --title "%MKVDIR%"
for %%c in ("%WDIR%\*chapters.xml" "%WDIR%\*chapters.txt") do (
echo.[%time% %date%] chapters found:"%%~c" >> "%MKVLOG%"
echo [%time% %date%] chapters found:"%%~c"
SET MKVCLI=%MKVCLI% --chapters "%%~c"
goto :findtags
)
:findtags
for %%c in ("%WDIR%\*tags.xml") do (
echo.[%time% %date%] tags found:"%%~c" >> "%MKVLOG%"
echo [%time% %date%] tags found:"%%~c"
SET MKVCLI=%MKVCLI% --global-tags "%%~c"
)
if exist "%WDIR%\cover.jpg" (
echo.[%time% %date%] cover found:"%WDIR%\cover.jpg" >> "%MKVLOG%"
echo [%time% %date%] cover found:"%WDIR%\cover.jpg"
SET MKVCLI=%MKVCLI% --attachment-mime-type "image/jpeg" --attachment-name "cover.jpg" --attach-file "%WDIR%\cover.jpg"
)
SET TRACKS=
echo.[%time% %date%] finding audio tracks and evaluating languages and delays...>> "%MKVLOG%"
echo [%time% %date%] finding audio tracks and evaluating languages and delays...
SET X1COUNT=0
for %%a in ("%WDIR%\*.ac3" "%WDIR%\*.dts" "%WDIR%\*.mp4" "%WDIR%\*.mp3" "%WDIR%\*.flac" "%WDIR%\*.wav" "%WDIR%\*.ogg") do (
echo.Track found: %%a>> "%MKVLOG%"
echo Track found: %%a
SET ATRACK=%%~na
SET XTRACK=%%~xa
SET DELAY=
SET LNG=
SET TID=0
SET TRACK="%%~a"
SET TRACKDEFAULT=no
if /i "!XTRACK!" EQU ".mp4" (
SET TID=1
SET TRACK=--no-global-tags --no-chapters !TRACK!
)
call :getdelay "!ATRACK!" !TID!
if not "!DELAY!" EQU "" (
echo.Track delay detected: !DELAY!>> "%MKVLOG%"
echo Track delay detected: !DELAY!
)
call :getlang "!ATRACK!" !TID!
if not "!LNG!" EQU "" (
echo.Track language detected: !LNG!>> "%MKVLOG%"
echo Track language detected: !LNG!
)
SET TRACKS=!TRACKS! !LNG! --default-track !TID!:!TRACKDEFAULT! --compression !TID!:none --track-name !TID!:"!XTRACK:~1! !ATRACK!" !DELAY! !TRACK!
SET /A X1COUNT+=1
)
echo.[%time% %date%] total audio tracks found: !X1COUNT! >> "%MKVLOG%"
echo [%time% %date%] total audio tracks found: !X1COUNT!
echo.[%time% %date%] finding subtitle tracks and evaluating languages and delays...>> "%MKVLOG%"
echo [%time% %date%] finding subtitle tracks and evaluating languages and delays...
SET XCOUNT=0
SET SCOUNT=0
for %%a in ("%WDIR%\*.srt" "%WDIR%\*.ass" "%WDIR%\*.ssa" "%WDIR%\*.idx") do (
echo.Track found: %%a>> "%MKVLOG%"
echo Track found: %%a
SET ATRACK=%%~na
SET XTRACK=%%~xa
SET DELAY=
SET LNG=
SET TID=0
SET TRACK="%%~a"
SET TNAME=!XTRACK:~1! !ATRACK!
echo !ATRACK:~-12! | find "forced" > nul
if not errorlevel 1 (
echo.forced subtitle track detected: %%~a>> "%MKVLOG%"
echo forced subtitle track detected: %%~a
SET TRACK=--forced-track !TID!:yes !TRACK!
)
call :getdelay "!ATRACK!" !TID!
if not "!DELAY!" EQU "" (
echo.Track delay detected: !DELAY!>> "%MKVLOG%"
echo Track delay detected: !DELAY!
)
if /i not "!XTRACK!"==".idx" (
call :getlang "!ATRACK!" !TID!
if not "!LNG!" EQU "" (
echo.Track language detected: !LNG!>> "%MKVLOG%"
echo Track language detected: !LNG!
)
) else (
SET TIND=0
for /f "tokens=2 delims=:," %%t in ('findstr /b /e "id:.*index:.*[0-9]" "%%~a"') do (
SET LID=%%t
if not "!TIND!" EQU "0" (
SET TRACK=--track-name !TIND!:"!XTRACK:~1! !ATRACK! !LID: =!" --default-track !TIND!:no !TRACK!
SET /A SCOUNT+=1
) else (
SET TNAME=!TNAME! !LID: =!
)
SET /A TIND+=1
)
)
SET TRACKS=!TRACKS! !LNG! --track-name !TID!:"!TNAME!" !DELAY! --compression !TID!:none --default-track !TID!:no !TRACK!
SET /A XCOUNT+=1
SET /A SCOUNT+=1
)
echo.[%time% %date%] total subtitle tracks found: !SCOUNT! in !XCOUNT! files>> "%MKVLOG%"
echo [%time% %date%] total subtitle tracks found: !SCOUNT! in !XCOUNT! files
if %X1COUNT%==0 if %XCOUNT%==0 (
echo.[%time% %date%] no subtitle or audio tracks found, skipping mux...>> "%MKVLOG%"
echo [%time% %date%] no subtitle or audio tracks found, skipping mux...
goto :cleanup
)
echo [%time% %date%] merging tracks...
echo.[%time% %date%] merging tracks...>> "%MKVLOG%"
SET MKVCLI=%MKVCLI% --compression 1:none --no-global-tags --no-chapters --no-attachments %VIDEO% %TRACKS%
echo %MKVCLI%
echo.%MKVCLI%>>"%MKVLOG%"
mkvmerge %MKVCLI%
type "%MKVLOG%.tmp"
type "%MKVLOG%.tmp" | findstr /v "Progress:" >> "%MKVLOG%"
del "%MKVLOG%.tmp"
title %OUTFILE% ready =)
:cleanup
if exist langs.txt del langs.txt
exit
goto :eof
:getlang
SET USRLANG=%~1
SET USRLANG=!USRLANG:~-3!
if not exist langs.txt for /f "skip=1 tokens=2 delims=|" %%l in ('mkvmerge --list-languages') do (
set STR=%%l
set STR=!STR: =!
echo.!STR!>>langs.txt
)
SET LNG=
for /f "tokens=1" %%l in ('findstr /i !USRLANG! langs.txt') do (
SET LNG=--language %2:%%l
if /i "%%l" EQU "rus" if not defined DEFAULTCHOSEN (
SET TRACKDEFAULT=yes
SET DEFAULTCHOSEN=yes
)
)
goto :eof
:getmkvdir
set MKVDIR=%~n1
goto :eof
:getdelay
echo.%~1>delaycheck.tmp
for /f "tokens=1-23 delims=. " %%d in ('findstr DELAY delaycheck.tmp') do (
if "%%y" EQU "DELAY" (
SET DELAY=%%z
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%x" EQU "DELAY" (
SET DELAY=%%y
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%w" EQU "DELAY" (
SET DELAY=%%x
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%v" EQU "DELAY" (
SET DELAY=%%w
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%u" EQU "DELAY" (
SET DELAY=%%v
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%t" EQU "DELAY" (
SET DELAY=%%u
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%s" EQU "DELAY" (
SET DELAY=%%t
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%r" EQU "DELAY" (
SET DELAY=%%s
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%q" EQU "DELAY" (
SET DELAY=%%r
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%p" EQU "DELAY" (
SET DELAY=%%q
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%o" EQU "DELAY" (
SET DELAY=%%p
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%n" EQU "DELAY" (
SET DELAY=%%o
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%m" EQU "DELAY" (
SET DELAY=%%n
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%l" EQU "DELAY" (
SET DELAY=%%m
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%k" EQU "DELAY" (
SET DELAY=%%l
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%j" EQU "DELAY" (
SET DELAY=%%k
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%i" EQU "DELAY" (
SET DELAY=%%j
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%h" EQU "DELAY" (
SET DELAY=%%i
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%g" EQU "DELAY" (
SET DELAY=%%h
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%f" EQU "DELAY" (
SET DELAY=%%g
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%e" EQU "DELAY" (
SET DELAY=%%f
SET DELAY=!DELAY:~0,-2!
goto :found
)
if "%%d" EQU "DELAY" (
SET DELAY=%%e
SET DELAY=!DELAY:~0,-2!
goto :found
)
)
:found
if "%DELAY%" EQU "0" (
SET DELAY=
)
if "%DELAY%" EQU "" (
SET DELAY=
) else (
SET DELAY=-y %2:!DELAY!
)
del delaycheck.tmp
goto :eof
