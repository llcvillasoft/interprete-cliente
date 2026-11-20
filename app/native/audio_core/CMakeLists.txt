cmake_minimum_required(VERSION 3.16)
project(audio_core C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# miniaudio v0.11.26, vendorizado en third_party/miniaudio (dominio público o MIT-0).
set(MINIAUDIO_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/miniaudio")

add_library(audio_core SHARED src/audio_core.c)
target_include_directories(audio_core
  PUBLIC  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  PRIVATE "${MINIAUDIO_DIR}")
target_compile_definitions(audio_core PRIVATE AUDIO_CORE_BUILD)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  target_link_libraries(audio_core PRIVATE pthread m dl)
endif()

if(MSVC)
  target_compile_options(audio_core PRIVATE /W3)
else()
  target_compile_options(audio_core PRIVATE -Wall -Wextra -Wno-unused-parameter)
endif()

enable_testing()

add_executable(test_audio_core test/test_audio_core.c)
target_link_libraries(test_audio_core PRIVATE audio_core)
add_test(NAME audio_core COMMAND test_audio_core)
