@echo off
mode con cols=80 lines=40
title Batch CIA 3DS CCI Decryptor
SetLocal EnableDelayedExpansion
echo %date% %time% >log.txt 2>&1
echo Decrypting and analyzing size reduction...
echo.

:: VARIABLE INITIALIZATION AND CLEANUP
if not exist "decrypted" mkdir "decrypted"
if exist stats.tmp del stats.tmp >nul 2>&1
set /a TOTAL_PROCESSED=0

:: PRE-PROCESSING: Temporarily rename .cci to .cci.3ds
for %%a in (*.cci) do ren "%%a" "%%a.3ds"

for %%a in (*.ncch) do del "%%a" >nul 2>&1

:: --- LOOP 1: .3DS and .CCI GAMES ---
for %%a in (*.3ds) do (
    set "FULLNAME=%%~na"
    set "IS_CCI=0"
    if /i "!FULLNAME:~-4!"==".cci" (
        set "IS_CCI=1"
        set "CUTN=!FULLNAME:~0,-4!"
        set "OUT_EXT=.cci"
    ) else (
        set "CUTN=!FULLNAME!"
        set "OUT_EXT=.3ds"
    )

    :: REMOVED THE "IF DECRYPTED" CHECK HERE
    echo Processing: !CUTN!
    echo | decrypt "%%a" >>log.txt 2>&1
    set ARG=
    for %%f in ("!FULLNAME!.*.ncch") do (
        if %%f==!FULLNAME!.Main.ncch set i=0
        if %%f==!FULLNAME!.Manual.ncch set i=1
        if %%f==!FULLNAME!.DownloadPlay.ncch set i=2
        if %%f==!FULLNAME!.Partition4.ncch set i=3
        if %%f==!FULLNAME!.Partition5.ncch set i=4
        if %%f==!FULLNAME!.Partition6.ncch set i=5
        if %%f==!FULLNAME!.N3DSUpdateData.ncch set i=6
        if %%f==!FULLNAME!.UpdateData.ncch set i=7
        set ARG=!ARG! -i "%%f:!i!:!i!"
    )
    
    set "OUT_FILE=decrypted\!CUTN!!OUT_EXT!"
    makerom -f cci -ignoresign -target p -o "!OUT_FILE!"!ARG! >>log.txt 2>&1
    
    :: CALCULATE STATISTICS
    set /a TOTAL_PROCESSED+=1
    call :CALC_STATS "%%a" "!OUT_FILE!"
    echo.
)

:: CLEANUP CCI NAMES
for %%a in (*.cci.3ds) do ren "%%a" "%%~na"

:: --- LOOP 2: CIA (Content Extraction) ---
for %%a in (*.cia) do (
    set CUTN=%%~na
    
    :: REMOVED THE "IF DECRYPTED" CHECK HERE
    ctrtool -tmd "%%a" >content.txt
    set FILE="content.txt"
    set /a i=0
    set ARG=
    
    :: STANDARD CIA GAMES
    findstr /pr "^T.*D.*00040000" !FILE! >nul
    if not errorlevel 1 (
        echo Processing CIA: !CUTN!
        echo | decrypt "%%a" >>log.txt 2>&1
        for %%f in ("!CUTN!.*.ncch") do (
            set ARG=!ARG! -i "%%f:!i!:!i!"
            set /a i+=1
        )
        makerom -f cia -ignoresign -target p -o "!CUTN!-decfirst.cia"!ARG! >>log.txt 2>&1
    )

    :: PATCH AND DLC
    findstr /pr "^T.*D.*0004000E ^T.*D.*0004008C" !FILE! >nul
    if not errorlevel 1 (
        set TEXT="Content id"
        set /a X=0
        echo | decrypt "%%a" >>log.txt 2>&1
        for %%h in ("!CUTN!.*.ncch") do (
            set NCCHN=%%~nh
            set /a n=!NCCHN:%%~na.=!
            if !n! gtr !X! set /a X=!n!
        )
        for /f "delims=" %%d in ('findstr /c:!TEXT! !FILE!') do (
            set CONLINE=%%d
            call :EXF
        )
        
        findstr /pr "^T.*D.*0004000E" !FILE! >nul
        if not errorlevel 1 (
            echo Processing Patch: !CUTN!
            set "OUT_FILE=decrypted\!CUTN! (Patch).cia"
            makerom -f cia -ignoresign -target p -o "!OUT_FILE!"!ARG! >>log.txt 2>&1
            set /a TOTAL_PROCESSED+=1
            call :CALC_STATS "%%a" "!OUT_FILE!"
            echo.
        )
        
        findstr /pr "^T.*D.*0004008C" !FILE! >nul
        if not errorlevel 1 (
            echo Processing DLC: !CUTN!
            set "OUT_FILE=decrypted\!CUTN! (DLC).cia"
            makerom -f cia -dlc -ignoresign -target p -o "!OUT_FILE!"!ARG! >>log.txt 2>&1
            set /a TOTAL_PROCESSED+=1
            call :CALC_STATS "%%a" "!OUT_FILE!"
            echo.
        )
    )
)
if exist content.txt del content.txt >nul 2>&1

