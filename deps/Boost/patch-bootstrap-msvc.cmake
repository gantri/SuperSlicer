# Names the toolset used to build the b2 engine, so that build.bat does not have to guess
# it with vswhere. Boost.Build 4.3 only knows up to Visual Studio 2019 and resolves anything
# newer to "vcunk", a toolset its own config_toolset.bat never dispatches, which fails the
# engine build with "Unknown toolset: vcunk".
#
# Run from the Boost source directory as the patch step of dep_Boost:
#     cmake -P <this file>

set(_bootstrap "bootstrap.bat")
set(_from "call .\\build.bat")
set(_to "call .\\build.bat vc142")

if (NOT EXISTS "${_bootstrap}")
    message(FATAL_ERROR "${_bootstrap} not found in ${CMAKE_CURRENT_SOURCE_DIR}")
endif ()

file(READ "${_bootstrap}" _content)

if (_content MATCHES "build\\.bat vc142")
    message(STATUS "${_bootstrap} already names the engine toolset")
    return()
endif ()

string(REPLACE "${_from}" "${_to}" _patched "${_content}")

if (_patched STREQUAL _content)
    message(FATAL_ERROR "Could not find '${_from}' in ${_bootstrap}: the Boost version changed "
                        "and this patch needs to be revisited")
endif ()

file(WRITE "${_bootstrap}" "${_patched}")
message(STATUS "Patched ${_bootstrap} to build the b2 engine with the vc142 toolset")
