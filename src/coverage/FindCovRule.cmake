add_custom_target(cov)
add_custom_target(cov-clean)

xtdmake_find_program(Lcov
  NAMES lcov
  DOC "code coverage generation tool"
  URL "http://ltp.sourceforge.net/coverage/lcov.php"
  REQUIRED CovRule_FIND_REQUIRED
  VERSION_OPT "--version"
  VERSION_POS 3)

xtdmake_find_program(Genhtml
  NAMES genhtml
  DOC "Html report generation tool"
  URL "http://ltp.sourceforge.net/coverage/lcov.php"
  REQUIRED CovRule_FIND_REQUIRED
  VERSION_OPT "--version"
  VERSION_POS 3)

set(CovRule_DEFAULT_EXCLUDE_PATTERNS "Test*.*" CACHE STRING "CovRule default file exclude wildcards")
set(CovRule_DEFAULT_MIN_PERCENT      "30"      CACHE STRING "CovRule default mimunim coverage percentage to consider task successful")
set(CovRule_FOUND 0)

if (NOT Lcov_FOUND OR NOT Genhtml_FOUND OR NOT CheckRule_FOUND)
  message(STATUS "Found module CovRule : FALSE (unmet required dependencies)")
  if (CovRule_FIND_REQUIRED)
    message(FATAL_ERROR "Unable to load required module CovRule")
  endif()
else()
  set(CovRule_FOUND 1)
  message(STATUS "Found module CovRule : TRUE")
endif()

if (NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
  function(add_cov module)
    add_custom_target(${module}-cov
      COMMAND echo "warning: cov rule is disabled due release build")
    add_custom_target(${module}-cov-clean
      COMMAND echo "warning: cov rule is disabled due release build")
    add_dependencies(cov       ${module}-cov)
    add_dependencies(cov-clean ${module}-cov-clean)
  endfunction()
else()
  if (NOT CovRule_FOUND)
    function(add_cov module)
      add_custom_target(${module}-cov
        COMMAND echo "warning: cov rule is disabled due to missing dependencies")
      add_custom_target(${module}-cov-clean
        COMMAND echo "warning: cov rule is disabled due to missing dependencies")
      add_dependencies(cov       ${module}-cov)
      add_dependencies(cov-clean ${module}-cov-clean)
    endfunction()
  else()
    function(add_cov module)
      set(multiValueArgs  EXCLUDE_PATTERNS)
      set(oneValueArgs    )
      set(options         )
      cmake_parse_arguments(CovRule
        "${options}"
        "${oneValueArgs}"
        "${multiValueArgs}"
        ${ARGN})

      set(CovRule_OUTPUT   "${CMAKE_BINARY_DIR}/reports/${module}/coverage")
      xtdmake_set_default(CovRule EXCLUDE_PATTERNS)
      xtdmake_set_default(CovRule MIN_PERCENT)
      file(GLOB l_depends "${CMAKE_CURRENT_BINARY_DIR}/*.gcno")

      add_custom_command(
        COMMENT "Generating ${module} coverage informations"
        OUTPUT  ${CMAKE_CURRENT_BINARY_DIR}/coverage.info
        DEPENDS ${module}-check-build
        COMMAND bash -c "while [ -d ${CMAKE_CURRENT_BINARY_DIR}/testing ]; do sleep 1; done"
        COMMAND rm -f ${CMAKE_CURRENT_BINARY_DIR}/coverage-run.info ${CMAKE_CURRENT_BINARY_DIR}/coverage-initial.info ${CMAKE_CURRENT_BINARY_DIR}/coverage.info
        COMMAND ${Lcov_EXECUTABLE} -q -z -d ${CMAKE_CURRENT_BINARY_DIR}
        COMMAND ${Lcov_EXECUTABLE} -q -c -i -d ${CMAKE_CURRENT_BINARY_DIR} -o ${CMAKE_CURRENT_BINARY_DIR}/coverage-initial.info
        COMMAND $(MAKE) ${module}-check-run-forced  > /dev/null 2>&1
        COMMAND ${Lcov_EXECUTABLE} -q -c -d ${CMAKE_CURRENT_BINARY_DIR} -o ${CMAKE_CURRENT_BINARY_DIR}/coverage-run.info || cp ${CMAKE_CURRENT_BINARY_DIR}/coverage-initial.info ${CMAKE_CURRENT_BINARY_DIR}/coverage-run.info
        COMMAND ${Lcov_EXECUTABLE} -q -a ${CMAKE_CURRENT_BINARY_DIR}/coverage-initial.info -a ${CMAKE_CURRENT_BINARY_DIR}/coverage-run.info -o ${CMAKE_CURRENT_BINARY_DIR}/coverage.info || cp ${CMAKE_CURRENT_BINARY_DIR}/coverage-initial.info ${CMAKE_CURRENT_BINARY_DIR}/coverage.info
        COMMAND ${Lcov_EXECUTABLE} -q -e ${CMAKE_CURRENT_BINARY_DIR}/coverage.info "${CMAKE_CURRENT_SOURCE_DIR}/*"                          -o ${CMAKE_CURRENT_BINARY_DIR}/coverage.info
        COMMAND ${Lcov_EXECUTABLE} -q -r ${CMAKE_CURRENT_BINARY_DIR}/coverage.info ${CovRule_EXCLUDE_PATTERNS}                              -o ${CMAKE_CURRENT_BINARY_DIR}/coverage.info
        VERBATIM)

      add_custom_command(
        COMMENT "Generating ${module} coverage HTML and XML reports"
        OUTPUT ${CovRule_OUTPUT}/index.html ${CovRule_OUTPUT}/coverage.xml ${CovRule_OUTPUT}/status.json
        DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/coverage.info ${XTDMake_HOME}/coverage/status.py
        COMMAND ${Genhtml_EXECUTABLE} -q -o ${CovRule_OUTPUT}/ --function-coverage -t "${module} unit test coverage" --demangle-cpp ${CMAKE_CURRENT_BINARY_DIR}/coverage.info --legend -s
        COMMAND ${XTDMake_HOME}/coverage/lcov_cobertura.py ${CMAKE_CURRENT_BINARY_DIR}/coverage.info -d -o ${CovRule_OUTPUT}/coverage.xml
        COMMAND ${XTDMake_HOME}/coverage/status.py --input-file=${CovRule_OUTPUT}/coverage.xml --output-file=${CovRule_OUTPUT}/status.json --min-percent=${CovRule_MIN_PERCENT}
        )

      add_custom_target(${module}-cov
        DEPENDS ${CovRule_OUTPUT}/index.html ${CovRule_OUTPUT}/coverage.xml ${CovRule_OUTPUT}/status.json)
      add_custom_target(${module}-cov-clean
        COMMAND rm -rf ${CovRule_OUTPUT} ${CMAKE_CURRENT_BINARY_DIR}/coverage.info)
      add_dependencies(cov       ${module}-cov)
      add_dependencies(cov-clean ${module}-cov-clean)
    endfunction()
  endif()
endif()