@echo off
setlocal EnableExtensions
title Download and update OpenAI Codex CLI

rem ============================================================
rem Configuration
rem ============================================================

rem GitHub release asset
set "ASSET=codex-x86_64-pc-windows-msvc.exe.zip"
set "EXE_NAME=codex-x86_64-pc-windows-msvc.exe"

rem GitHub latest stable release
set "RELEASE_PAGE_URL=https://github.com/openai/codex/releases/latest"
set "GITHUB_URL=https://github.com/openai/codex/releases/latest/download/%ASSET%"

rem Download directory
set "DOWNLOAD_DIR=D:\codex-cli"
set "TARGET_ZIP=%DOWNLOAD_DIR%\%ASSET%"
set "TEMP_ZIP=%TARGET_ZIP%.tmp"

rem Get the BAT directory without a trailing backslash
for %%I in ("%~dp0.") do set "INSTALL_DIR=%%~fI"

rem Final executable paths
set "INSTALL_TARGET=%INSTALL_DIR%\codex.exe"
set "NEW_TARGET=%INSTALL_DIR%\codex.exe.new"

rem ============================================================
rem Prepare download directory
rem ============================================================

if not exist "%DOWNLOAD_DIR%" (
    mkdir "%DOWNLOAD_DIR%"
)

if errorlevel 1 goto :mkdir_failed

echo.
echo ============================================================
echo OpenAI Codex CLI Updater
echo ============================================================
echo.
echo ZIP file:
echo %TARGET_ZIP%
echo.
echo Install directory:
echo %INSTALL_DIR%
echo.
echo Final executable:
echo %INSTALL_TARGET%
echo.

rem ============================================================
rem Check local and remote versions
rem ============================================================

echo ============================================================
echo Checking Codex CLI versions
echo ============================================================
echo.

set "LOCAL_VERSION="
set "REMOTE_VERSION="
set "LATEST_RELEASE_URL="
set "VERSION_COMPARE="

rem ------------------------------------------------------------
rem Read the locally installed version
rem Example output:
rem codex-cli 0.106.0
rem ------------------------------------------------------------

if exist "%INSTALL_TARGET%" (
    for /f "tokens=2" %%V in ('"%INSTALL_TARGET%" --version 2^>nul') do (
        if not defined LOCAL_VERSION set "LOCAL_VERSION=%%V"
    )
)

if defined LOCAL_VERSION (
    echo Local version : %LOCAL_VERSION%
) else (
    echo Local version : Not installed
)

rem ------------------------------------------------------------
rem Resolve the latest release page
rem Example:
rem https://github.com/openai/codex/releases/tag/rust-v0.106.0
rem ------------------------------------------------------------

for /f "delims=" %%U in ('
    curl.exe ^
        --silent ^
        --show-error ^
        --fail ^
        --location ^
        --head ^
        --connect-timeout 20 ^
        --max-time 60 ^
        --output NUL ^
        --write-out "%%{url_effective}" ^
        "%RELEASE_PAGE_URL%" 2^>nul
') do (
    set "LATEST_RELEASE_URL=%%U"
)

if not defined LATEST_RELEASE_URL goto :remote_version_failed

rem ------------------------------------------------------------
rem Extract release tag from the final redirected URL
rem ------------------------------------------------------------

set "VERSION_PART=%LATEST_RELEASE_URL:*/tag/=%"

for /f "tokens=1 delims=/?#" %%V in ("%VERSION_PART%") do (
    set "REMOTE_VERSION=%%V"
)

rem Remove the rust-v prefix
if /i "%REMOTE_VERSION:~0,6%"=="rust-v" (
    set "REMOTE_VERSION=%REMOTE_VERSION:~6%"
)

rem Remove the v prefix
if /i "%REMOTE_VERSION:~0,1%"=="v" (
    set "REMOTE_VERSION=%REMOTE_VERSION:~1%"
)

if not defined REMOTE_VERSION goto :remote_version_failed

echo Remote version: %REMOTE_VERSION%
echo.

rem ============================================================
rem Decide whether an update is required
rem ============================================================

rem Codex is not installed
if not defined LOCAL_VERSION (
    echo Codex CLI is not installed.
    echo The latest version will be downloaded.
    echo.
    goto :download_routes
)

call :compare_versions "%LOCAL_VERSION%" "%REMOTE_VERSION%"

rem Local version is lower than remote version
if "%VERSION_COMPARE%"=="-1" (
    echo ============================================================
    echo A newer Codex CLI version is available
    echo ============================================================
    echo.
    echo Installed version: %LOCAL_VERSION%
    echo Latest version   : %REMOTE_VERSION%
    echo.
    echo Starting update...
    echo.
    goto :download_routes
)

