include(ExternalProject)

# Define ion-kit version
set(ION_KIT_VERSION 0.3.4)

# Set URLs for Windows and Linux
set(ION_KIT_WIN_URL "https://github.com/fixstars/ion-kit/releases/download/v${ION_KIT_VERSION}/ion-kit-${ION_KIT_VERSION}-win64.zip")
set(ION_KIT_LINUX_URL "https://github.com/fixstars/ion-kit/releases/download/v${ION_KIT_VERSION}/ion-kit-${ION_KIT_VERSION}-Linux.tar.gz")

set(ION_KIT_WIN_URL_HASH "3d6edc0ad63f07e54a9d5c10d672b1e48154aa4deb374eb5ecc66d40bcef32b1")
set(ION_KIT_LINUX_URL "48f7e24795885140bc9e254b1b8cf620d61ac3065321364b6beaf13c5f92a075")

# Determine the operating system
if(WIN32)
    set(ION_KIT_OS_URL ${ION_KIT_WIN_URL})
    set(ION_KIT_OS_HASH ${ION_KIT_WIN_URL_HASH})
    set(ION_KIT_OS_FILE ion-kit-${ION_KIT_VERSION}-win64)
elseif(UNIX)
    set(ION_KIT_OS_URL ${ION_KIT_LINUX_URL})
    set(ION_KIT_OS_HASH ${ION_KIT_LINUX_URL_HASH})
    set(ION_KIT_OS_FILE ion-kit-${ION_KIT_VERSION}-Linux.tar.gz)
else()
    message(FATAL_ERROR "Unsupported operating system")
endif()

set(ION_KIT_DIR ${CMAKE_BINARY_DIR}/external/ion-kit/src/${ION_KIT_OS_FILE})

# Add ion-kit external project
ExternalProject_Add(
    ion-kit_external
    PREFIX ${CMAKE_BINARY_DIR}/external/ion-kit
    URL ${ION_KIT_OS_URL}
    URL_HASH SHA256=${ION_KIT_OS_HASH}  # Use SHA-256 hash
    DOWNLOAD_DIR ${CMAKE_BINARY_DIR}/external/ion-kit/downloads  # Specify a downloads directory
    SOURCE_DIR ${ION_KIT_DIR}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    CONFIGURE_COMMAND ""  # No configure step needed
    BUILD_COMMAND ""  # No build step needed
    INSTALL_COMMAND  ""
    # COMMAND powershell -Command "Expand-Archive -Path '<DOWNLOAD_DIR>/${ION_KIT_OS_FILE}.zip' -DestinationPath '${CMAKE_SOURCE_DIR}/external/ion-kit' -Force"
    BUILD_IN_SOURCE FALSE
    BUILD_ALWAYS FALSE  # Adjust this according to your needs
)


# Specify the ion-kit library and include directories
add_library(ion-kit INTERFACE)
add_dependencies(ion-kit ion-kit_external ion-kit_external_linux)
target_include_directories(ion-kit INTERFACE ${ION_KIT_DIR}/include)

# Install ion-kit library, binaries, includes, and shared files
# install(DIRECTORY ${CMAKE_SOURCE_DIR}/external/ion-kit/${ION_KIT_OS_FILE}/ DESTINATION install)
install(DIRECTORY ${ION_KIT_DIR}/bin/ DESTINATION bin)
install(DIRECTORY ${ION_KIT_DIR}/include/ DESTINATION include)
install(DIRECTORY ${ION_KIT_DIR}/share/ DESTINATION share)
install(DIRECTORY ${ION_KIT_DIR}/lib/ DESTINATION lib)

# Copy and concatenate license files
file(GLOB_RECURSE license_files ${ION_KIT_DIR}/license/LICENSE ${ION_KIT_DIR}/license/*thirdparty_notice.txt*)
# installer\external\ion-kit\ion-kit-0.3.1-win64\license\LICENSE
message(VERBOSE  "Ion-kit Liscence file found: ${license_files}")
set(THIRPARTY_NOTICE_FILE "${CMAKE_BINARY_DIR}/license/thirdparty_notice.txt")
file(WRITE ${THIRPARTY_NOTICE_FILE} "--------\n")
foreach(license ${license_files})
    message (VERBOSE "Copying ${license} to ${THIRPARTY_NOTICE_FILE}")
    file(READ ${license} license_content)
    file(APPEND ${THIRPARTY_NOTICE_FILE} "${license_content}\n--------\n")
endforeach()

