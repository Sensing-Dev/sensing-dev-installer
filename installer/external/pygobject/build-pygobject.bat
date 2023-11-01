@ECHO OFF
SETLOCAL

REM Configuration - Adjust the paths as necessary
SET "sourceDir=%CD%"
SET "buildDir=%sourceDir%\build"
SET "installDir=%sourceDir%\install"
SET "pkgConfigDir=%buildDir%"
SET "dependenciesDir=%buildDir%\dependencies"

IF "%1"=="" (
    ECHO No conanfile.txt provided.
    EXIT /B 1
)
SET "conanFile=%1"

RMDIR %buildDir%

ECHO "Start conan install "
ECHO "======================"

conan install %conanFile% -b missing -if %buildDir% 
IF ERRORLEVEL 1 EXIT /B 1
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
@REM IF ERRORLEVEL 1 EXIT /B 1

REM Compile and install the project with Ninja
ECHO Compiling with Meson...
meson compile -C %buildDir% -v
@REM IF ERRORLEVEL 1 EXIT /B 1

ECHO Installing with Meson...
meson install -C %buildDir%
@REM IF ERRORLEVEL 1 EXIT /B 1

ECHO Build and install completed successfully!
ENDLOCAL
