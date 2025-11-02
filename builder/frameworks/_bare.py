"""
Baremetal framework for Z80/eZ80 microcontrollers
"""

from os.path import join

from SCons.Script import DefaultEnvironment

env = DefaultEnvironment()
platform = env.PioPlatform()
board = env.BoardConfig()

_toolchain_dir = platform.get_package_dir("toolchain-clangz80") or ""

machine_flags = [
    "-Wa,-march=ez80+adl",  # eZ80 in ADL mode
    "--target=ez80-none-elf",
]

env.Append(
    ASFLAGS=machine_flags,
    
    CPPPATH=[
        join(_toolchain_dir, "include"),
        join(_toolchain_dir, "include", "c++")
    ],
    
    CCFLAGS=machine_flags + [
        "-Oz",  # Optimize for size
        "-Wall",
        "-ffunction-sections",  # place each function in its own section
        "-fdata-sections",      # place each variable in its own section
    ],
    
    CXXFLAGS=[
        "-std=gnu++17",
        "-fno-threadsafe-statics",
        "-fno-rtti",
        "-fno-exceptions"
    ],

    CPPDEFINES=[
        ("F_CPU", "$BOARD_F_CPU")
    ],

    LINKFLAGS=[
        #"--oformat", "elf32-z80",
        "--no-warn-rwx-segments",
        "-nostdlib",
        "--gc-sections",
        #"--relax",
        # "--print-gc-sections",
        "-defsym=RAM_START=0x40000",
        "-defsym=RAM_SIZE=0x80000",
    ],
    
    LIBS=[
        # commonly needed functions for compiler builtins like multiplication, but without the crt0 __start routine 
        File(join(_toolchain_dir, "lib", "libcrt_no_crt0.a"))
    ]
)