:: --- LOOP 3: FINAL CONVERSION CIA -> CCI ---
for %%a in (*-decfirst.cia) do (
    set CUTN=%%~na
    echo Converting to CCI: !CUTN:-decfirst=!
    set "OUT_FILE=decrypted\!CUTN:-decfirst=!.cci"
    makerom -ciatocci "%%a" -o "!OUT_FILE!" >>log.txt 2>&1
    
    :: Compare intermediate CIA with final CCI
    set /a TOTAL_PROCESSED+=1
    call :CALC_STATS "%%a" "!OUT_FILE!"
    echo.
)

for %%a in (*-decfirst.cia) do del "%%a" >nul 2>&1
for %%a in (*.ncch) do del "%%a" >nul 2>&1

:: OVERALL FINAL STATISTICS SECTION
echo ======================================================
echo  FINISHED!
echo  Files are located in the "decrypted" folder.

if !TOTAL_PROCESSED! gtr 1 (
    if exist stats.tmp (
        echo.
        echo  ------------------------------------------------
        echo  GLOBAL BATCH STATISTICS:
        powershell -NoProfile -Command "$t=0; Get-Content 'stats.tmp' | ForEach-Object {$t+=[int64]$_}; Write-Host ('  Total Space Saved: -{0:N2} MB' -f ($t/1MB)) -ForegroundColor Cyan"
        echo  ------------------------------------------------
        del stats.tmp >nul 2>&1
    )
)
echo ======================================================
echo.
echo Press any key to exit.
pause >nul
exit

:EXF
if !X! geq !i! (
    if exist !CUTN!.!i!.ncch (
        set CONLINE=!CONLINE:~24,8!
        call :GETX !CONLINE!, ID
        set ARG=!ARG! -i "!CUTN!.!i!.ncch:!i!:!ID!"
        set /a i+=1
    ) else (
        set /a i+=1
        goto EXF
    )
)
exit/B

:GETX v dec
set /a dec=0x%~1
if [%~2] neq [] set %~2=%dec%
exit/b

:: FUNCTION FOR STATS CALCULATION AND DATA ACCUMULATION
:CALC_STATS
set "PS_IN_FILE=%~1"
set "PS_OUT_FILE=%~2"

if not exist "!PS_OUT_FILE!" (
    echo    [ERROR] Output file not found.
    exit /b
)

:: PowerShell: 1. Calculate diff. 2. Print with minus sign. 3. Append saved bytes to stats.tmp
powershell -NoProfile -Command "$o=(Get-Item -LiteralPath $env:PS_IN_FILE).Length; $n=(Get-Item -LiteralPath $env:PS_OUT_FILE).Length; $d=$o-$n; $p=0; if($o -gt 0){$p=($d/$o)*100}; Write-Host ('   -> Reduced by {0:N2}%% (-{1:N2} MB)' -f $p, ($d/1MB)) -ForegroundColor Green; Add-Content -Path 'stats.tmp' -Value $d"
exit /b
rem matif
