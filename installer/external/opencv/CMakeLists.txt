include(ExternalProject)

# Define variables
set(OPENCV_NAME "opencv")
set(OPENCV_ACTION "download" CACHE STRING "OpenCv action, Valid options are(download or use_existing)") # You can set this to a specific action or leave it empty

# Call the Python script and capture its output
execute_process(
    COMMAND ${Python_EXECUTABLE} ${CONFIG_PARSER_PATH} --name ${OPENCV_NAME} --action ${OPENCV_ACTION} --config-path ${CONFIG_PATH}
    OUTPUT_VARIABLE OUTPUT_VALUE
    RESULTS_VARIABLE RESULT_CODE
    ERROR_VARIABLE error
)

if(RESULT_CODE)
    message(FATAL_ERROR "Error while parsing config: ${OUTPUT_VALUE}")
endif()

# Split the output into a list
string(REPLACE "\n" ";" OUTPUT_LIST ${OUTPUT_VALUE})

# Set the variables
list(GET OUTPUT_LIST 0 OPENCV_NAME)

# list(GET OUTPUT_LIST 3 OPENCV_ACTION)
list(GET OUTPUT_LIST 7 OPENCV_VERSION)

# Print to verify
message("OPENCV_NAME  ${OPENCV_NAME}")
message("OPENCV_ACTION : ${OPENCV_ACTION}")
message("OPENCV_VERSION: ${OPENCV_VERSION}")

set(OPENCV_OS_FILE archive.tar)
set(OPENCV_DIR ${CMAKE_BINARY_DIR}/external/opencv/src/opencv)

if(OPENCV_ACTION STREQUAL "build")
    list(GET OUTPUT_LIST 1 OPENCV_SOURCE)
    list(GET OUTPUT_LIST 2 OPENCV_INSTALL)
    list(GET OUTPUT_LIST 6 OPENCV_GIT_REPO)

    message("OPENCV_SOURCE : ${OPENCV_SOURCE}")
    message("OPENCV_INSTALL: ${OPENCV_INSTALL}")
    message("OPENCV_GIT_REPO: ${OPENCV_GIT_REPO}")
    message(FATAL_ERROR "Option Unimplemented, Please use use_existing or download")
elseif(OPENCV_ACTION STREQUAL "download")
    list(GET OUTPUT_LIST 4 OPENCV_PKG_URL)
    list(GET OUTPUT_LIST 5 OPENCV_PKG_SHA)

    message("OPENCV_PKG_URL: ${OPENCV_PKG_URL}")
    message("OPENCV_PKG_SHA : ${OPENCV_PKG_SHA}")

    # # Add aravis external project
    ExternalProject_Add(
        opencv_external
        PREFIX ${CMAKE_BINARY_DIR}/external/opencv
        URL ${OPENCV_PKG_URL}
        URL_HASH SHA256=${OPENCV_PKG_SHA} # Use SHA-256 hash
        DOWNLOAD_DIR ${CMAKE_BINARY_DIR}/external/opencv/downloads # Specify a downloads directory
        SOURCE_DIR ${OPENCV_DIR}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        CONFIGURE_COMMAND "" # No configure step needed
        BUILD_COMMAND "" # No build step needed
        INSTALL_COMMAND ""

        # COMMAND powershell -Command "Expand-Archive -Path '<DOWNLOAD_DIR>/${OPENCV_OS_FILE}.zip' -DestinationPath '${CMAKE_SOURCE_DIR}/external/opencv' -Force"
        BUILD_IN_SOURCE FALSE
        BUILD_ALWAYS FALSE # Adjust this according to your needs
    )

    # Specify the opencv library and include directories
    add_library(opencv INTERFACE)
    add_dependencies(opencv opencv_external opencv_external_linux)
    target_include_directories(opencv INTERFACE ${OPENCV_DIR}/include)

    # Install opencv library, binaries, includes, and shared files
    # Copy everything from v24.04.00
    message("OPENCV_DIR = ${OPENCV_DIR}")
    install(DIRECTORY ${OPENCV_DIR}/build DESTINATION opencv)

    # # Update thirdparty_notice.txt
    # Keep copying third party notice after copying everything 
    file(GLOB_RECURSE license_files
        ${OPENCV_DIR}/build/LICENSE
        ${OPENCV_DIR}/build/LICENSE_FFMPEG.txt
        ${OPENCV_DIR}/build/etc/licenses/*LICENSE* 
        ${OPENCV_DIR}/build/etc/licenses/*license* 
        )

    # installer\external\opencv\build\etc\licenses
    message(VERBOSE "OpenCV Liscence file found: ${license_files}")

    if(EXISTS ${THIRPARTY_NOTICE_FILE})
        # Copy and concatenate license files
        file(APPEND ${THIRPARTY_NOTICE_FILE} "${OPENCV_NAME}\n--------\n")

        foreach(license ${license_files})
            message(STATUS "Copying ${license} to ${THIRPARTY_NOTICE_FILE}")
            file(READ ${license} license_content)
            file(APPEND ${THIRPARTY_NOTICE_FILE} "${license_content}\n--------\n")
        endforeach()
    else()
        message(FATAL_ERROR "Source file '${THIRPARTY_NOTICE_FILE}' does not exist.")
    endif()

elseif(OPENCV_ACTION STREQUAL "use_existing")
    message(STATUS "Use local Opencv ")
else()
    message(FATAL_ERROR "Incorrect action option. Valid values are build, doewnload and use_existing")
endif()