rem Local version is equal to remote version
if "%VERSION_COMPARE%"=="0" (
    echo ============================================================
    echo Codex CLI is already up to date
    echo ============================================================
    echo.
    echo Installed version: %LOCAL_VERSION%
    echo Latest version   : %REMOTE_VERSION%
    echo.
    goto :ask_force_update
)

rem Local version is higher than remote stable version
if "%VERSION_COMPARE%"=="1" (
    echo ============================================================
    echo Local Codex CLI is newer than the stable release
    echo ============================================================
    echo.
    echo Installed version: %LOCAL_VERSION%
    echo Stable version   : %REMOTE_VERSION%
    echo.
    goto :ask_force_update
)

rem Unexpected comparison result
echo WARNING: Version comparison returned an unexpected result.
echo.
goto :ask_force_update

rem ============================================================
rem Ask whether to update even if local version is equal or newer
rem ============================================================

:ask_force_update
set "UPDATE_CHOICE="

set /p "UPDATE_CHOICE=Do you still want to download and reinstall Codex CLI? [y/N]: "

if /i "%UPDATE_CHOICE%"=="Y" goto :force_update_confirmed
if /i "%UPDATE_CHOICE%"=="YES" goto :force_update_confirmed

echo.
echo Update cancelled.
echo The existing Codex CLI installation was not changed.
echo.
pause
exit /b 0

:force_update_confirmed
echo.
echo The update was confirmed by the user.
echo Starting download...
echo.
goto :download_routes

rem ============================================================
rem Remote version detection failed
rem ============================================================

:remote_version_failed
echo Remote version: Unable to detect
echo.
echo WARNING: Failed to detect the latest GitHub release version.
echo.
echo Possible reasons:
echo   1. GitHub cannot be accessed.
echo   2. The GitHub release URL has changed.
echo   3. curl.exe is unavailable.
echo   4. A proxy intercepted the redirect.
echo.

set "UPDATE_CHOICE="
set /p "UPDATE_CHOICE=Continue downloading the latest version anyway? [y/N]: "

if /i "%UPDATE_CHOICE%"=="Y" goto :remote_check_continue
if /i "%UPDATE_CHOICE%"=="YES" goto :remote_check_continue

echo.
echo Update cancelled.
echo.
pause
exit /b 1

:remote_check_continue
echo.
echo Continuing without remote version comparison...
echo.
goto :download_routes

rem ============================================================
rem Download routes
rem ============================================================

:download_routes

rem Proxy 1: ghfast.top
call :download "https://ghfast.top/%GITHUB_URL%"
if not errorlevel 1 goto :install

rem Proxy 2: gh-proxy.com
call :download "https://gh-proxy.com/%GITHUB_URL%"
if not errorlevel 1 goto :install

rem Final fallback: GitHub direct
call :download "%GITHUB_URL%"
if not errorlevel 1 goto :install

rem ============================================================
rem All download routes failed
rem ============================================================

echo.
echo ============================================================
echo ERROR: All download routes failed
echo ============================================================
echo.
echo Check the network connection or replace the proxy URL.
echo.

if exist "%TEMP_ZIP%" (
    del /f /q "%TEMP_ZIP%" >nul 2>&1
)

pause
exit /b 1

rem ============================================================
rem Download function
rem ============================================================

:download
set "CURRENT_URL=%~1"

echo ============================================================
echo Trying:
echo %CURRENT_URL%
echo ============================================================
echo.
echo Downloading, please wait...
echo.

if exist "%TEMP_ZIP%" (
    del /f /q "%TEMP_ZIP%" >nul 2>&1
)

rem Download with a simple progress bar
curl.exe ^
    --fail ^
    --location ^
    --progress-bar ^
    --retry 2 ^
    --retry-delay 2 ^
    --connect-timeout 20 ^
    --max-time 600 ^
    --output "%TEMP_ZIP%" ^
    "%CURRENT_URL%"

if errorlevel 1 (
    echo.
    echo Route failed. Trying the next route...
    echo.

    if exist "%TEMP_ZIP%" (
        del /f /q "%TEMP_ZIP%" >nul 2>&1
    )

    exit /b 1
)

echo.
echo Validating ZIP file...
echo.

rem Validate ZIP using tar.exe included in Windows Server 2022
tar.exe -tf "%TEMP_ZIP%" >nul 2>&1

if errorlevel 1 (
    echo Invalid ZIP response. Trying the next route...
    echo.

    del /f /q "%TEMP_ZIP%" >nul 2>&1
    exit /b 1
)

rem Replace the previously downloaded ZIP
move /y "%TEMP_ZIP%" "%TARGET_ZIP%" >nul

if errorlevel 1 (
    echo.
    echo ERROR: Failed to save ZIP file:
    echo %TARGET_ZIP%
    echo.
    exit /b 1
)

echo Download route succeeded.
echo.
exit /b 0

