@ECHO OFF
cls
REM Blank the screen to make it easier to follow what is happening

set /p startIP=Enter the start IP address you wish to scan:
set /p endIP=Enter the end IP address you wish to scan:

REM Extracting the last octet of the IP addresses
for /f "tokens=1-4 delims=." %%a in ("%startIP%") do (
    set start1=%%a
    set start2=%%b
    set start3=%%c
    set start4=%%d
)

for /f "tokens=1-4 delims=." %%a in ("%endIP%") do (
    set end1=%%a
    set end2=%%b
    set end3=%%c
    set end4=%%d
)

REM Ensuring the start and end IP addresses are within the same subnet
if "%start1%.%start2%.%start3%" neq "%end1%.%end2%.%end3%" (
    echo Start and end IP addresses must be in the same subnet.
    exit /b
)

REM Loop through the range of IP addresses
set currentIP=%start4%
:scanLoop
if %currentIP% gtr %end4% goto end

set computer=%start1%.%start2%.%start3%.%currentIP%

for /F "tokens=1-4 delims=/ " %%i IN ('date /t') DO (
    set DT_DAY=%%i
    set DT_MM=%%j
    set DT_DD=%%k
    set DT_YYYY=%%l
)

for /F "tokens=1-4 delims=: " %%i IN ('time /t') DO (
    set DT_hour=%%i
    set DT_min=%%j
)

c:\temp\psinfo.exe -s applications \\%computer% >> C:\temp\%computer%.txt
c:\temp\psinfo64.exe -s applications \\%computer% >> C:\temp\%computer%.txt

sort C:\temp\%computer%.txt >> C:\temp\%computer%_.txt

FOR /f "delims=" %%a IN (C:\temp\%computer%_.txt) DO SET $%%a=Y
(FOR /F "delims=$=" %%a IN ('set $ 2^>Nul') DO ECHO %%a) > C:\temp\%computer%_%DT_YYYY%%DT_MM%%DT_DD%%DT_hour%%DT_min%.txt

del C:\temp\%computer%_.txt
del C:\temp\%computer%.txt

set /a currentIP+=1
goto scanLoop

:end
echo Scanning complete.
