@echo off
setlocal enabledelayedexpansion

echo Starting Cylonix Share test...

REM Create test files in temp directory
set TEMP_DIR=%TEMP%\cylonix_test
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
echo Creating test files in %TEMP_DIR%...
echo Test content 1 > "%TEMP_DIR%\test1.txt"
echo Test content 2 > "%TEMP_DIR%\test2.txt"

REM Create build directory
set BUILD_DIR=%~dp0..\build
echo Setting up build directory: %BUILD_DIR%
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
pushd "%BUILD_DIR%"

REM Configure and build debug version
echo Configuring CMake...
cmake -G "Visual Studio 17 2022" -A x64 ^
    -DCMAKE_TOOLCHAIN_FILE=C:/Users/cylonix/src/vcpkg/scripts/buildsystems/vcpkg.cmake ^
    -DCMAKE_PREFIX_PATH=C:/Users/cylonix/src/vcpkg/installed/x64-windows/share ^
    -Dnlohmann_json_DIR=C:/Users/cylonix/src/vcpkg/installed/x64-windows/share/nlohmann_json ^
    -DDEBUG_TEST=ON ..
if errorlevel 1 goto error

echo Building project...
cmake --build . --config Debug
if errorlevel 1 goto error

REM Run the test
echo.
echo Running share extension test...
echo Command: Debug\ShareTest.exe "%TEMP_DIR%\test1.txt" "%TEMP_DIR%\test2.txt"
Debug\ShareTest.exe "%TEMP_DIR%\test1.txt" "%TEMP_DIR%\test2.txt"
if errorlevel 1 (
    echo ShareTest.exe failed with error level %errorlevel%
    goto error
)
goto end

:error
echo Build or test failed with error level %errorlevel%!
pause
goto cleanup

:end
echo Test completed successfully

:cleanup
echo Cleaning up...
if exist "%TEMP_DIR%" rd /s /q "%TEMP_DIR%"
popd
echo Done.