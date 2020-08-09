################################################################################
# Copyright (C) 2020, NextGIS <info@nextgis.com>
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

cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

project(xslt)

# Some init settings
set(CMAKE_COLOR_MAKEFILE ON)
# Set path to additional CMake modules
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

if(NOT DEFINED PACKAGE_VENDOR)
    set(PACKAGE_VENDOR NextGIS)
endif()

if(NOT DEFINED PACKAGE_BUGREPORT)
    set(PACKAGE_BUGREPORT info@nextgis.com)
endif()

if(OSX_FRAMEWORK AND (BUILD_SHARED_LIBS OR BUILD_STATIC_LIBS))
  message(FATAL_ERROR "Only OSX_FRAMEWORK key or any or both BUILD_SHARED_LIBS
                       and BUILD_STATIC_LIBS keys are permitted")
endif()

if(OSX_FRAMEWORK)
    set(INSTALL_BIN_DIR "bin" CACHE INTERNAL "Installation directory for executables" FORCE)
    set(INSTALL_LIB_DIR "Library/Frameworks" CACHE INTERNAL "Installation directory for libraries" FORCE)
    set(INSTALL_INC_DIR ${INSTALL_LIB_DIR}/lib${PROJECT_NAME}.framework/Headers CACHE INTERNAL "Installation directory for headers" FORCE)
    set(INSTALL_SHARE_DIR ${INSTALL_LIB_DIR}/lib${PROJECT_NAME}.framework/Resources CACHE INTERNAL "Directory for data" FORCE)
    set(INSTALL_CMAKECONF_DIR ${INSTALL_LIB_DIR}/lib${PROJECT_NAME}.framework/Resources/CMake CACHE INTERNAL "Installation directory for cmake config files" FORCE)
    set(SKIP_INSTALL_HEADERS ON)
    set(SKIP_INSTALL_EXECUTABLES OFF)
    set(SKIP_INSTALL_FILES ON)
    set(SKIP_INSTALL_EXPORT ON)
    set(CMAKE_MACOSX_RPATH ON)
    set(BUILD_SHARED_LIBS ON)
else()
    include(GNUInstallDirs)

    set(INSTALL_BIN_DIR ${CMAKE_INSTALL_BINDIR} CACHE INTERNAL "Installation directory for executables" FORCE)
    set(INSTALL_LIB_DIR ${CMAKE_INSTALL_LIBDIR} CACHE INTERNAL "Installation directory for libraries" FORCE)
    set(INSTALL_INC_DIR ${CMAKE_INSTALL_INCLUDEDIR} CACHE INTERNAL "Installation directory for headers" FORCE)
    set(INSTALL_SHARE_DIR ${CMAKE_INSTALL_DATADIR} CACHE INTERNAL "Installation directory for share data" FORCE)
    set(INSTALL_PARENT_INC_DIR ${CMAKE_INSTALL_INCLUDEDIR} CACHE INTERNAL "Installation directory for headers" FORCE)
    set(INSTALL_CMAKECONF_DIR ${CMAKE_INSTALL_DATADIR}/lib${PROJECT_NAME}/CMake CACHE INTERNAL "Installation directory for cmake config files" FORCE)
endif()

if(WIN32 OR OSX_FRAMEWORK)
    set(XSLT_LIB_NAME lib${PROJECT_NAME})
    set(EXSLT_LIB_NAME libexslt)
else()
    set(XSLT_LIB_NAME ${PROJECT_NAME})
    set(EXSLT_LIB_NAME exslt)
endif()

set(PACKAGE_NAME ${XSLT_LIB_NAME})
string(TOUPPER ${PACKAGE_NAME} PACKAGE_UPPER_NAME)
string(TOUPPER ${EXSLT_LIB_NAME} EXSLT_PACKAGE_UPPER_NAME)

if(POLICY CMP0075)
	cmake_policy(SET CMP0075 NEW)
endif()


include(util)
# Version information
check_version(LIBXSLT_MAJOR_VERSION LIBXSLT_MINOR_VERSION LIBXSLT_MICRO_VERSION LIBEXSLT_MAJOR_VERSION LIBEXSLT_MINOR_VERSION LIBEXSLT_MICRO_VERSION)

set(LIBEXSLT_DOTTED_VERSION ${LIBEXSLT_MAJOR_VERSION}.${LIBEXSLT_MINOR_VERSION}.${LIBEXSLT_MICRO_VERSION})
math(EXPR LIBEXSLT_VERSION_NUMBER "${LIBEXSLT_MAJOR_VERSION} * 10000 + ${LIBEXSLT_MINOR_VERSION} * 100 + ${LIBEXSLT_MICRO_VERSION}")
set(LIBEXSLT_VERSION_EXTRA "")

set(LIBXSLT_DOTTED_VERSION "${LIBXSLT_MAJOR_VERSION}.${LIBXSLT_MINOR_VERSION}.${LIBXSLT_MICRO_VERSION}")
math(EXPR LIBXSLT_VERSION_NUMBER "${LIBXSLT_MAJOR_VERSION} * 10000 + ${LIBXSLT_MINOR_VERSION} * 100 + ${LIBXSLT_MICRO_VERSION}")
set(LIBXSLT_VERSION_EXTRA "")

set(VERSION ${LIBXSLT_DOTTED_VERSION})
set(LIBEXSLT_VERSION ${LIBEXSLT_DOTTED_VERSION})

if(OSX_FRAMEWORK)
    set(LIBXSLT_FRAMEWORK_VERSION ${LIBXSLT_MAJOR_VERSION})
    set(LIBEXSLT_FRAMEWORK_VERSION ${LIBEXSLT_MAJOR_VERSION})
endif()

report_version(${PROJECT_NAME} ${VERSION})

#include(CMakePackageConfigHelpers)

include(FindAnyProject)

find_anyproject(ICONV REQUIRED)
find_anyproject(LIBXML2 REQUIRED)

find_package(Threads)

include(CheckLibraryExists)
check_library_exists(grypt gcry_control "gcrypt.h" HAVE_GCRYPT)

option(LIBXSLT_WITH_DEBUGGER "Add the debugging support" OFF)

if(HAVE_GCRYPT)
    option(LIBXSLT_WITH_CRYPTO "Add crypto support to exslt" ON)
else()
    set(LIBXSLT_WITH_CRYPTO OFF)
endif()

option(LIBXSLT_WITH_MEM_DEBUG "Add the memory debugging module" OFF)
option(LIBXSLT_WITH_MODULES "Add the module support" ON)
option(LIBXSLT_WITH_PROFILER "Add the profiling support" OFF)

set(LIBXSLT_WITH_TRIO OFF)
option(LIBXSLT_WITH_XSLT_DEBUG "Add the debugging code" OFF)

foreach(VARIABLE IN ITEMS WITH_CRYPTO WITH_DEBUGGER WITH_MEM_DEBUG WITH_MODULES WITH_PROFILER WITH_PYTHON WITH_TRIO WITH_XSLT_DEBUG)
    if(LIBXSLT_${VARIABLE})
        set(${VARIABLE} 1)
    else()
        set(${VARIABLE} 0)
    endif()
endforeach()

set(MODULE_EXTENSION "${CMAKE_SHARED_LIBRARY_SUFFIX}")

if(Threads_FOUND)
    list(APPEND CMAKE_REQUIRED_LIBRARIES Threads::Threads)
endif()

if(MSVC)
    configure_file(libxslt/win32config.h config.h COPYONLY)
    configure_file(libxslt/win32config.h win32config.h COPYONLY)
else()
    include(CheckCSourceCompiles)
    include(CheckFunctionExists)
    include(CheckIncludeFiles)

    if(UNIX)
        set(CMAKE_REQUIRED_LIBRARIES m)
    endif()
    check_function_exists(clock_gettime HAVE_CLOCK_GETTIME)
    check_include_files(dlfcn.h HAVE_DLFCN_H)
    check_function_exists(fabs HAVE_FABS)
    check_include_files(float.h HAVE_FLOAT_H)
    check_function_exists(floor HAVE_FLOOR)
    check_function_exists(fprintf HAVE_FPRINTF)
    check_include_files(fp_class.h HAVE_FP_CLASS_H)
    check_function_exists(ftime HAVE_FTIME)
    check_function_exists(gettimeofday HAVE_GETTIMEOFDAY)
    check_function_exists(gmtime HAVE_GMTIME)
    check_function_exists(gmtime_r HAVE_GMTIME_R)
    check_include_files(ieeefp.h HAVE_IEEEFP_H)
    check_include_files(inttypes.h HAVE_INTTYPES_H)
    check_library_exists(pthread pthread_join "" HAVE_LIBPTHREAD)
    check_include_files(locale.h HAVE_LOCALE_H)
    check_function_exists(localtime HAVE_LOCALTIME)
    check_function_exists(localtime_r HAVE_LOCALTIME_R)
    check_include_files(math.h HAVE_MATH_H)
    check_include_files(memory.h HAVE_MEMORY_H)
    check_include_files(nan.h HAVE_NAN_H)
    check_function_exists(pow HAVE_POW)
    check_function_exists(printf HAVE_PRINTF)
    check_include_files(pthread.h HAVE_PTHREAD_H)
    check_function_exists(snprintf HAVE_SNPRINTF)
    check_function_exists(sprintf HAVE_SPRINTF)
    check_function_exists(sscanf HAVE_SSCANF)
    check_function_exists(stat HAVE_STAT)
    check_include_files(stdarg.h HAVE_STDARG_H)
    check_include_files(stdint.h HAVE_STDINT_H)
    check_include_files(stdlib.h HAVE_STDLIB_H)
    check_include_files(strings.h HAVE_STRINGS_H)
    check_include_files(string.h HAVE_STRING_H)
    check_function_exists(strxfrm_l HAVE_STRXFRM_L)
    check_include_files(sys/select.h HAVE_SYS_SELECT_H)
    check_include_files(sys/stat.h HAVE_SYS_STAT_H)
    check_include_files(sys/timeb.h HAVE_SYS_TIMEB_H)
    check_include_files(sys/time.h HAVE_SYS_TIME_H)
    check_include_files(sys/types.h HAVE_SYS_TYPES_H)
    check_function_exists(time HAVE_TIME)
    check_include_files(time.h HAVE_TIME_H)
    check_include_files(unistd.h HAVE_UNISTD_H)
    check_function_exists(vfprintf HAVE_VFPRINTF)
    check_function_exists(vsnprintf HAVE_VSNPRINTF)
    check_function_exists(vsprintf HAVE_VSPRINTF)
    check_include_files(xlocale.h HAVE_XLOCALE_H)
    check_function_exists(_stat HAVE__STAT)
    set(LT_OBJDIR ".libs/")
    check_include_files("float.h;stdarg.h;stdlib.h;string.h" STDC_HEADERS)
    set(_ALL_SOURCE ON)
    set(_GNU_SOURCE ON)
    set(_POSIX_PTHREAD_SEMANTICS ON)
    set(_TANDEM_SOURCE ON)
    check_c_source_compiles("
        #define __EXTENSIONS__ 1
        int main() { return 0; }
    " __EXTENSIONS__)
    check_include_files(minix/config.h HAVE_MINIX_CONFIG_H)
    if(HAVE_MINIX_CONFIG_H)
        set(_MINIX ON)
        set(_POSIX_1_SOURCE ON)
        set(_POSIX_SOURCE ON)
    endif()
    configure_file(cmake/config.cmake.in config.h)
endif()

configure_file(libexslt/exsltconfig.h.in libexslt/exsltconfig.h)
configure_file(libxslt/xsltconfig.h.in libxslt/xsltconfig.h)

set(
    LIBXSLT_HDRS
    libxslt/attributes.h
    libxslt/documents.h
    libxslt/extensions.h
    libxslt/extra.h
    libxslt/functions.h
    libxslt/imports.h
    libxslt/keys.h
    libxslt/namespaces.h
    libxslt/numbersInternals.h
    libxslt/pattern.h
    libxslt/preproc.h
    libxslt/security.h
    libxslt/templates.h
    libxslt/transform.h
    libxslt/variables.h
    libxslt/xslt.h
    ${CMAKE_CURRENT_BINARY_DIR}/libxslt/xsltconfig.h
    libxslt/xsltexports.h
    libxslt/xsltInternals.h
    libxslt/xsltlocale.h
    libxslt/xsltutils.h
)

set(
    LIBXSLT_SRCS
    libxslt/attributes.c
    libxslt/attrvt.c
    libxslt/documents.c
    libxslt/extensions.c
    libxslt/extra.c
    libxslt/functions.c
    libxslt/imports.c
    libxslt/keys.c
    libxslt/namespaces.c
    libxslt/numbers.c
    libxslt/pattern.c
    libxslt/preproc.c
    libxslt/security.c
    libxslt/templates.c
    libxslt/transform.c
    libxslt/variables.c
    libxslt/xslt.c
    libxslt/xsltlocale.c
    libxslt/xsltutils.c
)

add_library(${XSLT_LIB_NAME} ${LIBXSLT_HDRS} ${LIBXSLT_SRCS})

target_include_directories(
    ${XSLT_LIB_NAME}
    PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
)

if(LIBXSLT_WITH_CRYPTO)
    target_link_libraries(${XSLT_LIB_NAME} PRIVATE gcrypt)
endif()

if(ICONV_FOUND)
    target_link_libraries(${XSLT_LIB_NAME} PUBLIC ${ICONV_LIBRARIES})
endif()

target_link_libraries(${XSLT_LIB_NAME} PUBLIC ${LIBXML2_LIBRARIES})

if(UNIX)
    target_link_libraries(${XSLT_LIB_NAME} PRIVATE m)
endif()

if(Threads_FOUND)
    target_link_libraries(${XSLT_LIB_NAME} PRIVATE Threads::Threads)
endif()

set_target_properties(
    ${XSLT_LIB_NAME}
    PROPERTIES
    IMPORT_PREFIX lib
    POSITION_INDEPENDENT_CODE ON
    PREFIX lib
    VERSION ${VERSION}
)

if(WIN32)
    if(BUILD_SHARED_LIBS)
        set_target_properties(
            ${XSLT_LIB_NAME}
            PROPERTIES
            DEBUG_POSTFIX d
        )
    else()
        set_target_properties(
            ${XSLT_LIB_NAME}
            PROPERTIES
            DEBUG_POSTFIX sd
            MINSIZEREL_POSTFIX s
            RELEASE_POSTFIX s
            RELWITHDEBINFO_POSTFIX s
        )
    endif()
endif()

if(OSX_FRAMEWORK)
    set_property(SOURCE ${LIBXSLT_HDRS}
        PROPERTY MACOSX_PACKAGE_LOCATION "Headers/libxslt"
    )
    set_target_properties(${XSLT_LIB_NAME} PROPERTIES
        FRAMEWORK TRUE
        FRAMEWORK_VERSION "${LIBXSLT_FRAMEWORK_VERSION}"
        VERSION ${VERSION}
        SOVERSION "${LIBXSLT_FRAMEWORK_VERSION}"
        MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${VERSION}
        MACOSX_FRAMEWORK_BUNDLE_VERSION ${VERSION}
        MACOSX_FRAMEWORK_IDENTIFIER org.xmlsoft.libxslt
        XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
    )
endif()

set(
    LIBEXSLT_HDRS
    libexslt/exslt.h
    ${CMAKE_CURRENT_BINARY_DIR}/libexslt/exsltconfig.h
    libexslt/exsltexports.h
)

set(
    LIBEXSLT_SRCS
    libexslt/common.c
    libexslt/crypto.c
    libexslt/date.c
    libexslt/dynamic.c
    libexslt/exslt.c
    libexslt/functions.c
    libexslt/libexslt.h
    libexslt/math.c
    libexslt/saxon.c
    libexslt/sets.c
    libexslt/strings.c
)

add_library(${EXSLT_LIB_NAME} ${LIBEXSLT_HDRS} ${LIBEXSLT_SRCS})

target_include_directories(
    ${EXSLT_LIB_NAME}
    PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
)

if(LIBXSLT_WITH_GCRYPT)
    target_link_libraries(${EXSLT_LIB_NAME} PRIVATE gcrypt)
endif()

target_link_libraries(${EXSLT_LIB_NAME} PUBLIC ${XSLT_LIB_NAME} ${LIBXML2_LIBRARIES})

if(UNIX)
    target_link_libraries(${EXSLT_LIB_NAME} PRIVATE m)
endif()

if(Threads_FOUND)
    target_link_libraries(${EXSLT_LIB_NAME} PRIVATE Threads::Threads)
endif()

set_target_properties(
    ${EXSLT_LIB_NAME}
    PROPERTIES
    IMPORT_PREFIX lib
    POSITION_INDEPENDENT_CODE ON
    PREFIX lib
    VERSION ${LIBEXSLT_VERSION}
)

if(WIN32)
    if(BUILD_SHARED_LIBS)
        set_target_properties(
            ${EXSLT_LIB_NAME}
            PROPERTIES
            DEBUG_POSTFIX d
        )
    endif()
endif()

if(OSX_FRAMEWORK)
    set_property(SOURCE ${LIBEXSLT_HDRS}
        PROPERTY MACOSX_PACKAGE_LOCATION "Headers/libexslt"
    )
    set_target_properties(${EXSLT_LIB_NAME} PROPERTIES
        FRAMEWORK TRUE
        FRAMEWORK_VERSION "${LIBEXSLT_FRAMEWORK_VERSION}"
        VERSION ${VERSION}
        SOVERSION "${LIBEXSLT_FRAMEWORK_VERSION}"
        MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${VERSION}
        MACOSX_FRAMEWORK_BUNDLE_VERSION ${VERSION}
        MACOSX_FRAMEWORK_IDENTIFIER org.xmlsoft.libxslt
        XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
    )
endif()

add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

# Export package ===============================================================

# Add all targets to the build-tree export set
export(TARGETS ${XSLT_LIB_NAME} ${EXSLT_LIB_NAME}
   FILE ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Targets.cmake)

if(REGISTER_PACKAGE)
   # Export the package for use from the build-tree
   # (this registers the build-tree with a global CMake-registry)
   export(PACKAGE ${PACKAGE_UPPER_NAME})
endif()

# Create the Config.cmake file
configure_file(cmake/PackageConfig.cmake.in
   ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Config.cmake @ONLY)

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL)

    install(
        TARGETS ${XSLT_LIB_NAME} ${EXSLT_LIB_NAME}
        EXPORT ${PACKAGE_UPPER_NAME}Targets
        ARCHIVE DESTINATION ${INSTALL_LIB_DIR} COMPONENT development
        LIBRARY DESTINATION ${INSTALL_LIB_DIR} COMPONENT runtime NAMELINK_SKIP
        RUNTIME DESTINATION ${INSTALL_BIN_DIR} COMPONENT runtime
        INCLUDES DESTINATION ${INSTALL_INC_DIR}
        FRAMEWORK DESTINATION ${INSTALL_LIB_DIR}
    )
    
    # Install the <Package>Config.cmake
    install(FILES
        ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Config.cmake
        DESTINATION ${INSTALL_CMAKECONF_DIR} COMPONENT dev)

    # Install the export set for use with the install-tree
    install(EXPORT ${PACKAGE_UPPER_NAME}Targets DESTINATION ${INSTALL_CMAKECONF_DIR} COMPONENT dev)
    
    if(MSVC AND BUILD_SHARED_LIBS)
        install(FILES $<TARGET_PDB_FILE:${XSLT_LIB_NAME}> DESTINATION ${INSTALL_BIN_DIR} CONFIGURATIONS Debug RelWithDebInfo COMPONENT debug)
        install(FILES $<TARGET_PDB_FILE:${EXSLT_LIB_NAME}> DESTINATION ${CMAKE_INSTALL_BINDIR} CONFIGURATIONS Debug RelWithDebInfo COMPONENT debug)
    endif()
endif()

if(NOT SKIP_INSTALL_HEADERS AND NOT SKIP_INSTALL_ALL)
   install(FILES ${LIBXSLT_HDRS} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/libxslt COMPONENT development)
   install(FILES ${LIBEXSLT_HDRS} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/libexslt COMPONENT development)
endif()

# Archiving ====================================================================

set(CPACK_PACKAGE_NAME "${PACKAGE_NAME}")
set(CPACK_PACKAGE_VENDOR "${PACKAGE_VENDOR}")
set(CPACK_PACKAGE_VERSION "${VERSION}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PACKAGE_NAME} Installation")
set(CPACK_PACKAGE_RELOCATABLE TRUE)
set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)
set(CPACK_GENERATOR "ZIP")
set(CPACK_MONOLITHIC_INSTALL ON)
set(CPACK_STRIP_FILES TRUE)

# Get cpack zip archive name
get_cpack_filename(${VERSION} PROJECT_CPACK_FILENAME)
set(CPACK_PACKAGE_FILE_NAME ${PROJECT_CPACK_FILENAME})

include(CPack)