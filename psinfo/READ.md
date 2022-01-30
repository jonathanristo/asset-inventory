PSinfo.exe and PSinfo64.exe script

For this script to work, the psinfo.exe and psinfo64.exe files must be in the c:\temp
directory. To change this, any reference to c:\temp within the batch file must be modified
to the new location of these files. When the script is run, it will request the IP address of
the system to query.

The output of this script is also stored in the c:\temp directory. The output will be
in the format of <IP address>_YEAR_MONTH_DAY_HOUR_MINUTE.txt. This
format is to permit multiple collections from the same IP address to happen without
overwriting the information, and to quickly provide a reference of when the script created
the file.

To run this script, all that is needed is to call the .bat file from an administrative
command prompt. The user’s current credentials are passed along to the system being
queried by the operating system. It has been assumed that the batch file is called
psinfo.bat and has been placed in the c:\temp directory. The user must type the following
command to invoke the batch file:

C:\temp\psinfo.bat