rem ============================================================
rem Extract all files
rem ============================================================

:install
echo.
echo ============================================================
echo Download completed
echo ============================================================
echo.
echo Extracting all files to:
echo %INSTALL_DIR%
echo.

rem Extract all files from the ZIP into the BAT directory
rem Existing files with the same names will be overwritten
tar.exe -xf "%TARGET_ZIP%" -C "%INSTALL_DIR%"

if errorlevel 1 (
    echo.
    echo ERROR: Failed to extract ZIP file.
    echo.
    echo ZIP file:
    echo %TARGET_ZIP%
    echo.
    echo Install directory:
    echo %INSTALL_DIR%
    echo.
    pause
    exit /b 1
)

echo All files were extracted successfully.
echo.

rem ============================================================
rem Locate original Codex executable
rem ============================================================

set "ORIGINAL_EXE="

for /r "%INSTALL_DIR%" %%F in ("%EXE_NAME%") do (
    if exist "%%F" (
        if not defined ORIGINAL_EXE (
            set "ORIGINAL_EXE=%%F"
        )
    )
)

if not defined ORIGINAL_EXE (
    echo.
    echo ERROR: Codex executable was not found after extraction.
    echo.
    echo Expected filename:
    echo %EXE_NAME%
    echo.
    pause
    exit /b 1
)

echo Original executable:
echo %ORIGINAL_EXE%
echo.
echo Final executable:
echo %INSTALL_TARGET%
echo.

rem ============================================================
rem Prepare the new codex.exe
rem ============================================================

if exist "%NEW_TARGET%" (
    del /f /q "%NEW_TARGET%" >nul 2>&1
)

copy /y "%ORIGINAL_EXE%" "%NEW_TARGET%" >nul

if errorlevel 1 (
    echo.
    echo ERROR: Failed to prepare the new codex.exe.
    echo.
    echo Check directory permissions.
    echo.
    pause
    exit /b 1
)

rem ============================================================
rem Remove old codex.exe
rem ============================================================

if exist "%INSTALL_TARGET%" (
    echo Removing old codex.exe...

    del /f /q "%INSTALL_TARGET%" >nul 2>&1

    if exist "%INSTALL_TARGET%" (
        echo.
        echo ERROR: Cannot overwrite the existing codex.exe.
        echo.
        echo codex.exe may currently be running.
        echo Close all Codex terminals and processes, then try again.
        echo.

        if exist "%NEW_TARGET%" (
            del /f /q "%NEW_TARGET%" >nul 2>&1
        )

        pause
        exit /b 1
    )
)

rem ============================================================
rem Rename the new executable to codex.exe
rem ============================================================

move /y "%NEW_TARGET%" "%INSTALL_TARGET%" >nul

if errorlevel 1 (
    echo.
    echo ERROR: Failed to create codex.exe.
    echo.
    pause
    exit /b 1
)

rem Delete the original executable with the long filename
if /i not "%ORIGINAL_EXE%"=="%INSTALL_TARGET%" (
    if exist "%ORIGINAL_EXE%" (
        del /f /q "%ORIGINAL_EXE%" >nul 2>&1
    )
)

rem ============================================================
rem Verify installation
rem ============================================================

echo.
echo ============================================================
echo Verifying installed version
echo ============================================================
echo.

"%INSTALL_TARGET%" --version

if errorlevel 1 (
    echo.
    echo WARNING: Files were extracted, but version verification failed.
    echo.
    echo Installed executable:
    echo %INSTALL_TARGET%
) else (
    echo.
    echo ============================================================
    echo Codex CLI update completed successfully
    echo ============================================================
    echo.
    echo Previous version:
    if defined LOCAL_VERSION (
        echo %LOCAL_VERSION%
    ) else (
        echo Not installed
    )
    echo.
    echo Installed executable:
    echo %INSTALL_TARGET%
    echo.
    echo Downloaded ZIP:
    echo %TARGET_ZIP%
)

echo.
pause
explorer.exe "%INSTALL_DIR%"
exit /b 0

rem ============================================================
rem Semantic version comparison
rem
rem Result:
rem   VERSION_COMPARE=-1  Local version is lower
rem   VERSION_COMPARE=0   Versions are equal
rem   VERSION_COMPARE=1   Local version is higher
rem ============================================================

:compare_versions
set "VERSION_COMPARE=0"
set "VERSION_LEFT=%~1"
set "VERSION_RIGHT=%~2"

rem Remove optional release prefixes
if /i "%VERSION_LEFT:~0,6%"=="rust-v" (
    set "VERSION_LEFT=%VERSION_LEFT:~6%"
)

if /i "%VERSION_LEFT:~0,1%"=="v" (
    set "VERSION_LEFT=%VERSION_LEFT:~1%"
)

