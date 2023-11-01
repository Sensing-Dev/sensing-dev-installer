@ECHO OFF
SETLOCAL

REM Configuration - Adjust the paths as necessary
SET "sourceDir=%CD%"
SET "buildDir=%sourceDir%\build"
SET "installDir=%sourceDir%\install"
SET "pkgConfigDir=%buildDir%"
SET "dependenciesDir=%buildDir%\dependencies"

ECHO "Start conan install "
ECHO "======================"

conan install %sourceDir%\scripts\conanfile.txt -b missing -if %buildDir% 

REM Check if source directory exists and clone if it doesn't

ECHO "Update virtual env"
ECHO "======================"

REM Run the batch file for setting up pkg-config and dependencies
CALL %pkgConfigDir%\activate.bat
CALL %pkgConfigDir%\activate_build.bat
CALL %pkgConfigDir%\activate_run.bat
SET "PKG_CONFIG_PATH=%pkgConfigDir%;%PKG_CONFIG_PATH%"
SET PKG_CONFIG_PATH

ECHO "Meson setup"
ECHO "======================"
REM Meson build - Check if you need to reconfigure or it's the first-time setup

REM First-time setup
REM Add additional Meson configurations as needed
meson setup %buildDir% %sourceDir% --prefix=%installDir% --buildtype release -Dpycairo=disabled -Dtests=false --pkg-config-path %PKG_CONFIG_PATH%
IF ERRORLEVEL 1 EXIT /B 1


REM Change to the build directory
CD /D %buildDir%

REM Compile and install the project with Ninja
ECHO Compiling with Meson...
meson compile -C . -v
IF ERRORLEVEL 1 EXIT /B 1

ECHO Installing with Meson...
meson install -C .
IF ERRORLEVEL 1 EXIT /B 1

ECHO Build and install completed successfully!
ENDLOCAL
