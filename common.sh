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

#------------Decoration-----------#
anim=(
  "${BLUE}•${GREEN}•${RED}•${MAGENTA}•    "
  " ${GREEN}•${RED}•${MAGENTA}•${BLUE}•   "
  "  ${RED}•${MAGENTA}•${BLUE}•${GREEN}•  "
  "   ${MAGENTA}•${BLUE}•${GREEN}•${RED}• "
  "    ${BLUE}•${GREEN}•${RED}•${MAGENTA}•"
)

start_animation() {
  setterm -cursor off

  (
    while true; do
      for i in {0..4}; do
        echo -ne "\r\033[2K                         ${anim[i]}"
        sleep 0.1
      done

      for i in {4..0}; do
        echo -ne "\r\033[2K                         ${anim[i]}"
        sleep 0.1
      done
    done
  ) &

  export ANIM_PID="${!}"
}

stop_animation() {
  [[ -e "/proc/${ANIM_PID}" ]] && kill -13 "${ANIM_PID}"
  setterm -cursor on
}

test() {
    start_animation; sleep 5; stop_animation
    echo
}