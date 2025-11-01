"""
    Builder for Z80/eZ80 platform
"""

from platform import system
from os.path import join

from SCons.Script import COMMAND_LINE_TARGETS, AlwaysBuild, Builder, Default, DefaultEnvironment
import sys
import subprocess
import importlib


def _ensure_xmodem_installed():
    """Ensure the `xmodem` package is available in the Python environment
    running SCons/PlatformIO. If missing, try to install it into the
    current interpreter using pip.
    """
    try:
        import xmodem  # noqa: F401
        return
    except Exception:
        pass

    try:
        print("`xmodem` not found — installing via pip into current Python environment...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "xmodem", "--no-input"])
        # Invalidate import caches so subsequent imports work
        importlib.invalidate_caches()
    except Exception as e:
        print("Failed to install `xmodem` automatically:", e)
        print("You may need to install it manually in the PlatformIO Python environment:")
        print("    {} -m pip install xmodem".format(sys.executable))


# Ensure runtime dependency for uploader scripts (ez80_upload.py)
_ensure_xmodem_installed()

env = DefaultEnvironment()
platform = env.PioPlatform()
board = env.BoardConfig()

# Wrapper that normalizes path separators before calling the real clang
# This will be used to set CC/CXX so every compile invocation goes
# through the wrapper and gets cleaned up for Windows clang quirks.
_wrapper = join(platform.get_dir() or "", "builder", "clang_wrapper.py").replace('\\', '/')
_real_clang = join(platform.get_package_dir("toolchain-clangz80") or "", "bin", "ez80-none-elf-clang.exe").replace('\\', '/')
_wrapper_cmd = '"$PYTHONEXE" "%s" "%s"' % (_wrapper, _real_clang)

env.Replace(
    AR="ez80-none-elf-ar",
    AS="ez80-none-elf-as",
    CC=_wrapper_cmd,
    CXX=_wrapper_cmd,
    GDB="ez80-none-elf-gdb",
    LINK="ez80-none-elf-ld",
    OBJCOPY="ez80-none-elf-objcopy",
    OBJDUMP="ez80-none-elf-objdump",
    RANLIB="ez80-none-elf-ranlib",
    SIZETOOL="ez80-none-elf-size",

    ARFLAGS=["rc"],

    SIZEPROGREGEXP=r"^(?:\.init|\.text|\.data|\.rodata|\.text\.align)\s+(\d+).*",
    SIZEDATAREGEXP=r"^(?:\.data|\.bss|\.noinit)\s+(\d+).*",
    SIZECHECKCMD="$SIZETOOL -A -d $SOURCES",
    SIZEPRINTCMD='$SIZETOOL -B -d $SOURCES',
    
    PROGSUFFIX=".elf"
)

def is_pio_build():
	from SCons.Script import COMMAND_LINE_TARGETS
	return all([x not in COMMAND_LINE_TARGETS for x in ["idedata", "_idedata", "__idedata"]])

# TODO Remove this. This is a hacky workaround to still emit the right compiler path for the intellisense
# instead of our python wrapper. We need to rebuild clang.exe natively on MINGW64 instead of MSYS2 to 
# eliviate the need for the wrapper altogether.
if not is_pio_build():
    env.Replace(CC="ez80-none-elf-clang.exe", CXX="ez80-none-elf-clang.exe")

env.Append(
    BUILDERS=dict(
        ElfToBin=Builder(
            action=env.VerboseAction(" ".join([
                "$OBJCOPY",
                "-O",
                "binary",
                "$SOURCES",
                "$TARGET"
            ]), "Building $TARGET"),
            suffix=".bin"
        ),
        ElfToHex=Builder(
            action=env.VerboseAction(" ".join([
                "$OBJCOPY",
                "-O",
                "ihex",
                "-R",
                ".eeprom",
                "$SOURCES",
                "$TARGET"
            ]), "Building $TARGET"),
            suffix=".hex"
        ),
        Disassemble=Builder(
            action=env.VerboseAction(" ".join([
                "$OBJDUMP",
                "-d",
                "$SOURCES",
                ">",
                "$TARGET"
            ]), "Building disassembly $TARGET"),
            suffix=".lst"
        ),
        DisassembleDebug=Builder(
            action=env.VerboseAction(" ".join([
                "$OBJDUMP",
                "-d",
                "-S",
                "$SOURCES",
                ">",
                "$TARGET"
            ]), "Building debug disassembly $TARGET"),
            suffix=".debug.lst"
        )
    )
)

# Allow user to override via pre:script
if env.get("PROGNAME", "program") == "program":
    env.Replace(PROGNAME="firmware")

if not env.get("PIOFRAMEWORK"):
    env.SConscript("frameworks/_bare.py")

#
# Target: Build executable and linkable firmware
#
target_elf = None
if "nobuild" in COMMAND_LINE_TARGETS:
    target_elf = join("$BUILD_DIR", "${PROGNAME}.elf")
    target_hex = join("$BUILD_DIR", "${PROGNAME}.hex")
    target_bin = join("$BUILD_DIR", "${PROGNAME}.bin")
else:
    target_elf = env.BuildProgram()
    target_hex = env.ElfToHex(join("$BUILD_DIR", "${PROGNAME}"), target_elf)
    target_bin = env.ElfToBin(join("$BUILD_DIR", "${PROGNAME}"), target_elf)
    target_lst = env.Disassemble(join("$BUILD_DIR", "${PROGNAME}"), target_elf)
    target_debug = env.DisassembleDebug(join("$BUILD_DIR", "${PROGNAME}"), target_elf)

AlwaysBuild(env.Alias("nobuild", [target_hex, target_bin, target_lst, target_debug]))
AlwaysBuild(env.Alias("buildprog", [target_hex, target_bin, target_lst, target_debug]))

#
# Target: Print binary size
#
target_size = env.Alias(
    "size", target_elf,
    env.VerboseAction("$SIZEPRINTCMD", "Calculating size $SOURCE"))
AlwaysBuild(target_size)

#
# Target: Upload firmware
#
upload_protocol = env.subst("$UPLOAD_PROTOCOL")
debug_tools = board.get("debug.tools", {})

if upload_protocol.startswith("zdi"):
    env.Replace(
        UPLOADER="$PYTHONEXE",
        UPLOADERFLAGS=[
            "-u", # unbuffered, makes output visible immediately
            '"%s"' % join(
                platform.get_package_dir("tool-zdiprobe") or "",
                "ez80_upload.py"
            ),
            "-p", "$UPLOAD_PORT",
            "flash",
            "-r"  # Always reset after flashing
        ],
        UPLOADCMD="$UPLOADER $UPLOADERFLAGS $SOURCE"
    )
    
    upload_actions = [
        env.VerboseAction(env.AutodetectUploadPort, "Looking for upload port..."),
        env.VerboseAction("$UPLOADCMD", "Uploading $SOURCE")
    ]

AlwaysBuild(env.Alias("upload", target_bin, upload_actions))

#
# Setup default targets
#
Default([target_hex, target_bin, target_lst, target_debug, target_size])