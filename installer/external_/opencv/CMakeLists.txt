include(ExternalProject)

# Define opencv version
set(OPENCV_VERSION 4.5.5)

# Set URLs for Windows and Linux
# https://github.com/opencv/opencv/releases/download/4.5.5/opencv-4.5.5-vc14_vc15.exe
set(OPENCV_WIN_URL "https://github.com/opencv/opencv/releases/download/${OPENCV_VERSION}/opencv-${OPENCV_VERSION}-vc14_vc15.exe")
set(OPENCV_WIN_URL_HASH "cac31973cd1c59bfe9dc926acbde815553d23662ea355e0414b5e50d8f8aa5a8")

# Determine the operating system
if(WIN32)
    set(OPENCV_OS_URL ${OPENCV_WIN_URL})
    set(OPENCV_OS_HASH ${OPENCV_WIN_URL_HASH})
    set(OPENCV_OS_FILE archive.tar)
elseif(UNIX)
    
else()
    message(FATAL_ERROR "Unsupported operating system")
endif()

set(OPENCV_DIR ${CMAKE_BINARY_DIR}/external/opencv/src/opencv)
# set(OPENCV_DIR ${CMAKE_SOURCE_DIR}/external/opencv)

# Add opencv external project
ExternalProject_Add(
    opencv_external
    PREFIX ${CMAKE_BINARY_DIR}/external/opencv
    URL ${OPENCV_OS_URL}
    URL_HASH SHA256=${OPENCV_OS_HASH}  # Use SHA-256 hash
    DOWNLOAD_DIR ${CMAKE_BINARY_DIR}/external/opencv/downloads  # Specify a downloads directory
    SOURCE_DIR ${OPENCV_DIR}  # Specify a downloads directory
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    CONFIGURE_COMMAND ""  # No configure step needed
    BUILD_COMMAND ""  # No build step needed
    INSTALL_COMMAND  ""
    # ${CMAKE_COMMAND} -E tar xzf <DOWNLOAD_DIR>/${OPENCV_OS_FILE}
    BUILD_IN_SOURCE FALSE
    BUILD_ALWAYS FALSE  # Adjust this according to your needs
)


# Specify the opencv library and include directories
add_library(opencv INTERFACE)
add_dependencies(opencv opencv_external opencv_external_linux)
target_include_directories(opencv INTERFACE ${OPENCV_DIR}/include)

# Install opencv library, binaries, includes, and shared files
# install(DIRECTORY ${CMAKE_SOURCE_DIR}/external/opencv/${OPENCV_OS_FILE}/ DESTINATION install)
message("OPENCV_DIR = ${OPENCV_DIR}")
install(DIRECTORY ${OPENCV_DIR}/build/bin/ DESTINATION bin)
install(DIRECTORY ${OPENCV_DIR}/build/x64/vc15/bin/ DESTINATION bin)
install(DIRECTORY ${OPENCV_DIR}/build/x64/vc15/lib/ DESTINATION lib)
install(DIRECTORY ${OPENCV_DIR}/build/include/ DESTINATION include)


## Update thirdparty_notice.txt
file(GLOB_RECURSE license_files 
            ${OPENCV_DIR}/build/LICENSE 
            ${OPENCV_DIR}/build/LICENSE_FFMPEG.txt 
            ${OPENCV_DIR}/build/etc/licenses/* )
# installer\external\opencv\build\etc\licenses
message(VERBOSE "OpenCV Liscence file found: ${license_files}")

set(THIRPARTY_NOTICE_FILE "${CMAKE_BINARY_DIR}/license/thirdparty_notice.txt")

# Copy and concatenate license files
file(WRITE ${THIRPARTY_NOTICE_FILE} "--------\n")

foreach(license ${license_files})
    message (VERBOSE "Copying ${license} to ${THIRPARTY_NOTICE_FILE}")
    file(READ ${license} license_content)
    file(APPEND ${THIRPARTY_NOTICE_FILE} "${license_content}\n--------\n")
endforeach()
