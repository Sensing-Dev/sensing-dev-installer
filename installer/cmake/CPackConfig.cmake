# Check for CPack availability
if(NOT EXISTS "${CMAKE_ROOT}/Modules/CPack.cmake")
  message(STATUS "CPack is not found. Skipping CPack configuration.")
  return()
endif()

# set(CPACK_GENERATOR "NSIS;WIX")  # NSIS and WiX generators for MSI
set(CPACK_GENERATOR "WIX") # NSIS and WiX generators for MSI

# Set common CPack variables
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Sensing dev installer")
set(CPACK_PACKAGE_VENDOR "Fixstars Solution Inc")
set(CPACK_PACKAGE_VERSION "${SENSING_DEV_INSTALLER_VCSVERSION}")
set(CPACK_PACKAGE_VERSION_MAJOR "${SENSING_DEV_INSTALLER_VERSION_MAJOR}")
set(CPACK_PACKAGE_VERSION_MINOR "${SENSING_DEV_INSTALLER_VERSION_MINOR}")
set(CPACK_PACKAGE_VERSION_PATCH "${SENSING_DEV_INSTALLER_VERSION_PATCH}")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/license/thirdparty_notice.rtf")
set(CPACK_PACKAGE_ICON "${CMAKE_CURRENT_SOURCE_DIR}/resources/sensing_dev_logo.ico")
# set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CPACK_SYSTEM_NAME}")

set(CPACK_OPENCV_COMPONENT "")
if(OPENCV_ACTION STREQUAL "use_existing")
  set(CPACK_OPENCV_COMPONENT "-no-opencv-")
endif()

set(CPACK_PACKAGE_FILE_NAME "${CMAKE_PROJECT_NAME}-${SENSING_DEV_INSTALLER_VCSVERSION}${CPACK_OPENCV_COMPONENT}-win64")

# # set(CPACK_SET_DESTDIR "ON")
# message(STATUS "CPack Generator: ${CPACK_GENERATOR}")

# # set(CPACK_WIX_ROOT_FOLDER_ID "LocalAppDataFolder")

# # Define the path to your PowerShell script relative to the source directory
# set(PS_SCRIPT_PATH "${CMAKE_SOURCE_DIR}/tools/Env.ps1")
# set(INSTALLATION_DIR "$env:{CMAKE_INSTALL_PREFIX}")

# # Configure the CMake script to invoke the PowerShell script
# configure_file("${CMAKE_SOURCE_DIR}/cmake/PostInstallScript.cmake.in"
#   "${CMAKE_BINARY_DIR}/PostInstallScript.cmake"
#   @ONLY)

# # Set the CPACK_INSTALL_SCRIPTS variable to the generated script
# set(CPACK_INSTALL_SCRIPTS "${CMAKE_BINARY_DIR}/PostInstallScript.cmake")

# Generator-specific settings
if(CPACK_GENERATOR STREQUAL "WIX")
  # CPack settings for the WIX generator
  set(CPACK_WIX_UPGRADE_GUID D2E80558-5056-4993-899C-AC81AA7D6286)
  set(CPACK_WIX_PRODUCT_GUID BEC319CD-78B2-4B68-8978-70D84B9497EB)

# set(CPACK_WIX_UI_REF "WixUI_Mondo")
# set(CPACK_WIX_LICENSE_RTF ${THIRPARTY_NOTICE_FILE_RTF})
elseif(CPACK_GENERATOR STREQUAL "NSIS")
  # CPack settings for the NSIS generator
  # Uncomment and adjust settings as needed for NSIS
  # set(CPACK_GENERATOR "NSIS")
  # set(CPACK_NSIS_MODIFY_PATH TRUE)
  # set(CPACK_NSIS_INSTALL_ROOT "${CPACK_PACKAGING_INSTALL_PREFIX}")
  # ...
endif()

# Include CPack
include(CPack)
