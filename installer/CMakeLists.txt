cmake_minimum_required(VERSION 3.15)
project(sensing-dev CXX)
set(CMAKE_CXX_STANDARD 17)

message(STATUS "Building with CMake version: ${CMAKE_VERSION}")

# Load the CMake ExternalProject module
include(ExternalProject)
add_subdirectory(external)

# Add your main executable
add_executable(${PROJECT_NAME} src/installer.cpp)

# Link against aravis, pygobject, ion-kit, and OpenCV libraries
# target_link_libraries(${PROJECT_NAME} aravis::aravis)


#version
# set(SENSING_DEV_INSTALLER_VERSION_MAJOR 23)
# set(SENSING_DEV_INSTALLER_VERSION_MINOR 08)
# set(SENSING_DEV_INSTALLER_VERSION_PATCH 00)

execute_process(
    COMMAND git describe --abbrev=0 --tags
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE GIT_LATEST_TAG
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
if(NOT GIT_LATEST_TAG)
    message(WARNING "No git tags found. Setting version to default.")

    string(TIMESTAMP CURRENT_YEAR "%Y")
    math(EXPR CURRENT_YEAR_SHORT "${CURRENT_YEAR} - 2000")
    string(TIMESTAMP CURRENT_MONTH "%m")
    string(TIMESTAMP CURRENT_DAY "%d")

    set(GIT_LATEST_TAG "v${CURRENT_YEAR_SHORT}.${CURRENT_MONTH}.${CURRENT_DAY}")
endif()

if(GIT_LATEST_TAG MATCHES "^v([0-9]+)\\.([0-9]+)\\.([0-9]+)-?(.*)$")
    set(SENSING_DEV_INSTALLER_VERSION_MAJOR "${CMAKE_MATCH_1}")
    set(SENSING_DEV_INSTALLER_VERSION_MINOR "${CMAKE_MATCH_2}")
    set(SENSING_DEV_INSTALLER_VERSION_PATCH "${CMAKE_MATCH_3}")
    set(SENSING_DEV_INSTALLER_VERSION_TAG "${CMAKE_MATCH_4}")
else()
    message(FATAL_ERROR "Failed to parse version from tag '${GIT_LATEST_TAG}'")
endif()


configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/Version.h.in
    ${CMAKE_CURRENT_BINARY_DIR}/Version.h
)

set(SENSING_DEV_INSTALLER_VCSVERSION "${SENSING_DEV_INSTALLER_VERSION_MAJOR}.${SENSING_DEV_INSTALLER_VERSION_MINOR}.${SENSING_DEV_INSTALLER_VERSION_PATCH}")

message(STATUS "Sensing Dev Installer Version : ${SENSING_DEV_INSTALLER_VCSVERSION}")


# # Install sensing-dev-installer
install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION bin)

# Include header files
install(DIRECTORY ${CMAKE_SOURCE_DIR}/include/ DESTINATION include  FILES_MATCHING PATTERN "*.h;*.hpp" )
install(FILES ${CMAKE_BINARY_DIR}/Version.h DESTINATION include)
install(DIRECTORY ${CMAKE_SOURCE_DIR}/tools/ DESTINATION tools)
install(FILES ${CMAKE_SOURCE_DIR}/license/LICENSE DESTINATION license)

# For MSVC generator
if(MSVC)    
    install(FILES ${CMAKE_BINARY_DIR}/license/thirdparty_notice.txt DESTINATION license)
    set(THIRPARTY_NOTICE_FILE_RTF "${CMAKE_BINARY_DIR}/license/thirdparty_notice.rtf")

    # Copy and concatenate license files
    file(READ  ${CMAKE_BINARY_DIR}/license/thirdparty_notice.txt content)
    file(WRITE ${THIRPARTY_NOTICE_FILE_RTF} "${content}\n--------\n")
    install(DIRECTORY ${CMAKE_BINARY_DIR}/license/ DESTINATION license)    
endif()

# install(CODE "execute_process(COMMAND powershell -ExecutionPolicy Bypass -File \${CMAKE_INSTALL_PREFIX}/tools/Env.ps1 -installPath \${CMAKE_INSTALL_PREFIX})")


include(cmake/CPackConfig.cmake)
