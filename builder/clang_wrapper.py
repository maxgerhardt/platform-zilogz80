#!/usr/bin/env python3
"""
Small wrapper to normalize Windows path separators to POSIX-style
before invoking the real clang binary. This addresses toolchains that
reject backslash separators for temporary files or input paths.

Usage:
    python clang_wrapper.py <real_compiler> [args...]

The wrapper replaces all backslashes in all arguments with '/'
and execs the real compiler with the cleaned arguments.
"""
import sys
import subprocess


def main():
    if len(sys.argv) < 2:
        print("Usage: clang_wrapper.py <real_compiler> [args...]", file=sys.stderr)
        return 2

    real = sys.argv[1]
    args = sys.argv[2:]

    # Normalize backslashes -> forward slashes in all args
    norm = [a.replace('\\', '/') for a in args]

    # Invoke the real compiler
    try:
        rc = subprocess.call([real] + norm)
        return rc
    except FileNotFoundError:
        print("Compiler not found:", real, file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
