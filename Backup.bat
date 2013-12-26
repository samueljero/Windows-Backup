@echo off
rem Author: Samuel Jero <sjero@purdue.edu>
rem Date: 12-24-2013
rem
rem Copyright (C) 2013  Samuel Jero
rem
rem This program is free software: you can redistribute it and/or modify
rem it under the terms of the GNU General Public License as published by
rem the Free Software Foundation, either version 3 of the License, or
rem (at your option) any later version.
rem
rem This program is distributed in the hope that it will be useful,
rem but WITHOUT ANY WARRANTY; without even the implied warranty of
rem MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
rem GNU General Public License for more details.
rem
rem You should have received a copy of the GNU General Public License
rem along with this program.  If not, see <http://www.gnu.org/licenses/>.

rem Configuration
set BACKUPDIRECTORY=ComputerBackups
set PROFILEDIRECTORY=%HOMEPATH%
set PROFILEDRIVE=%HOMEDRIVE%
set THUNDERBIRDPROFILE=""
set BACKUPPICTURES=0
set LOGFILE=backup.log
set TMPDRIVE=B:
set THREADS=2


echo Backup Script...
echo.
echo.

rem Set working directory to current directory
%~d0
CD %~dp0

rem Once VSS is up and running jump to copy operations
if NOT "%1"=="ELEV" IF NOT "%1"=="" (goto shadowcopy )

rem We need UAC permissions to do backups because Windows is stupid...
rem inspired by http://stackoverflow.com/questions/7044985/
rem  how-can-i-auto-elevate-my-batch-file-so-that-it-requests-from-uac-admin-rights/12264592#12264592
:checkPrivileges
verify >nul
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges ) 

:getPrivileges 
if '%1'=='ELEV' (shift & goto gotPrivileges)  
ECHO. 
ECHO **************************************
ECHO Because Windows is stupid, we require
ECHO additional priviledges to backup your
ECHO system. Attempting to elevate privileges.
ECHO You will see a UAC prompt shortly...
ECHO **************************************

rem Re-execute this script with elevated privileges causing UAC prompt
setlocal DisableDelayedExpansion
set "batchPath=%~0"
setlocal EnableDelayedExpansion
ECHO Set UAC = CreateObject^("Shell.Application"^) > "%temp%\OEgetPrivileges.vbs" 
ECHO UAC.ShellExecute "!batchPath!", "ELEV", "", "runas", 1 >> "%temp%\OEgetPrivileges.vbs" 
"%temp%\OEgetPrivileges.vbs" 
exit /B 

:gotPrivileges
setlocal & pushd .


rem Look for needed programs
verify >nul
ROBOCOPY 2> NUL > NUL
if %ERRORLEVEL%==9009 (
	echo.
	echo.
	echo The robocopy utility is not available on this machine.
	echo This utlity is required for sucessful backup.
	echo Please download it from the link below or contact
	echo your system administrator.
	echo http://edi.idglabs.net/?p=2737
	PAUSE
	exit 255
)
reg 2> NUL > NUL
if %ERRORLEVEL%==9009 (
	echo.
	echo.
	echo The reg utility is not available on this machine.
	echo This utlity is required for sucessful backup.
	echo Please contact your system administrator.
	PAUSE
	exit 255
)

vscsc 2> NUL > NUL
if %ERRORLEVEL%==9009 (
	echo.
	echo.
	echo The vscsc utility is not available on this machine.
	echo This utlity is required for sucessful backup.
	echo Please download it from the link below or contact
	echo your system administrator.
	echo http://sourceforge.net/projects/vscsc/
	PAUSE
	exit 255
)

dosdev 2> NUL > NUL
if %ERRORLEVEL%==9009 (
	echo.
	echo.
	echo The dosdev utility is not available on this machine.
	echo This utlity is required for sucessful backup.
	echo Please download it from the link below or contact
	echo your system administrator.
	echo http://sourceforge.net/projects/vscsc/files/utilities/
	PAUSE
	exit 255
)

rem truncate logfile
echo starting backup... > %LOGFILE%

rem Create VSS and re-execute this script
echo Preparing to backup please wait...
echo *****************************************
vscsc -exec=%~0 %PROFILEDRIVE%
If %ERRORLEVEL% NEQ 0 (
	PAUSE
)
exit

rem Do copy after the VSS is setup
:shadowcopy

rem Mount VSS as TMPDRIVE
dosdev %TMPDRIVE% %1

rem Ask for Drive
echo ***************************************** 
set /P DRIVE=What Drive Would You Like to Backup To:
set DRIVE=%DRIVE::=%
set DRIVE=%DRIVE: =%
If not exist %DRIVE%: (
echo Couldn't find drive for backup
PAUSE
goto :eof
)

rem Setup Variables
set BACKUP="%DRIVE%:\%BACKUPDIRECTORY%"
set BASE="%TMPDRIVE%\%PROFILEDIRECTORY%"

rem make sure we have folders for backups
If not exist "%BACKUP%" mkdir "%BACKUP%"
If not "%THUNDERBIRDPROFILE%"=="" If not exist "%BACKUP%\Email" mkdir "%BACKUP%\Email"
If "%BACKUPPICTURES%"=="1" If not exist "%BACKUP%\Pictures" mkdir "%BACKUP%\Pictures"
If not exist "%BACKUP%\Registry" mkdir "%BACKUP%\Registry"
If not exist "%BACKUP%\Profile" mkdir "%BACKUP%\Profile"

