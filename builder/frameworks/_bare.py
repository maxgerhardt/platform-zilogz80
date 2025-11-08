"""
Baremetal framework for Z80/eZ80 microcontrollers
"""

from os.path import join

from SCons.Script import DefaultEnvironment

env = DefaultEnvironment()
platform = env.PioPlatform()
board = env.BoardConfig()

_toolchain_dir = platform.get_package_dir("toolchain-clangz80") or ""

flash_size = int(board.get("upload.maximum_size"))
extram_size = int(board.get("upload.maximum_ram_size"))
extram_start = int(board.get("upload.ram_start", "0x40000"), 0)
intram_size = int(board.get("upload.maximum_intram_size", "0"))
intram_start = int(board.get("upload.intram_start", "0xb7e000"), 0)

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
        "-O3",  # Optimize for size
        "-Wall",
        "-ffunction-sections",  # place each function in its own section
        "-fdata-sections",      # place each variable in its own section
        "-fshort-enums",
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
        "-defsym=EXTRAM_START=%s" % hex(extram_start),
        "-defsym=EXTRAM_SIZE=%s" % hex(extram_size),
        "-defsym=INTRAM_START=%s" % hex(intram_start),
        "-defsym=INTRAM_SIZE=%s" % hex(intram_size),
        "-defsym=FLASH_SIZE=%s" % hex(flash_size)
    ],
    
    LIBS=[
        # commonly needed functions for compiler builtins like multiplication, but without the crt0 __start routine 
        File(join(_toolchain_dir, "lib", "libcrt_no_crt0.a"))
    ]
)