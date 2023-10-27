cmake_minimum_required(VERSION 3.10)
project(lua VERSION 5.4.7)

# Set C standard
set(CMAKE_C_STANDARD 99)

# Lua core library sources
set(LUA_CORE_SOURCES
    lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c
    lfunc.c lgc.c llex.c lmem.c lobject.c lopcodes.c
    lparser.c lstate.c lstring.c ltable.c ltm.c
    lundump.c lvm.c lzio.c
)

# Lua library sources
set(LUA_LIB_SOURCES
    lauxlib.c lbaselib.c lcorolib.c ldblib.c liolib.c
    lmathlib.c loslib.c lstrlib.c ltablib.c lutf8lib.c
    loadlib.c linit.c
)

# Create shared library (DLL)
add_library(lua SHARED ${LUA_CORE_SOURCES} ${LUA_LIB_SOURCES})
target_compile_definitions(lua PRIVATE LUA_BUILD_AS_DLL)

# Create static library
add_library(lua_static STATIC ${LUA_CORE_SOURCES} ${LUA_LIB_SOURCES})
set_target_properties(lua_static PROPERTIES OUTPUT_NAME lua)

# Create lua interpreter
add_executable(lua_exe lua.c)
target_link_libraries(lua_exe lua)
set_target_properties(lua_exe PROPERTIES OUTPUT_NAME lua)

# Create lua compiler
add_executable(luac luac.c)
target_link_libraries(luac lua_static)

# Installation
install(TARGETS lua lua_static lua_exe luac
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

install(FILES lua.h luaconf.h lualib.h lauxlib.h lua.hpp
    DESTINATION include
)