# AppendLicenses.cmake script to append the contents of each license file

cmake_minimum_required(VERSION 3.0)
file(GLOB_RECURSE LICENSE_FILES ${ARGV0})
foreach(LICENSE_FILE IN LISTS LICENSE_FILES)
    file(READ ${LICENSE_FILE} LICENSE_CONTENT)
    file(APPEND ${ARGV1} "${LICENSE_CONTENT}\n--------\n")
endforeach()
