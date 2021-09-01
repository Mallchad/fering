# GPL3 License
# Copyright (c) 2021 Mallchad
# This source provides the right to be freely used in any form, so long as modified
# variations remain available publically, or open request.
# Modified versions must be marked as such.
# The source comes with no warranty of any kind.

cmake_minimum_required(VERSION 3.10)

project(fering)

# Build Calls


# Core
add_executable(fering src/main.cpp)
target_include_directories(fering PUBLIC "include")
target_compile_definitions(fering PUBLIC FERING_DEBUG=${FERING_DEBUG})

# Dependencies
add_library(cxxopts STATIC include)

# Variables
message(${CMAKE_BINARY_DIR})
set(FERING_BUILD_DIR ${CMAKE_BINARY_DIR}
  CACHE STRING "A custom path for the build directory")
set(FERING_BINARY_DIR ${FERING_BUILD_DIR}/bin
  CACHE STRING "A custom path for the binary output directory")
set(FERING_LIBRARY_DIR ${FERING_BUILD_DIR}/bin
  CACHE STRING "A custom path for the library output directory")
set(FERING_ARTIFACT_DIR ${FERING_BUILD_DIR}/bin
  CACHE STRING "A custom path for the build artifact output directory")
set(FERING_DEBUG_DIR ${FERING_BUILD_DIR}/debug
  CACHE STRING "A custom path for the build artifact output directory")
set(FERING_DEBUG true
  CACHE STRING "")
# Attempt to parallelize build
include(ProcessorCount)
ProcessorCount(CPU_CORES)
if(NOT CPU_CORES EQUAL 0)
  set(CMAKE_BUILD_PARALLEL_LEVEL ${CPU_CORES})
endif(NOT CPU_CORES EQUAL 0)

# Enable Compiler Cache if possible
find_program(CCACHE_FOUND ccache)
if(CCACHE_FOUND)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
  message("ccache : Detected program launcher will be used")
endif(CCACHE_FOUND)

# Use clang compiler if possible
find_program(CLANG_FOUND clang)
if(CLANG_FOUND)
  set(CMAKE_CXX_COMPILER "/usr/bin/clang++")
  message("clang : Detected compiler will be used")
endif(CLANG_FOUND)

# Target Properties
set_target_properties(fering PROPERTIES
  CXX_STANDARD 17
  # Output Direcorties
  # The '$<0:>' is a cmake generator expression to prevent multi-target build
  # generators like Microsoft Visual Studio from manipulating output directories
  RUNTIME_OUTPUT_DIRECTORY ${FERING_BINARY_DIR}$<0:>
  LIBRARY_OUTPUT_DIRECTORY ${FERING_LIBRARY_DIR}$<0:>
  ARCHIVE_OUTPUT_DIRECTORY ${FERING_ARTIFACT_DIR}$<0:>
  COMPILE_PDB_OUTPUT_DIRECTORY ${FERING_DEBUG_DIR}$<0:>)

set_target_properties(cxxopts PROPERTIES LINKER_LANGUAGE CXX
  LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin$<0:>
  ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin$<0:>)
