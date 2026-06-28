cmake_minimum_required(VERSION 3.16)
project(GIFCopier VERSION 2.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ── Platform source selection ─────────────────────────────────────────────────
set(PLATFORM_SRC "")
if(WIN32)
    list(APPEND PLATFORM_SRC app_win.cpp)
    message(STATUS "Building for Windows")
elseif(UNIX AND NOT APPLE)
    list(APPEND PLATFORM_SRC app_linux.cpp)
    message(STATUS "Building for Linux")
else()
    message(FATAL_ERROR "Unsupported platform. Only Windows and Linux are supported.")
endif()

# ── Main executable ───────────────────────────────────────────────────────────
add_executable(ClipApp clipapp.cpp ${PLATFORM_SRC})

target_compile_options(ClipApp PRIVATE
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
    $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall -Wextra>
)

# Windows: link Shell32 for SHGetKnownFolderPath / DROPFILES
if(WIN32)
    target_link_libraries(ClipApp PRIVATE shell32)
endif()

# ── Tests ─────────────────────────────────────────────────────────────────────
option(BUILD_TESTS "Build unit tests" OFF)

if(BUILD_TESTS)
    enable_testing()

    include(FetchContent)
    FetchContent_Declare(
        googletest
        URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
    )
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)

    add_executable(clipapp_test app_test.cpp ${PLATFORM_SRC})
    target_link_libraries(clipapp_test PRIVATE GTest::gtest_main)

    include(GoogleTest)
    gtest_discover_tests(clipapp_test)
endif()

# ── Install ───────────────────────────────────────────────────────────────────
install(TARGETS ClipApp DESTINATION .)
