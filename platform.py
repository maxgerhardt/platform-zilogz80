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

import platform
from platformio.public import PlatformBase
from platformio import util
import sys

class Zilogz80Platform(PlatformBase):

    def is_embedded(self) -> bool:
        return True

    toolchain_clangz80 = {
        # Windows
        "windows_amd64": "https://github.com/maxgerhardt/toolchain-clangz80.git#windows_x64",
        #"windows_x86": ""
        # No Windows x86, ARM64 or ARM32 builds.
        # Linux
        "linux_x86_64": "https://github.com/maxgerhardt/toolchain-clangz80.git#linux_x64",
        #"linux_i686": "",
        #"linux_aarch64": "",
        #"linux_armv7l": "",
        #"linux_armv6l": "",
        # Mac (Intel and ARM are the separate)
        #"darwin_x86_64": "",
        #"darwin_arm64": ""
    }

    def configure_default_packages(self, variables, targets):
        sys_type = util.get_systype()
        # get the correct toolchain-clangz80 version for the host system
        self.packages["toolchain-clangz80"]["version"] = Zilogz80Platform.toolchain_clangz80[sys_type]
        return super().configure_default_packages(variables, targets)