# Call conan install for dependencies



include(FetchContent)

set(CONFIG_PATH "${CMAKE_SOURCE_DIR}/external/config.yml")

set(CONFIG_PARSER_PATH "${CMAKE_SOURCE_DIR}/tools/build_support/parse_config.py")

message("CONFIG_PATH : ${CONFIG_PATH}")
message("CONFIG_PARSER_PATH : ${CONFIG_PARSER_PATH}")

# Find Python interpreter
find_package(Python REQUIRED)

# Print the path of the found Python interpreter
message(STATUS "Using Python: ${Python_EXECUTABLE}")


add_subdirectory(ion-kit)
add_subdirectory(opencv)
add_subdirectory(aravis)
add_subdirectory(pygobject)

