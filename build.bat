@echo off
REM mRemoteNG Build Script
REM This script builds the mRemoteNG solution using Visual Studio MSBuild

setlocal

REM Find MSBuild using vswhere
for /f "usebackq tokens=*" %%i in (`"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe`) do (
    set MSBUILD=%%i
)

if not defined MSBUILD (
    echo ERROR: Could not find MSBuild. Please install Visual Studio 2022.
    exit /b 1
)

REM Default configuration
set CONFIG=%1
if "%CONFIG%"=="" set CONFIG=Debug

REM Default platform
set PLATFORM=%2
if "%PLATFORM%"=="" set PLATFORM=x64

echo.
echo ========================================
echo Building mRemoteNG
echo ========================================
echo MSBuild: %MSBUILD%
echo Configuration: %CONFIG%
echo Platform: %PLATFORM%
echo ========================================
echo.

REM Build the solution
"%MSBUILD%" mRemoteNG.sln -p:Configuration=%CONFIG% -p:Platform=%PLATFORM% -v:m -t:rebuild

if %ERRORLEVEL% neq 0 (
    echo.
    echo ========================================
    echo Build FAILED!
    echo ========================================
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================
echo Build SUCCEEDED!
echo ========================================
echo Output: mRemoteNG\bin\%PLATFORM%\%CONFIG%\mRemoteNG.exe
echo ========================================
