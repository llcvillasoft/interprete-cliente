cmake_minimum_required(VERSION 3.16)
project(whisper_core C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# whisper.cpp v1.9.6, traído con FetchContent y enlazado estáticamente dentro de
# la biblioteca compartida, para que la app solo cargue un archivo.
include(FetchContent)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
FetchContent_Declare(whisper
  GIT_REPOSITORY https://github.com/ggml-org/whisper.cpp
  GIT_TAG v1.9.6
  GIT_SHALLOW TRUE)
FetchContent_MakeAvailable(whisper)

add_library(whisper_core SHARED src/whisper_core.c)
target_include_directories(whisper_core
  PUBLIC  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  PRIVATE "${whisper_SOURCE_DIR}/include")
target_compile_definitions(whisper_core PRIVATE WHISPER_CORE_BUILD)
target_link_libraries(whisper_core PRIVATE whisper)

enable_testing()
add_executable(test_whisper_core test/test_whisper_core.c)
target_link_libraries(test_whisper_core PRIVATE whisper_core)
add_test(NAME whisper_core COMMAND test_whisper_core)
