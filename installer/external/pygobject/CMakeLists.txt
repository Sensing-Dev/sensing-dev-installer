include(ExternalProject)

# Define variables
set(PYGOBJECT_NAME "pygobject")
set(PYGOBJECT_ACTION "download") # You can set this to a specific action or leave it empty

# Call the Python script and capture its output
execute_process(
    COMMAND ${Python_EXECUTABLE} ${CONFIG_PARSER_PATH} --name ${PYGOBJECT_NAME} --action ${PYGOBJECT_ACTION} --config-path ${CONFIG_PATH}
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
list(GET OUTPUT_LIST 0 PYGOBJECT_NAME)
list(GET OUTPUT_LIST 7 PYGOBJECT_VERSION)
list(GET OUTPUT_LIST 3 PYGOBJECT_ACTION)


# Print to verify
message("PYGOBJECT_NAME  ${PYGOBJECT_NAME}")
message("PYGOBJECT_VERSION: ${PYGOBJECT_VERSION}")
message("PYGOBJECT_ACTION : ${PYGOBJECT_ACTION}")


set(PYGOBJECT_OS_FILE pygobject-${PYGOBJECT_VERSION})
set(PYGOBJECT_DIR ${CMAKE_BINARY_DIR}/external/pygobject/src/pygobject)

if(PYGOBJECT_ACTION STREQUAL "build")
    list(GET OUTPUT_LIST 1 PYGOBJECT_SOURCE)
    list(GET OUTPUT_LIST 2 PYGOBJECT_INSTALL)
    list(GET OUTPUT_LIST 6 PYGOBJECT_GIT_REPO)
    message("PYGOBJECT_SOURCE : ${PYGOBJECT_SOURCE}")
    message("PYGOBJECT_INSTALL: ${PYGOBJECT_INSTALL}")
    message("PYGOBJECT_GIT_REPO: ${PYGOBJECT_GIT_REPO}")
    message(FATAL_ERROR "Option Unimplemented")
elseif(PYGOBJECT_ACTION STREQUAL "download")
    # # Add aravis external project
    
    list(GET OUTPUT_LIST 4 PYGOBJECT_PKG_URL)
    list(GET OUTPUT_LIST 5 PYGOBJECT_PKG_SHA)

    message("PYGOBJECT_PKG_URL: ${PYGOBJECT_PKG_URL}")
    message("PYGOBJECT_PKG_SHA : ${PYGOBJECT_PKG_SHA}")
    ExternalProject_Add(
        pygobject_external
        PREFIX ${CMAKE_BINARY_DIR}/external/pygobject
        URL ${PYGOBJECT_PKG_URL}
        URL_HASH SHA256=${PYGOBJECT_PKG_SHA}  # Use SHA-256 hash
        DOWNLOAD_DIR ${CMAKE_BINARY_DIR}/external/pygobject/downloads  # Specify a downloads directory
        SOURCE_DIR ${PYGOBJECT_DIR}
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
        CONFIGURE_COMMAND ""  # No configure step needed
        BUILD_COMMAND ""  # No build step needed
        INSTALL_COMMAND  ""
        # COMMAND powershell -Command "Expand-Archive -Path '<DOWNLOAD_DIR>/${PYGOBJECT_OS_FILE}.zip' -DestinationPath '${CMAKE_SOURCE_DIR}/external/pygobject' -Force"
        BUILD_IN_SOURCE FALSE
        BUILD_ALWAYS FALSE  # Adjust this according to your needs
    )  
    # Add pygobject external project
    
elseif(PYGOBJECT_ACTION STREQUAL "use_existing")
    list(GET OUTPUT_LIST 1 PYGOBJECT_SOURCE)
    list(GET OUTPUT_LIST 2 PYGOBJECT_INSTALL)
    message("PYGOBJECT_SOURCE : ${PYGOBJECT_SOURCE}")
    message("PYGOBJECT_INSTALL: ${PYGOBJECT_INSTALL}")
    set(PYGOBJECT_DIR  ${CMAKE_SOURCE_DIR}/${PYGOBJECT_INSTALL}-${PYGOBJECT_VERSION})
else()
    message(FATAL_ERROR "Incorrect action option. Valid values are build, download and use_existing")
endif()

# Specify the pygobject library and include directories
add_library(pygobject INTERFACE)
add_dependencies(pygobject pygobject_external)
target_include_directories(pygobject INTERFACE ${PYGOBJECT_DIR}/include)

# Install pygobject library, binaries, includes, and shared files
# install(DIRECTORY ${CMAKE_SOURCE_DIR}/external/pygobject/${PYGOBJECT_OS_FILE}/ DESTINATION install)
install(DIRECTORY ${PYGOBJECT_DIR}/include/ DESTINATION include)
install(DIRECTORY ${PYGOBJECT_DIR}/bin/ DESTINATION bin)
install(DIRECTORY ${PYGOBJECT_DIR}/share/ DESTINATION share)
install(DIRECTORY ${PYGOBJECT_DIR}/lib/ DESTINATION lib)
# install(DIRECTORY ${PYGOBJECT_DIR}/license/ DESTINATION license)



file(GLOB_RECURSE license_files ${PYGOBJECT_DIR}/license/COPYING )
# installer\external\pygobject\pygobject-0.3.1-win64\license\LICENSE
message(VERBOSE "Liscence file found: ${license_files}")

set(THIRPARTY_NOTICE_FILE "${CMAKE_BINARY_DIR}/license/thirdparty_notice.txt")

# Copy and concatenate license files
file(WRITE ${THIRPARTY_NOTICE_FILE} "--------\n")

foreach(license ${license_files})
    message (VERBOSE "Copying ${license} to ${THIRPARTY_NOTICE_FILE}")
    file(READ ${license} license_content)
    file(APPEND ${THIRPARTY_NOTICE_FILE} "${license_content}\n--------\n")
endforeach()

install(FILES ${THIRPARTY_NOTICE_FILE}
            DESTINATION license
        )
