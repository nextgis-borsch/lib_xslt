################################################################################
# Project:  cmake build system for all
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nexgis.com
################################################################################
# Copyright (C) 2015-2019, NextGIS <info@nextgis.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
################################################################################

function(check_version libxslt_major libxslt_minor libxslt_micro libexslt_major libexslt_minor libexslt_micro)

    set(VERSION_FILE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/configure.ac")
    # Read version information from configure.ac.
    file(READ "${VERSION_FILE_PATH}" _CONTENTS)
    
    string(REGEX MATCH "MAJOR_VERSION.*[0-9]+"
      LIBXSLT_MAJOR_VERSION ${_CONTENTS})
    string (REGEX MATCH "[0-9]+"
      LIBXSLT_MAJOR_VERSION ${LIBXSLT_MAJOR_VERSION})
    string(REGEX MATCH "MINOR_VERSION.*[0-9]+"
      LIBXSLT_MINOR_VERSION ${_CONTENTS})
    string (REGEX MATCH "[0-9]+"
      LIBXSLT_MINOR_VERSION ${LIBXSLT_MINOR_VERSION})
    string(REGEX MATCH "MICRO_VERSION.*[0-9]+"
      LIBXSLT_MICRO_VERSION ${_CONTENTS})
    string (REGEX MATCH "[0-9]+"
      LIBXSLT_MICRO_VERSION ${LIBXSLT_MICRO_VERSION})
      
    set(${libxslt_major} ${LIBXSLT_MAJOR_VERSION} PARENT_SCOPE)
    set(${libxslt_minor} ${LIBXSLT_MINOR_VERSION} PARENT_SCOPE)
    set(${libxslt_micro} ${LIBXSLT_MICRO_VERSION} PARENT_SCOPE)
    
    string(REGEX MATCH "LIBEXSLT_MAJOR_VERSION=+([0-9]+)"
      LIBEXSLT_MAJOR_VERSION ${_CONTENTS})
    string (REGEX MATCH "([0-9]+)"
      LIBEXSLT_MAJOR_VERSION ${LIBEXSLT_MAJOR_VERSION})
    string(REGEX MATCH "LIBEXSLT_MINOR_VERSION=+([0-9]+)"
        LIBEXSLT_MINOR_VERSION ${_CONTENTS})
    string (REGEX MATCH "([0-9]+)"
        LIBEXSLT_MINOR_VERSION ${LIBEXSLT_MINOR_VERSION})
    string(REGEX MATCH "LIBEXSLT_MICRO_VERSION=+([0-9]+)"
        LIBEXSLT_MICRO_VERSION ${_CONTENTS})
    string (REGEX MATCH "([0-9]+)"
        LIBEXSLT_MICRO_VERSION ${LIBEXSLT_MICRO_VERSION})

    set(${libexslt_major} ${LIBEXSLT_MAJOR_VERSION} PARENT_SCOPE)
    set(${libexslt_minor} ${LIBEXSLT_MINOR_VERSION} PARENT_SCOPE)
    set(${libexslt_micro} ${LIBEXSLT_MICRO_VERSION} PARENT_SCOPE)

    # Store version string in file for installer needs
    file(TIMESTAMP "${VERSION_FILE_PATH}" VERSION_DATETIME "%Y-%m-%d %H:%M:%S" UTC)
    set(VERSION ${LIBXSLT_MAJOR_VERSION}.${LIBXSLT_MINOR_VERSION}.${LIBXSLT_MICRO_VERSION})
    get_cpack_filename(${VERSION} PROJECT_CPACK_FILENAME)
    file(WRITE ${CMAKE_BINARY_DIR}/version.str "${VERSION}\n${VERSION_DATETIME}\n${PROJECT_CPACK_FILENAME}")

endfunction(check_version)

function(report_version name ver)

    string(ASCII 27 Esc)
    set(BoldYellow  "${Esc}[1;33m")
    set(ColourReset "${Esc}[m")

    message("${BoldYellow}${name} version ${ver}${ColourReset}")

endfunction()

# macro to find programs on the host OS
macro( find_exthost_program )
    if(CMAKE_CROSSCOMPILING)
        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER )

        find_program( ${ARGN} )

        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY )
    else()
        find_program( ${ARGN} )
    endif()
endmacro()

function(get_prefix prefix IS_STATIC)
  if(IS_STATIC)
    set(STATIC_PREFIX "static-")
      if(ANDROID)
        set(STATIC_PREFIX "${STATIC_PREFIX}android-${ANDROID_ABI}-")
      elseif(IOS)
        set(STATIC_PREFIX "${STATIC_PREFIX}ios-${IOS_ARCH}-")
      endif()
    endif()
  set(${prefix} ${STATIC_PREFIX} PARENT_SCOPE)
endfunction()


function(get_cpack_filename ver name)
    get_compiler_version(COMPILER)
    
    if(NOT DEFINED BUILD_STATIC_LIBS)
      set(BUILD_STATIC_LIBS OFF)
    endif()

    get_prefix(STATIC_PREFIX ${BUILD_STATIC_LIBS})

    set(${name} ${PROJECT_NAME}-${ver}-${STATIC_PREFIX}${COMPILER} PARENT_SCOPE)
endfunction()

function(get_compiler_version ver)
    ## Limit compiler version to 2 or 1 digits
    string(REPLACE "." ";" VERSION_LIST ${CMAKE_C_COMPILER_VERSION})
    list(LENGTH VERSION_LIST VERSION_LIST_LEN)
    if(VERSION_LIST_LEN GREATER 2 OR VERSION_LIST_LEN EQUAL 2)
        list(GET VERSION_LIST 0 COMPILER_VERSION_MAJOR)
        list(GET VERSION_LIST 1 COMPILER_VERSION_MINOR)
        set(COMPILER ${CMAKE_C_COMPILER_ID}-${COMPILER_VERSION_MAJOR}.${COMPILER_VERSION_MINOR})
    else()
        set(COMPILER ${CMAKE_C_COMPILER_ID}-${CMAKE_C_COMPILER_VERSION})
    endif()

    if(WIN32)
        if(CMAKE_CL_64)
            set(COMPILER "${COMPILER}-64bit")
        endif()
    endif()
    
    # Debug
    # set(COMPILER Clang-9.0)

    set(${ver} ${COMPILER} PARENT_SCOPE)
endfunction()
