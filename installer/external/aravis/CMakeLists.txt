include(ExternalProject)

# Define variables
set(ARAVIS_NAME "aravis")
set(ARAVIS_ACTION "download") # You can set this to a specific action or leave it empty

# Call the Python script and capture its output
execute_process(
    COMMAND ${Python_EXECUTABLE} ${CONFIG_PARSER_PATH} --name ${ARAVIS_NAME} --action ${ARAVIS_ACTION} --config-path ${CONFIG_PATH}
    OUTPUT_VARIABLE OUTPUT_VALUE
    RESULTS_VARIABLE  RESULT_CODE
    ERROR_VARIABLE error
)


if(RESULT_CODE)
    message(FATAL_ERROR "Error while parsing config: ${OUTPUT_VALUE}")
endif()

#Split the output into a list
string(REPLACE "\n" ";" OUTPUT_LIST ${OUTPUT_VALUE})

# Set the variables
list(GET OUTPUT_LIST 0 ARAVIS_NAME)
list(GET OUTPUT_LIST 3 ARAVIS_ACTION)
list(GET OUTPUT_LIST 7 ARAVIS_VERSION)


# Print to verify
message("ARAVIS_NAME  ${ARAVIS_NAME}")
message("ARAVIS_VERSION: ${ARAVIS_VERSION}")

message("ARAVIS_ACTION : ${ARAVIS_ACTION}")

set(ARAVIS_OS_FILE Aravis-${ARAVIS_VERSION})
set(ARAVIS_DIR ${CMAKE_BINARY_DIR}/external/aravis/src/aravis)

if(ARAVIS_ACTION STREQUAL "build")

    list(GET OUTPUT_LIST 6 ARAVIS_GIT_REPO)
    message("ARAVIS_GIT_REPO: ${ARAVIS_GIT_REPO}")
    message(FATAL_ERROR "Option Unimplemented")

elseif(ARAVIS_ACTION STREQUAL "download")
    list(GET OUTPUT_LIST 4 ARAVIS_PKG_URL)
    list(GET OUTPUT_LIST 5 ARAVIS_PKG_SHA)
    message("ARAVIS_PKG_URL: ${ARAVIS_PKG_URL}")
    message("ARAVIS_PKG_SHA : ${ARAVIS_PKG_SHA}")
    # # Add aravis external project
    ExternalProject_Add(
        aravis_external
        PREFIX ${CMAKE_BINARY_DIR}/external/aravis
        URL ${ARAVIS_PKG_URL}
        URL_HASH SHA256=${ARAVIS_PKG_SHA}  # Use SHA-256 hash
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
elseif(ARAVIS_ACTION STREQUAL "use_existing")

    list(GET OUTPUT_LIST 1 ARAVIS_SOURCE)
    list(GET OUTPUT_LIST 2 ARAVIS_INSTALL)
    message("ARAVIS_SOURCE : ${ARAVIS_SOURCE}")
    message("ARAVIS_INSTALL: ${ARAVIS_INSTALL}")
    message(FATAL_ERROR "Option Unimplemented")
else()
    message(FATAL_ERROR "Incorrect action option. Valid values are build, download and use_existing")
endif()

set(ARAVIS_DEP_DIR "${CMAKE_BINARY_DIR}/external/aravis_dependencies/src/aravis_dep")
set(ARAVIS_DEP_WIN_URL_HASH "c0b26fc0c0d2fde51f13107b450c66808ee88d15c2adb0a1f6d4b473f282c3a9")


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

set(LICENSE_FILES_GLOB "${ARAVIS_DIR}/license/COPYING")
concatenate_licenses(${THIRDPARTY_NOTICE_FILE} ${LICENSE_FILES_GLOB} aravis_external)

# Install aravis library, binaries, includes, and shared files
install(DIRECTORY ${ARAVIS_DEP_DIR}/include/ DESTINATION include)
install(DIRECTORY ${ARAVIS_DEP_DIR}/bin/ DESTINATION bin)
install(DIRECTORY ${ARAVIS_DEP_DIR}/lib/ DESTINATION lib)

    
