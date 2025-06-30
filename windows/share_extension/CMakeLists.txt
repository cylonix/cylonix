cmake_minimum_required(VERSION 3.15)
project(CylonixShare)

# Set CMake policy version
cmake_policy(VERSION 3.15)

# C++17 for filesystem support
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find nlohmann_json package
find_package(nlohmann_json CONFIG REQUIRED)

# Source files
set(SOURCES
    src/main.cpp
    src/share_handler.cpp
    src/share_window.cpp
    resources/resources.rc
    resources/app.manifest
)

# Option for debug testing
option(DEBUG_TEST "Build for debug testing" OFF)

if(DEBUG_TEST)
    add_executable(ShareTest WIN32 ${SOURCES})
    target_compile_definitions(ShareTest PRIVATE 
        _DEBUG 
        SHARE_TEST_MODE
    )
    target_include_directories(ShareTest PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${CMAKE_CURRENT_SOURCE_DIR}/resources
    )
    target_link_libraries(ShareTest PRIVATE
        comctl32
        nlohmann_json::nlohmann_json
    )
else()
    add_executable(CylonixShare WIN32 ${SOURCES})
    target_include_directories(CylonixShare PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${CMAKE_CURRENT_SOURCE_DIR}/resources
    )
    target_link_libraries(CylonixShare PRIVATE
        comctl32
        nlohmann_json::nlohmann_json
    )
endif()