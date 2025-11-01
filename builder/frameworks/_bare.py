"""
Baremetal framework for Z80/eZ80 microcontrollers
"""

from os.path import join

from SCons.Script import DefaultEnvironment

env = DefaultEnvironment()
platform = env.PioPlatform()
board = env.BoardConfig()

_toolchain_dir = platform.get_package_dir("toolchain-clangz80") or ""

env.Append(
    ASFLAGS=[
        "-Wa,-march=ez80+adl",  # eZ80 in ADL mode
        "--target=ez80-none-elf",
    ],
    
    CPPPATH=[
        join(_toolchain_dir, "include"),
        join(_toolchain_dir, "include", "c++")
    ],
    
    CCFLAGS=[
        "-Wa,-march=ez80+full",
        "--target=ez80-none-elf",
        "-Oz",  # Optimize for size
        "-Wall",
    ],
    
    CXXFLAGS=[
        "-std=gnu++17",
        "-fno-threadsafe-statics",
        "-fno-rtti",
        "-fno-exceptions"
    ],
    
    LINKFLAGS=[
        #"--oformat", "elf32-z80",
        "-nostdlib",
        "-defsym=RAM_START=0x40000",
        "-defsym=RAM_SIZE=0x70000",
    ],
    
    LIBS=[]
)