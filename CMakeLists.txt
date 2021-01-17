cmake_minimum_required(VERSION 3.10)

project(Blink)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_EXPORT_COMPILE_COMMANDS 1)
set(CMAKE_CXX_COMPILER_LAUNCHER /usr/bin/ccache)
add_executable(blink src/main.cpp)
target_include_directories(blink PUBLIC
  "include"
  )
