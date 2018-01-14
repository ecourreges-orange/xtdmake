macro(xtdmake_get_directory out in)
  if ("${CMAKE_MAJOR_VERSION}" STREQUAL "3")
    get_filename_component(${out} ${in} DIRECTORY)
  else()
    get_filename_component(${out} ${in} PATH)
  endif()
endmacro()

macro(xtdmake_debug var)
  message("${var} : ${${var}}")
endmacro()

macro(xtdmake_stringify var)
  string(REPLACE ";" " " ${var} "${${var}}")
endmacro()
