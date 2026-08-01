#!/usr/bin/env bash
# colors.sh — ANSI color codes for installer output
# Source this file; never execute directly.
# All variables are exported so child scripts inherit them.

# Disable colors if stdout is not a terminal or NO_COLOR is set
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    export C_RESET=$'\033[0m'
    export C_BOLD=$'\033[1m'
    export C_DIM=$'\033[2m'
    export C_RED=$'\033[31m'
    export C_GREEN=$'\033[32m'
    export C_YELLOW=$'\033[33m'
    export C_BLUE=$'\033[34m'
    export C_MAGENTA=$'\033[35m'
    export C_CYAN=$'\033[36m'
else
    export C_RESET="" C_BOLD="" C_DIM=""
    export C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_MAGENTA="" C_CYAN=""
fi
