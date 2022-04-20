#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;94m'
MAGENTA="\033[0;35m"
NC='\033[0m'

print_red() {
    echo -e "${RED}${1}${NC}"
}
print_blue() {
    echo -e "${BLUE}${1}${NC}"
}
print_green() {
    echo -e "${GREEN}${1}${NC}"
}
print_yellow() {
    echo -e "${YELLOW}${1}${NC}"
}

print_dry() {
    echo -e "${MAGENTA}[DryRun] $*${NC}"
}

no_host_check="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
