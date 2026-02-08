@echo off
cls
set /p computer=Enter the computer IP address you wish to query
REM getting the user to enter the IP address of the system to be inventoried

for /F "tokens=1-4 delims=/ " %%i IN ('date /t') DO (
set DT_DAY=%%i
set DT_MM=%%j
set DT_DD=%%k
set DT_YYYY=%%l)
REM the above takes the date command output and populates the appropriate variables

for /F "tokens=1-4 delims=: " %%i IN ('time /t') DO (
set DT_hour=%%i
set DT_min=%%j
)
REM the above does the same as the above date process, but for the time command

echo.
echo Starting the query. This may take a minute or two. Be patient.
REM Feedback to the user so they know what is happening

wmic /node:"%computer%" /OUTPUT:C:\temp\%computer%_%DT_YYYY%%DT_MM%%DT_DD%%DT_hour%%DT_min%.txt product get name,version
echo.
echo The file C:\temp\%computer%_%DT_YYYY%%DT_MM%%DT_DD%%DT_hour%%DT_min%.txt was written
echo.

REM Run the WMIC command that uses the provided address and saves the file with machine IP and date/time as the filename in C:\temp\
