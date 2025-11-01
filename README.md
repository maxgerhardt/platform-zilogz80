# Zilog Z80: development platform for [PlatformIO](https://platformio.org)

[![Build Status](https://github.com/maxgerhardt/platform-zilogz80/workflows/Examples/badge.svg)](https://github.com/maxgerhardt/platform-zilogz80/actions)

Zilog's Z80 and eZ80 series combine proven design with modern enhancements for demanding embedded systems. The eZ80 retains the 8-bit instruction set of the classic Z80 while introducing 24-bit registers and a 24-bit linear address space in ADL mode, enabling single-cycle pipelined execution across up to 16 MB of memory. With on-chip Flash and SRAM, UART, SPI, I²C, IrDA, timers, and a real-time clock, plus JTAG and ZDI debug support and low-power modes, it delivers high performance and flexibility while remaining fully compatible with legacy Z80 software.

* [Home](https://registry.platformio.org/platforms/maxgerhardt/zilogz80) (home page in the PlatformIO Registry)
* [Documentation](https://docs.platformio.org/page/platforms/zilogz80.html) (advanced usage, packages, boards, frameworks, etc.)

# Usage

1. [Install PlatformIO](https://platformio.org)
2. Create PlatformIO project and configure a platform option in [platformio.ini](https://docs.platformio.org/page/projectconf.html) file:

## Stable version

```ini
[env:stable]
platform = zilogz80
board = ...
...
```

## Development version

```ini
[env:development]
platform = https://github.com/maxgerhardt/platform-zilogz80.git
board = ...
...
```

# Configuration

Please navigate to [documentation](https://docs.platformio.org/page/platforms/zilogz80.html).