if /i "%VERSION_RIGHT:~0,6%"=="rust-v" (
    set "VERSION_RIGHT=%VERSION_RIGHT:~6%"
)

if /i "%VERSION_RIGHT:~0,1%"=="v" (
    set "VERSION_RIGHT=%VERSION_RIGHT:~1%"
)

rem Remove prerelease and build suffixes
for /f "tokens=1 delims=-+" %%V in ("%VERSION_LEFT%") do (
    set "VERSION_LEFT=%%V"
)

for /f "tokens=1 delims=-+" %%V in ("%VERSION_RIGHT%") do (
    set "VERSION_RIGHT=%%V"
)

set "LEFT_MAJOR=0"
set "LEFT_MINOR=0"
set "LEFT_PATCH=0"
set "LEFT_BUILD=0"

set "RIGHT_MAJOR=0"
set "RIGHT_MINOR=0"
set "RIGHT_PATCH=0"
set "RIGHT_BUILD=0"

for /f "tokens=1-4 delims=." %%A in ("%VERSION_LEFT%") do (
    set "LEFT_MAJOR=%%A"
    set "LEFT_MINOR=%%B"
    set "LEFT_PATCH=%%C"
    set "LEFT_BUILD=%%D"
)

for /f "tokens=1-4 delims=." %%A in ("%VERSION_RIGHT%") do (
    set "RIGHT_MAJOR=%%A"
    set "RIGHT_MINOR=%%B"
    set "RIGHT_PATCH=%%C"
    set "RIGHT_BUILD=%%D"
)

if not defined LEFT_MAJOR set "LEFT_MAJOR=0"
if not defined LEFT_MINOR set "LEFT_MINOR=0"
if not defined LEFT_PATCH set "LEFT_PATCH=0"
if not defined LEFT_BUILD set "LEFT_BUILD=0"

if not defined RIGHT_MAJOR set "RIGHT_MAJOR=0"
if not defined RIGHT_MINOR set "RIGHT_MINOR=0"
if not defined RIGHT_PATCH set "RIGHT_PATCH=0"
if not defined RIGHT_BUILD set "RIGHT_BUILD=0"

rem Convert the version segments to decimal integers.
rem Adding a decimal prefix avoids octal parsing caused by leading zeroes.
set /a LEFT_MAJOR_NUM=1000000%LEFT_MAJOR% %% 1000000
set /a LEFT_MINOR_NUM=1000000%LEFT_MINOR% %% 1000000
set /a LEFT_PATCH_NUM=1000000%LEFT_PATCH% %% 1000000
set /a LEFT_BUILD_NUM=1000000%LEFT_BUILD% %% 1000000

set /a RIGHT_MAJOR_NUM=1000000%RIGHT_MAJOR% %% 1000000
set /a RIGHT_MINOR_NUM=1000000%RIGHT_MINOR% %% 1000000
set /a RIGHT_PATCH_NUM=1000000%RIGHT_PATCH% %% 1000000
set /a RIGHT_BUILD_NUM=1000000%RIGHT_BUILD% %% 1000000

if %LEFT_MAJOR_NUM% LSS %RIGHT_MAJOR_NUM% (
    set "VERSION_COMPARE=-1"
    exit /b 0
)

if %LEFT_MAJOR_NUM% GTR %RIGHT_MAJOR_NUM% (
    set "VERSION_COMPARE=1"
    exit /b 0
)

if %LEFT_MINOR_NUM% LSS %RIGHT_MINOR_NUM% (
    set "VERSION_COMPARE=-1"
    exit /b 0
)

if %LEFT_MINOR_NUM% GTR %RIGHT_MINOR_NUM% (
    set "VERSION_COMPARE=1"
    exit /b 0
)

if %LEFT_PATCH_NUM% LSS %RIGHT_PATCH_NUM% (
    set "VERSION_COMPARE=-1"
    exit /b 0
)

if %LEFT_PATCH_NUM% GTR %RIGHT_PATCH_NUM% (
    set "VERSION_COMPARE=1"
    exit /b 0
)

if %LEFT_BUILD_NUM% LSS %RIGHT_BUILD_NUM% (
    set "VERSION_COMPARE=-1"
    exit /b 0
)

if %LEFT_BUILD_NUM% GTR %RIGHT_BUILD_NUM% (
    set "VERSION_COMPARE=1"
    exit /b 0
)

set "VERSION_COMPARE=0"
exit /b 0

rem ============================================================
rem Download directory creation failed
rem ============================================================

:mkdir_failed
echo.
echo ============================================================
echo ERROR: Cannot create download directory
echo ============================================================
echo.
echo Directory:
echo %DOWNLOAD_DIR%
echo.
echo Run this BAT file as Administrator or change DOWNLOAD_DIR.
echo.
pause
exit /b 1