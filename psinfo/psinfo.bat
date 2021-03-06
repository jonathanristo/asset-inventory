

@ECHO OFF
cls
REM blank the screen to make it easier to follow what is happen

set /p computer=Enter the computer IP address you wish to query:
REM getting the user to enter the IP address of the system to be inventoried

for /F "tokens=1-4 delims=/ " %%i IN ('date /t') DO (
set DT_DAY=%%i
set DT_MM=%%j
set DT_DD=%%k
set DT_YYYY=%%l)
REM the above lines date the output of the date comment and place the values into appropriate variables

for /F "tokens=1-4 delims=: " %%i IN ('time /t') DO (
set DT_hour=%%i
set DT_min=%%j)
REM do the same for the time command

c:\temp\psinfo.exe -s applications \\%computer% >> C:\temp\%computer%.txt
c:\temp\psinfo64.exe -s applications \\%computer% >> C:\temp\%computer%.txt
REM above run the psinfo and psinfo 64 command, which return information on the system in question.

sort C:\temp\%computer%.txt >> C:\temp\%computer%_.txt
REM the above sorts the items in the file
REM following two lines of code remove duplicate entries in a text file.
REM It was found at http://stackoverflow.com/questions/11689689/batch-to-remove-duplicate-rows-from-text-file

FOR /f "delims=" %%a IN (C:\temp\%computer%_.txt) DO SET $%%a=Y
(FOR /F "delims=$=" %%a In ('set $ 2^>Nul') DO ECHO %%a)>C:\temp\%computer%_%DT_YYYY%%DT_MM%%DT_DD%%DT_hour%%DT_min%.txt

del %computer%_.txt
del %computer%.txt
REM remove temp files
