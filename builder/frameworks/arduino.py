# Copyright 2014-present PlatformIO <contact@platformio.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
Arduino

Arduino Wiring-based Framework allows writing cross-platform software to
control devices attached to a wide range of Arduino boards to create all
kinds of creative coding, interactive objects, spaces or physical experiences.

http://arduino.cc/en/Reference/HomePage
"""

from os.path import isdir, join, isfile

from SCons.Script import DefaultEnvironment

env = DefaultEnvironment()
platform = env.PioPlatform()
board = env.BoardConfig()
build_core = board.get("build.core", "")
variant = board.get(
    "build.variant", board.get("build.arduino.variant", "generic")
)

FRAMEWORK_DIR = platform.get_package_dir("framework-arduinoez80")
assert isdir(FRAMEWORK_DIR)

env.SConscript("_bare.py", exports="env")

env.Append(
    CFLAGS=[
        "-std=gnu11",
    ],

    CXXFLAGS=[
        "-fpermissive"
    ],

    CPPDEFINES=[
        ("F_CPU", "$BOARD_F_CPU"),
        "ARDUINO_ARCH_EZ80",
        ("ARDUINO", 10808)
    ],

    #LIBS=["m"],

    LIBSOURCE_DIRS=[
        join(FRAMEWORK_DIR, "libraries")
    ],

    CPPPATH=[
        join(FRAMEWORK_DIR, "cores", build_core)
    ]
)

#
# Linker requires preprocessing with correct RAM|ROM sizes
#

variants_dir = (
    join(env.subst("$PROJECT_DIR"), board.get("build.variants_dir"))
    if board.get("build.variants_dir", "")
    else join(FRAMEWORK_DIR, "variants")
)
variant_dir = join(variants_dir, variant)

if not board.get("build.ldscript", ""):
    if not isfile(join(env.subst(variant_dir), "ldscript.ld")):
        print("Warning! Cannot find linker script for the current target!\n")
    env.Replace(LDSCRIPT_PATH=join(env.subst(variant_dir), "ldscript.ld"))

#
# Target: Build Core Library
#

libs = []

if "build.variant" in board:
    env.Append(
        CPPPATH=[
            join(variants_dir, board.get("build.variant"))
        ]
    )
    libs.append(env.BuildLibrary(
        join("$BUILD_DIR", "FrameworkArduinoVariant"),
        join(variants_dir, board.get("build.variant"))
    ))

libs.append(env.BuildLibrary(
    join("$BUILD_DIR", "FrameworkArduino"),
    join(FRAMEWORK_DIR, "cores", build_core)
))

env.Prepend(LIBS=libs)