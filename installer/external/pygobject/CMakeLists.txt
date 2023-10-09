include(ExternalProject)

# Define pygobject version
set(PYGOBJECT_VERSION 3.42.2)

# Set URLs for Windows and Linux
	#https://ion-kit.s3.us-west-2.amazonaws.com/dependencies/pygobject-3.42.2.zip
set(PYGOBJECT_WIN_URL "https://ion-kit.s3.us-west-2.amazonaws.com/dependencies/pygobject-3.42.2.zip")
set(PYGOBJECT_WIN_URL_HASH "eea9465b7cbf1420ee3b3d8a78f6cfa3feeff89ffade7ab1874ebb25d7078037")

# Determine the operating system
if(WIN32)
    set(PYGOBJECT_OS_URL ${PYGOBJECT_WIN_URL})
    set(PYGOBJECT_OS_HASH ${PYGOBJECT_WIN_URL_HASH})
    # set(PYGOBJECT_OS_FILE pygobject-${PYGOBJECT_VERSION})
    set(PYGOBJECT_OS_FILE pygobject-${PYGOBJECT_VERSION})
elseif(UNIX)

else()
    message(FATAL_ERROR "Unsupported operating system")
endif()

set(PYGOBJECT_DIR ${CMAKE_BINARY_DIR}/external/pygobject/src/pygobject)

# Add pygobject external project

ExternalProject_Add(
    pygobject_external
    PREFIX ${CMAKE_BINARY_DIR}/external/pygobject
    URL ${PYGOBJECT_OS_URL}
    URL_HASH SHA256=${PYGOBJECT_OS_HASH}  # Use SHA-256 hash
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
