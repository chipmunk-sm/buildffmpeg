@echo off

setlocal

rem  Color 07

rem set PLATFORMID=x86
rem  set PLATFORMID=x64
rem  set APPVEYOR_BUILD_WORKER_IMAGE=Visual Studio 2017
rem  set APPVEYOR_BUILD_WORKER_IMAGE=Visual Studio 2015

IF NOT "%PLATFORMID%" == "x64" IF NOT "%PLATFORMID%" == "x86" (
    ECHO "ERROR! SET PLATFORMID to x64 or x86"
    GOTO :exitError
)

SET ROOT_DIR=%cd%

set MSYS2_PATH_TYPE=inherit

rem *** START CLONE or UPDATE SOURCE
SET ENABLE_GIT_CLONE=1
SET ENABLE_GIT_PULL=0

SET sources[0]="https://github.com/FFmpeg/FFmpeg.git"
rem  SET sources[1]="git://git.videolan.org/x264.git"
rem  SET sources[2]="https://github.com/videolan/x265.git"
rem  SET sources[3]="https://github.com/mstorsjo/fdk-aac.git"
rem  SET sources[4]="https://github.com/gypified/libmp3lame.git"
rem  SET sources[5]="https://github.com/xiph/opus.git"

SET branch[0]=--branch n4.1.3
rem  SET branch[1]=
rem  SET branch[2]=
rem  SET branch[3]=
rem  SET branch[4]=
rem  SET branch[5]=

SET directory1[0]=FFmpeg
rem  SET directory1[1]=x264
rem  SET directory1[2]=x265
rem  SET directory1[3]=fdk-aac
rem  SET directory1[4]=libmp3lame
rem  SET directory1[5]=opus

SET "x=0"
:startCloneLoop
IF NOT defined sources[%x%] GOTO :endCloneLoop
	CALL SET clonedDir="%cd%\%%directory1[%x%]%%"
	CALL SET clonedUri=%%sources[%x%]%%
	CALL SET branch=%%branch[%x%]%%

	rem + START GIT PULL
	pushd %clonedDir%
	IF %ERRORLEVEL% NEQ 0 GOTO :cloneSub
   	git clean -ffxd
	IF %ENABLE_GIT_PULL% == 1 git.exe pull --progress -v --no-rebase
	IF %ERRORLEVEL% NEQ 0 GOTO :exitError
	popd
	SET /a "x+=1"
    GOTO :startCloneLoop
	rem ~ END GIT PULL

	rem + START GIT CLONE
:cloneSub
	IF %ENABLE_GIT_CLONE% == 1 git.exe clone --progress --recursive -v %branch% %clonedUri%
	IF %ERRORLEVEL% NEQ 0 GOTO :exitError
	SET /a "x+=1"
    GOTO :startCloneLoop
	rem ~ END GIT CLONE

:endCloneLoop
rem ~~~ END CLONE or UPDATE SOURCE



rem *** yasm
SET YASMDIR=c:\yasm
SET YASMOUT="%YASMDIR%\yasm.exe"

rem  ECHO "YASMDIR=%YASMDIR%"
rem  ECHO "YASMOUT=%YASMOUT%"

SET YASM32URL="http://www.tortall.net/projects/yasm/releases/yasm-1.3.0-win32.exe"
SET YASM64URL="http://www.tortall.net/projects/yasm/releases/yasm-1.3.0-win64.exe"

SET YASM32SRC="%YASMDIR%\yasm-1.3.0-win32.exe"
SET YASM64SRC="%YASMDIR%\yasm-1.3.0-win64.exe"


del %YASMOUT% >nul 2>&1
mkdir %YASMDIR% 2> NUL


IF "%PLATFORMID%" == "x86" (
    IF NOT EXIST %YASM32SRC% powershell.exe -noprofile -executionpolicy bypass -command "(New-Object System.Net.WebClient).DownloadFile('%YASM32URL%', '%YASM32SRC%')"
    copy %YASM32SRC% %YASMOUT% 1>NUL
)

IF "%PLATFORMID%" == "x64" (
    IF NOT EXIST %YASM64SRC% powershell.exe -noprofile -executionpolicy bypass -command "(New-Object System.Net.WebClient).DownloadFile('%YASM64URL%', '%YASM64SRC%')"
    copy %YASM64SRC% %YASMOUT% 1>NUL
)

IF %ERRORLEVEL% NEQ 0 GOTO :exitError
set PATH=%YASMDIR%;%PATH%
rem  yasm --version
rem ~~~ yasm


rem *** SELECT BUILD IMAGE

SET DEBUGBASH=-x

SET WIN10X86PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars32.bat
SET WIN10X64PATH=C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat
SET WIN8PATH=C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat

