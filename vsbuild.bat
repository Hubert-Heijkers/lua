@echo off
setlocal ENABLEDELAYEDEXPANSION

rem =====================================
rem Default settings
rem =====================================
set "REPO_DIR=%~dp0"
set "SRC_DIR=%REPO_DIR%src"
set "BUILD_DIR=%REPO_DIR%build"
set "CONFIG=Release"
set "ARCH=x64"
set "INSTALL_DIR=%REPO_DIR%install"
set "CLEAN_BUILD=0"
set "SHOW_HELP=0"

rem =====================================
rem Parse named parameters
rem Example:
rem   vsbuild.bat --config Debug --arch Win32 --install-dir "D:\install" --clean
rem =====================================
:parse_args
if "%~1"=="" goto :args_done

if /i "%~1"=="--config" (
    set "CONFIG=%~2"
    shift
) else if /i "%~1"=="--arch" (
    set "ARCH=%~2"
    shift
) else if /i "%~1"=="--install-dir" (
    set "INSTALL_DIR=%~2"
    shift
) else if /i "%~1"=="--build-dir" (
    set "BUILD_DIR=%~2"
    shift
) else if /i "%~1"=="--clean" (
    set "CLEAN_BUILD=1"
) else if /i "%~1"=="--help" (
    set "SHOW_HELP=1"
) else if /i "%~1"=="-h" (
    set "SHOW_HELP=1"
) else (
    echo [WARN] Unknown option: %~1
)
shift
goto :parse_args
:args_done

if "%SHOW_HELP%"=="1" goto :show_help

rem =====================================
rem Locate vswhere.exe
rem =====================================
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "GENERATOR="
set "VS_VER="
set "VS_PATH="

if exist "%VSWHERE%" (
    for /f "usebackq tokens=* delims=" %%I in (`"%VSWHERE%" -latest -products * -requires Microsoft.Component.MSBuild -property installationVersion`) do (
        set "VS_VER=%%~I"
    )
    for /f "usebackq tokens=* delims=" %%I in (`"%VSWHERE%" -latest -products * -requires Microsoft.Component.MSBuild -property installationPath`) do (
        set "VS_PATH=%%~I"
    )

    if defined VS_VER (
        for /f "tokens=1 delims=." %%M in ("!VS_VER!") do set "VS_MAJOR=%%M"
        if "!VS_MAJOR!"=="17" set "GENERATOR=Visual Studio 17 2022"
        if "!VS_MAJOR!"=="16" set "GENERATOR=Visual Studio 16 2019"
        if "!VS_MAJOR!"=="15" set "GENERATOR=Visual Studio 15 2017"
    )
)

if not defined GENERATOR (
    echo [INFO] Could not detect VS via vswhere. Using default: Visual Studio 17 2022
    set "GENERATOR=Visual Studio 17 2022"
)

echo [INFO] Generator: %GENERATOR%
echo [INFO] Config:    %CONFIG%
echo [INFO] Arch:      %ARCH%
echo [INFO] Build dir: %BUILD_DIR%
echo [INFO] Install:   %INSTALL_DIR%

rem =====================================
rem Clean build directory if requested
rem =====================================
if "%CLEAN_BUILD%"=="1" (
    if exist "%BUILD_DIR%" (
        echo [INFO] Cleaning build directory...
        rmdir /s /q "%BUILD_DIR%"
    )
)

rem =====================================
rem Create build directory if needed
rem =====================================
if not exist "%BUILD_DIR%" (
    echo [INFO] Creating build directory...
    mkdir "%BUILD_DIR%"
)

rem =====================================
rem Run CMake configure
rem =====================================
echo [INFO] Configuring with CMake...
cmake -S "%SRC_DIR%" -B "%BUILD_DIR%" -G "%GENERATOR%" -A %ARCH% -DCMAKE_INSTALL_PREFIX="%INSTALL_DIR%"
if errorlevel 1 (
    echo [ERROR] CMake configure failed.
    exit /b 1
)

rem =====================================
rem Build and install
rem =====================================
echo [INFO] Building and installing...
cmake --build "%BUILD_DIR%" --config %CONFIG% --target INSTALL -- /m
if errorlevel 1 (
    echo [ERROR] Build or install failed.
    exit /b 1
)

echo.
echo [SUCCESS] Build and install completed successfully.
echo           Build dir: %BUILD_DIR%
echo           Install to: %INSTALL_DIR%
exit /b 0

:show_help
rem =====================================
rem Show help
rem =====================================
echo.
echo ============================================
echo  Windows CMake Build Helper Script
echo ============================================
echo.
echo Usage:
echo   vsbuild.bat [options]
echo.
echo Options:
echo   --config ^<Debug^|Release^>     Build configuration (default: Release)
echo   --arch ^<x64^|Win32^|ARM64^>     Target architecture (default: x64)
echo   --build-dir ^<path^>           Build directory (default: .\build)
echo   --install-dir ^<path^>         Installation directory (default: .\install)
echo   --clean                      Remove existing build directory before building
echo   --help, -h                   Show this help message and exit
echo.
echo Example:
echo   vsbuild.bat --config Debug --arch x64 --clean
echo.
exit /b 0
