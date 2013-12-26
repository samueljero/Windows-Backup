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
set LOGFILE=restore.log
set THREADS=2

echo Restore Script...

rem Set working directory to current directory
%~d0
CD %~dp0

rem We need UAC permissions to do backups because Windows is stupid...
rem inspired by http://stackoverflow.com/questions/7044985/
rem  how-can-i-auto-elevate-my-batch-file-so-that-it-requests-from-uac-admin-rights/12264592#12264592
:checkPrivileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges ) 

:getPrivileges 
if '%1'=='ELEV' (shift & goto gotPrivileges)  
ECHO. 
ECHO **************************************
ECHO Because Windows is stupid, we require
ECHO additional priviledges to restore your
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
ROBOCOPY 2> NUL > NUL
if %ERRORLEVEL%==9009 (
	echo.
	echo.
	echo The robocopy utility is not available on this machine.
	echo This utlity is required for sucessful restore.
	echo Please download it from the link below or contact
	echo your system administrator.
	echo http://edi.idglabs.net/?p=2737
	PAUSE
	exit 255
)

rem Show Restore Warning
echo WARNING: THIS IS A RESTORE SCRIPT. IT WILL REPLACE ALL DATA WITH THE BACKUP COPY
PAUSE
echo.
echo.

rem Ask for Drive
set /P DRIVE=What Drive Would You Like to Restore from:
set DRIVE=%DRIVE::=%
set DRIVE=%DRIVE: =%
If not exist %DRIVE%: (
echo Couldn't find drive to restore from
PAUSE
goto :eof
)

rem Setup Variables
set BACKUP="%DRIVE%:\%BACKUPDIRECTORY%"
set BASE="%PROFILEDRIVE%\%PROFILEDIRECTORY%"

rem check for backup Directory
If not exist "%BACKUP%\Profile" (
	echo.
	echo.
	echo Backup Directory does not exist!
	echo Please re-check your backup drive.
	PAUSE
	goto :eof
)

rem Display date and prompt
If exist "%BACKUP%\date.txt" (
	echo This backup is from:
	type "%BACKUP%\date.txt"
)
set /P ANSWER=Do You Want to Restore THIS Backup [Y/N]?
echo "%ANSWER%"
If NOT "%ANSWER%"=="Y" If NOT "%ANSWER%"=="y" (
	echo Aborting...
	PAUSE
	goto :eof
)

rem do restore
If not exist "%BACKUP%\Profile" mkdir "%BACKUP%\Profile"
ROBOCOPY "%BACKUP%\Profile" "%BASE%" /S /E /B /R:2 /W:2  /COPYALL /MIR  /XJ /SECFIX /TIMFIX /LOG+:%LOGFILE% /TEE /MT:%THREADS%
set A=%ERRORLEVEL%

rem check for errors
If %A% GTR 3 (
	echo .
	echo .	
	echo Restore Failed
	echo At Profile Restore
	echo Return Code: %A%
	PAUSE
	goto :eof
) Else (
	echo .
	echo .
	echo Restore Completed Successfully
	PAUSE
	goto :cleanup
)

:cleanup
rem Delete Scripts
del /Q "%temp%\OEgetPrivileges.vbs" 2> NUL
