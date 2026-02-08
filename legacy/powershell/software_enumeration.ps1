
<# 

script to ask the user to provide the IP address they wish to query, and then to run the powershell
commands to get the installed software on the windows system in question.

The output will be saved to a file called c:\temp\<IP ADDRESS>__installed_software.txt 

The first portion contains a function named Get-RemoteProgram authored by Jaap Brasser. 
This function polls through the registry keys to extract the required information
and is posted on Microsoft's Technet at https://gallery.technet.microsoft.com/Get-RemoteProgram-Get-list-de9fd2b4

Small modifications were needed to this code to make it work as needed for this project. 

Where the code was modified from original, comment lines start with JR show any new information within the function
#>

$ErrorActionPreference= 'silentlycontinue'

#the above keeps the error messages from displaying on the screen, as when an IP address is not found,it throws an error. This prevents a see of RED of being displayed. 
#comment the line out if you wish to see any errors in the program.


Function Get-RemoteProgram {
<#
.Synopsis
Generates a list of installed programs on a computer

.DESCRIPTION
This function generates a list by querying the registry and returning the installed programs of a local or remote computer.

.NOTES   
Name: Get-RemoteProgram
Author: Jaap Brasser
Version: 1.2.1
DateCreated: 2013-08-23
DateUpdated: 2015-02-28
Blog: http://www.jaapbrasser.com
#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        [string[]]
            $ComputerName = $env:COMPUTERNAME,
        [Parameter(Position=0)]
        [string[]]$Property 
    )

    begin {
        $RegistryLocation = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\',
                            'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\'
        $HashProperty = @{}
		#JR  original line follows
        #$SelectProperty = @('ProgramName','ComputerName')
		#JR  modified line follows
		 $SelectProperty = @('ProgramName','DisplayVersion') 	
		 if ($Property) {
            $SelectProperty += $Property
        }
    }

    process {
        foreach ($Computer in $ComputerName) {
            $RegBase = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$Computer)
            foreach ($CurrentReg in $RegistryLocation) {
                if ($RegBase) {
                    $CurrentRegKey = $RegBase.OpenSubKey($CurrentReg)
                    if ($CurrentRegKey) {
                        $CurrentRegKey.GetSubKeyNames() | ForEach-Object {
                            if ($Property) {
                                foreach ($CurrentProperty in $Property) {
                                    $HashProperty.$CurrentProperty = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue($CurrentProperty)
                                }
                            }
                            #JR commented out following line - not needed for this work
							#$HashProperty.ComputerName = $Computer
                            $HashProperty.ProgramName = ($DisplayName = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue('DisplayName'))
                            #JR added following new line as needed for this work 
							$HashProperty.DisplayVersion = ($DisplayVersion = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue('DisplayVersion'))
							
							if ($DisplayName) {
                                New-Object -TypeName PSCustomObject -Property $HashProperty |
                                Select-Object -Property $SelectProperty
                            } 
                        }
                    }
                }
            }
        }
    }
}


clear-host
#blanking the screen to make it easy to see output

#blank out the variable to ensure it is empty
$ip_resp = ''
$ip_addr= ''

DO 
	{
	DO
		{
		$ip_addr = Read-Host 'Input the IP address of the systems you wish to scan. E.G. 10.11.12.13'
		} while ($ip_addr -notmatch '\p{Nd}+\.\p{Nd}+\.\p{Nd}+\.\p{Nd}+')	
		
		#the above forces the user to put the information in the format we want of x.x.x. and forces numbers only
	write-host 'You entered' $ip_addr ', is this correct?'
	$ip_resp = Read-Host 'Y or N'
	} #end of DO
Until ($ip_resp -eq "Y" -OR ($ip_resp -eq "y"))	

#the above loops asking the same question until the user enters Y or y

$a = Get-Date
# get date/time information

$path = 'C:\temp\'
#change the above location to where you wish to have the output files stored

<#
. .\Get-RemoteProgram-jr.ps1

# the above line loads the Get-RemoteProgram script to be able to use the function 
#>
$filename = $path + $ip_addr +'_'+$a.Year+$a.Month+$a.Day+$a.Hour+$a.Minute+$a.Second+'.txt'

Get-RemoteProgram -ComputerName $ip_addr| Out-File $filename
#the above writes out the contents of the variable to a file

write-host ‘Collection complete. File ‘ $filename ‘ written
