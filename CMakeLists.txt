cmake_minimum_required(VERSION 3.10)

project(Blink)
# Output Direcorties
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/artifacts)
set(CMAKE_COMPILE_PDB_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/debug)
# Variables
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS 1)
set(CMAKE_CXX_COMPILER_LAUNCHER /usr/bin/ccache)
# Build Calls
add_library(cxxopts STATIC include)
set_target_properties(cxxopts PROPERTIES LINKER_LANGUAGE CXX)
add_executable(blink src/main.cpp)
target_include_directories(blink PUBLIC
  "include"
  )