if "%APPVEYOR_BUILD_WORKER_IMAGE%"=="Visual Studio 2017" if "%PLATFORMID%"=="x86"  GOTO :Win10x86
if "%APPVEYOR_BUILD_WORKER_IMAGE%"=="Visual Studio 2017" if "%PLATFORMID%"=="x64"  GOTO :Win10x64
if "%APPVEYOR_BUILD_WORKER_IMAGE%"=="Visual Studio 2015" if "%PLATFORMID%"=="x86"  GOTO :Win8x86
if "%APPVEYOR_BUILD_WORKER_IMAGE%"=="Visual Studio 2015" if "%PLATFORMID%"=="x64"  GOTO :Win8x64

ECHO "Error! APPVEYOR_BUILD_WORKER_IMAGE is not set %APPVEYOR_BUILD_WORKER_IMAGE%"
GOTO :exitError

REM ********************* Win10x86 *******************
:Win10x86
set BUILDPROFILE=Win10x86
CALL "%WIN10X86PATH%"
IF %ERRORLEVEL% NEQ 0 GOTO :exitError
C:/msys32/usr/bin/bash.exe --login %DEBUGBASH% "%ROOT_DIR%/FFmpegBuild.sh" %BUILDPROFILE% "%ROOT_DIR%"
IF %ERRORLEVEL% NEQ 0 GOTO :exitError
GOTO :ffmpegSuccess

REM ********************* Win10x64 *******************
:Win10x64
set BUILDPROFILE=Win10x64
CALL "%WIN10X64PATH%"
IF %ERRORLEVEL% NEQ 0 GOTO :exitError
C:/msys64/usr/bin/bash.exe --login %DEBUGBASH% "%ROOT_DIR%/FFmpegBuild.sh" %BUILDPROFILE% "%ROOT_DIR%"
IF %ERRORLEVEL% NEQ 0 GOTO :exitError
GOTO :ffmpegSuccess
 
REM ********************* Win8x86 *******************
:Win8x86
set BUILDPROFILE=Win8x86
CALL "%WIN8PATH%" x86
IF %ERRORLEVEL% NEQ 0 GOTO :exitError
C:/msys32/usr/bin/bash.exe --login %DEBUGBASH% "%ROOT_DIR%/FFmpegBuild.sh" %BUILDPROFILE% "%ROOT_DIR%"
IF %ERRORLEVEL% NEQ 0 GOTO :exitError
GOTO :ffmpegSuccess
  
REM ********************* Win8x64 *******************
:Win8x64
set BUILDPROFILE=Win8x64
CALL "%WIN8PATH%" x86_amd64
IF %ERRORLEVEL% NEQ 0 GOTO :exitError
C:/msys64/usr/bin/bash.exe --login %DEBUGBASH% "%ROOT_DIR%/FFmpegBuild.sh" %BUILDPROFILE% "%ROOT_DIR%"
IF %ERRORLEVEL% NEQ 0 GOTO :exitError
GOTO :ffmpegSuccess

:ffmpegSuccess
rem ~~~ BUILD

GOTO :exitSuccess
 
rem  pushd x264
rem      ./configure --prefix=%ROOT_DIR% --bindir=%BIN_DIR% --enable-static
rem      make
rem  IF %ERRORLEVEL% NEQ 0 GOTO :exitError
rem  popd
rem   
rem  pushd x265
rem      cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=%ROOT_DIR% -DENABLE_SHARED:bool=off 
rem      make
rem  IF %ERRORLEVEL% NEQ 0 GOTO :exitError
rem  popd
rem    
rem  pushd fdk-aac
rem      autoreconf -fiv
rem      ./configure --prefix=%ROOT_DIR% --disable-shared
rem      make
rem  IF %ERRORLEVEL% NEQ 0 GOTO :exitError
rem  popd
rem    
rem  pushd libmp3lame
rem      ./configure --prefix=%ROOT_DIR% --enable-nasm --disable-shared
rem      make
rem  IF %ERRORLEVEL% NEQ 0 GOTO :exitError
rem  popd
rem  
rem  pushd libopus
rem      ./configure --prefix=%ROOT_DIR% --disable-shared
rem      make
rem  IF %ERRORLEVEL% NEQ 0 GOTO :exitError
rem  popd
rem    
rem  pushd libvpx
rem      ./configure --prefix=%ROOT_DIR% --disable-examples --disable-unit-tests
rem      make
rem  IF %ERRORLEVEL% NEQ 0 GOTO :exitError
rem  popd


:exitError
	echo Error!
rem  	Color 0c
	
	exit 1
	
	GOTO :exit
	
:exitSuccess
	echo Success!
rem  	Color 07
	GOTO :exit

:exit
