cmake_minimum_required(VERSION 3.16)
project(DPIEngine VERSION 2.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Threads REQUIRED)

set(COMMON_SOURCES
    src/pcap_reader.cpp
    src/packet_parser.cpp
    src/sni_extractor.cpp
    src/types.cpp
)

add_executable(dpi_engine src/dpi_mt.cpp ${COMMON_SOURCES})
target_include_directories(dpi_engine PRIVATE ${CMAKE_SOURCE_DIR}/include)
target_link_libraries(dpi_engine PRIVATE Threads::Threads)

add_executable(dpi_simple src/main_working.cpp ${COMMON_SOURCES})
target_include_directories(dpi_simple PRIVATE ${CMAKE_SOURCE_DIR}/include)
target_link_libraries(dpi_simple PRIVATE Threads::Threads)

if(MSVC)
    target_compile_options(dpi_engine PRIVATE /EHsc /W3 /utf-8)
    target_compile_options(dpi_simple PRIVATE /EHsc /W3 /utf-8)
else()
    target_compile_options(dpi_engine PRIVATE -Wall -O2)
    target_compile_options(dpi_simple PRIVATE -Wall -O2)
endif()
