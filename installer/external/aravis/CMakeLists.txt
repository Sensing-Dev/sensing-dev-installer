include(ExternalProject)

# Define aravis version
set(ARAVIS_VERSION 0.8.25)

# Set URLs for Windows and Linux
	#https://ion-kit.s3.us-west-2.amazonaws.com/dependencies/Aravis-0.8.25.zip
set(ARAVIS_WIN_URL "https://ion-kit.s3.us-west-2.amazonaws.com/dependencies/Aravis-0.8.25.zip")
set(ARAVIS_WIN_URL_HASH "D9633F91EDE3469AE00722CC2EEF506B6B6289AFC498FAE588B8898319E383B2")

# Determine the operating system
if(WIN32)
    set(ARAVIS_OS_URL ${ARAVIS_WIN_URL})
    set(ARAVIS_OS_HASH ${ARAVIS_WIN_URL_HASH})
    set(ARAVIS_OS_FILE Aravis-${ARAVIS_VERSION})
elseif(UNIX)

else()
    message(FATAL_ERROR "Unsupported operating system")
endif()

set(ARAVIS_DIR ${CMAKE_BINARY_DIR}/external/aravis/src/aravis)

# Add aravis external project

ExternalProject_Add(
    aravis_external
    PREFIX ${CMAKE_BINARY_DIR}/external/aravis
    URL ${ARAVIS_OS_URL}
    URL_HASH SHA256=${ARAVIS_OS_HASH}  # Use SHA-256 hash
    DOWNLOAD_DIR ${CMAKE_BINARY_DIR}/external/aravis/downloads  # Specify a downloads directory
    SOURCE_DIR ${ARAVIS_DIR}
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    CONFIGURE_COMMAND ""  # No configure step needed
    BUILD_COMMAND ""  # No build step needed
    INSTALL_COMMAND  ""
    # COMMAND powershell -Command "Expand-Archive -Path '<DOWNLOAD_DIR>/${ARAVIS_OS_FILE}.zip' -DestinationPath '${CMAKE_SOURCE_DIR}/external/aravis' -Force"
    BUILD_IN_SOURCE FALSE
    BUILD_ALWAYS FALSE  # Adjust this according to your needs
)

set(ARAVIS_DEP_DIR "${CMAKE_BINARY_DIR}/external/aravis_dependencies/src/aravis_dep")
set(ARAVIS_DEP_WIN_URL_HASH "379DF5AA0EF95E2FAECE6E3688681CD9BB57DBD1B9701D3320174E0846EA7621")


ExternalProject_Add(
        aravis_dependencies
        PREFIX ${CMAKE_BINARY_DIR}/external/aravis_dependencies
        URL "https://ion-kit.s3.us-west-2.amazonaws.com/dependencies/Aravis-dependencies.zip"
        URL_HASH SHA256=${ARAVIS_DEP_WIN_URL_HASH}  # Use SHA-256 hash
        DOWNLOAD_DIR ${CMAKE_BINARY_DIR}/external/aravis_dependencies/downloads  # Specify a downloads directory
        SOURCE_DIR ${ARAVIS_DEP_DIR}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        CONFIGURE_COMMAND ""  # No configure step needed
        BUILD_COMMAND ""  # No build step needed
        INSTALL_COMMAND  ""
        # COMMAND powershell -Command "Expand-Archive -Path '<DOWNLOAD_DIR>/${ARAVIS_DEP_OS_FILE}.zip' -DestinationPath '${CMAKE_SOURCE_DIR}/external/aravis' -Force"
        BUILD_IN_SOURCE FALSE
        BUILD_ALWAYS FALSE  # Adjust this according to your needs
    )



# Install aravis library, binaries, includes, and shared files
# install(DIRECTORY ${CMAKE_SOURCE_DIR}/external/aravis/ DESTINATION install)
install(DIRECTORY ${ARAVIS_DIR}/include/ DESTINATION include)
install(DIRECTORY ${ARAVIS_DIR}/bin/ DESTINATION bin)
install(DIRECTORY ${ARAVIS_DIR}/share/ DESTINATION share)
install(DIRECTORY ${ARAVIS_DIR}/lib/ DESTINATION lib)
# install(DIRECTORY ${ARAVIS_DIR}/license/ DESTINATION license)

# Specify the aravis library and include directories
add_library(aravis INTERFACE)
add_dependencies(aravis aravis_external aravis_dependencies)
target_include_directories(aravis INTERFACE ${ARAVIS_DIR}/include ${ARAVIS_DEP_DIR}/include)

# Install aravis library, binaries, includes, and shared files
install(DIRECTORY ${ARAVIS_DEP_DIR}/include/ DESTINATION include)
install(DIRECTORY ${ARAVIS_DEP_DIR}/bin/ DESTINATION bin)
install(DIRECTORY ${ARAVIS_DEP_DIR}/lib/ DESTINATION lib)

file(GLOB_RECURSE license_files ${ARAVIS_DIR}/license/COPYING )
# installer\external\aravis\aravis-0.3.1-win64\license\LICENSE
message(VERBOSE "ARAVIS Liscence file found: ${license_files}")

set(THIRPARTY_NOTICE_FILE "${CMAKE_BINARY_DIR}/license/thirdparty_notice.txt")

# Copy and concatenate license files
file(WRITE ${THIRPARTY_NOTICE_FILE} "--------\n")

foreach(license ${license_files})
    message (VERBOSE "Copying ${license} to ${THIRPARTY_NOTICE_FILE}")
    file(READ ${license} license_content)
    file(APPEND ${THIRPARTY_NOTICE_FILE} "${license_content}\n--------\n")
endforeach()

    