rem Indicate backup date
echo %DATE% > "%BACKUP%/date.txt"

rem do backup
echo Starting backup...
verify >nul
ROBOCOPY  "%BASE%"  "%BACKUP%\Profile" /S /E /B /R:2 /W:2 /COPYALL /XJD /MIR /SECFIX /TIMFIX /XD Cache cache tmp temp Temp /XF *.tmp *.TMP /LOG+:%LOGFILE% /TEE /MT:%THREADS%
set A=%ERRORLEVEL%
If not "%THUNDERBIRDPROFILE%"=="" (
ROBOCOPY "%BASE%\AppData\Roaming\Thunderbird\Profiles\%THUNDERBIRDPROFILE%" "%BACKUP%\Email" /S /E /B /R:2 /W:2 /MIR /COPYALL /XJD /SECFIX /TIMFIX /LOG+:%LOGFILE% /TEE /MT:%THREADS%
set B=%ERRORLEVEL%
)
If "%BACKUPPICTURES%"=="1" (
ROBOCOPY  "%BASE%\My Documents\Image Transfer" "%BACKUP%\Pictures" /S /E /B /R:2 /W:2 /MIR /COPYALL /SECFIX /TIMFIX /LOG+:%LOGFILE% /TEE /MT:%THREADS%
set C=%ERRORLEVEL%
)

rem Set Shortcut for My Documents
echo set WshShell = WScript.CreateObject("WScript.Shell" ) > "%temp%\CreateShortcut.vbs"
echo set oShellLink = WshShell.CreateShortcut(Wscript.Arguments.Named("shortcut") ^& ".lnk") >> "%temp%\CreateShortcut.vbs"
echo oShellLink.TargetPath = Wscript.Arguments.Named("target") >> "%temp%\CreateShortcut.vbs"
echo oShellLink.WindowStyle = 1 >> "%temp%\CreateShortcut.vbs"
echo oShellLink.Save >> "%temp%\CreateShortcut.vbs"
"%temp%\CreateShortcut.vbs" /target:"%BACKUP%\Profile\Documents" /shortcut:"%BACKUP%/MyDocuments"

del /Q "%BACKUP%\Registry\hklm.reg" 2> NUL
del /Q "%BACKUP%\Registry\hkcu.reg" 2> NUL
del /Q "%BACKUP%\Registry\hkcr.reg" 2> NUL
del /Q "%BACKUP%\Registry\hku.reg" 2> NUL
del /Q "%BACKUP%\Registry\hkcc.reg" 2> NUL


rem Backup Registry
verify >nul
reg export HKLM "%BACKUP%\Registry\hklm.reg"
set D=%ERRORLEVEL%
reg export HKCU "%BACKUP%\Registry\hkcu.reg"
set E=%ERRORLEVEL%
reg export HKCR "%BACKUP%\Registry\hkcr.reg"
set F=%ERRORLEVEL%
reg export HKU "%BACKUP%\Registry\hku.reg" 
set G=%ERRORLEVEL%
reg export HKCC "%BACKUP%\Registry\hkcc.reg"
set H=%ERRORLEVEL%

rem Unmount VSS
DOSDEV /D %TMPDRIVE%

rem check for errors
If %A% GTR 3 (
	echo.
	echo.	
	echo Backup Failed
	echo At Profile Backup
	echo Return Code: %A%
	PAUSE
	goto :eof
)
If not "%THUNDERBIRDPROFILE%"=="" If %B% GTR 3 (
	echo.
	echo.	
	echo Backup Failed
	echo At Email Backup
	echo Return Code: %B%
	PAUSE
	goto :eof
)
If "%BACKUPPICTURES%"=="1" If %C% GTR 3 (
	echo.
	echo.	
	echo Backup Failed
	echo At Picture Backup
	echo Return Code: %C%
	PAUSE
	goto :eof
)
If %D% NEQ 0 (
	echo.
	echo.	
	echo Backup Failed
	echo At Registry HKLM Backup
	echo Return Code: %D%
	PAUSE
	goto :eof
)
If %E% NEQ 0 (
	echo.
	echo.	
	echo Backup Failed
	echo At Registry HKCU Backup
	echo Return Code: %E%
	PAUSE
	goto :eof
)
If %F% NEQ 0 (
	echo.
	echo.	
	echo Backup Failed
	echo At Registry HKCR Backup
	echo Return Code: %F%
	PAUSE
	goto :eof
)
If %G% NEQ 0 (
	echo.
	echo.	
	echo Backup Failed
	echo At Registry HKU Backup
	echo Return Code: %G%
	PAUSE
	goto :eof
)
If %H% NEQ 0 (
	echo.
	echo.	
	echo Backup Failed
	echo At Registry HKCC Backup
	echo Return Code: %H%
	PAUSE
	goto :eof
) Else (
	echo.
	echo.
	echo Backup Completed Successfully
	PAUSE
	goto :cleanup
)

:cleanup
rem Delete Scripts
del /Q "%temp%\CreateShortcut.vbs" 2> NUL
del /Q "%temp%\OEgetPrivileges.vbs" 2> NUL

exit 0
