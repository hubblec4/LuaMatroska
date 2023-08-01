# LuaMatroska

This is a library to parse Matroska files.

All Matroska elements are defined and additional there is some internal logic for easy use.

## Matroska Block structure

The internal Matroska Block structure is currently not parsed.

### Lua versions

LuaMatroska has some sort of "compiler switches" to still support older Lua versions that don't do bit operations.
Older versions means Lua5.1, Lua5.2 and LuaJIT. Since Lua5.3 bit operations are supported.
