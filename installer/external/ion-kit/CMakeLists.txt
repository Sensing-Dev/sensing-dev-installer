include(ExternalProject)


# Define variables
set(ION_KIT_NAME "ion_kit")
set(ION_KIT_ACTION "download") # You can set this to a specific action or leave it empty

# Call the Python script and capture its output
execute_process(
    COMMAND ${Python_EXECUTABLE} ${CONFIG_PARSER_PATH} --name ${ION_KIT_NAME} --action ${ION_KIT_ACTION} --config-path ${CONFIG_PATH}
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
list(GET OUTPUT_LIST 0 ION_KIT_NAME)
list(GET OUTPUT_LIST 3 ION_KIT_ACTION)
list(GET OUTPUT_LIST 7 ION_KIT_VERSION)


# Print to verify
message("ION_KIT_NAME  ${ION_KIT_NAME}")
message("ION_KIT_ACTION : ${ION_KIT_ACTION}")
message("ION_KIT_VERSION: ${ION_KIT_VERSION}")



set(ION_KIT_OS_FILE ion-kit-${ION_KIT_VERSION})
set(ION_KIT_DIR ${CMAKE_BINARY_DIR}/external/ion-kit/src/${ION_KIT_OS_FILE})

if(ION_KIT_ACTION STREQUAL "build")

    list(GET OUTPUT_LIST 1 ION_KIT_SOURCE)
    list(GET OUTPUT_LIST 2 ION_KIT_INSTALL)
    list(GET OUTPUT_LIST 6 ION_KIT_GIT_REPO)

    message("ION_KIT_SOURCE : ${ION_KIT_SOURCE}")
    message("ION_KIT_INSTALL: ${ION_KIT_INSTALL}")
    message("ION_KIT_PKG_URL: ${ION_KIT_PKG_URL}")

    message(FATAL_ERROR "Option Unimplemented")
elseif(ION_KIT_ACTION STREQUAL "download")
    # Add ion-kit external project
    list(GET OUTPUT_LIST 4 ION_KIT_PKG_URL)
    list(GET OUTPUT_LIST 5 ION_KIT_PKG_SHA)
    
    message("ION_KIT_PKG_SHA : ${ION_KIT_PKG_SHA}")
    message("ION_KIT_GIT_REPO: ${ION_KIT_GIT_REPO}")
    
    ExternalProject_Add(
        ion-kit_external
        PREFIX ${CMAKE_BINARY_DIR}/external/ion-kit
        URL ${ION_KIT_PKG_URL}
        URL_HASH SHA256=${ION_KIT_PKG_SHA}  # Use SHA-256 hash
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
elseif(ION_KIT_ACTION STREQUAL "use_existing")
    list(GET OUTPUT_LIST 1 ION_KIT_SOURCE)
    list(GET OUTPUT_LIST 2 ION_KIT_INSTALL)
    message("ION_KIT_SOURCE : ${ION_KIT_SOURCE}")
    message("ION_KIT_INSTALL: ${ION_KIT_INSTALL}")
    set(ION_KIT_DIR  ${ION_KIT_INSTALL})
else()
    message(FATAL_ERROR "Incorrect action option. Valid values are build, download and use_existing")
endif()

# Add ion-kit external project


# Specify the ion-kit library and include directories
add_library(ion-kit INTERFACE)
add_dependencies(ion-kit ion-kit_external )
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

