declare -r TRUE=0
declare -r FALSE=1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;94m'
DARK_GREY='\033[0;90m'
NC='\033[0m'

print_red() {
    echo -e "${RED}${1}${NC}"
    return 0
}

print_green() {
    echo -e "${GREEN}${1}${NC}"
    return 0
}
print_yellow() {
    echo -e "${YELLOW}${1}${NC}"
    return 0
}
print_blue() {
    echo -e "${BLUE}${1}${NC}"
    return 0
}

print_grey() {
    echo -e "${DARK_GREY}${1}${NC}"
    return 0
}

no_host_check="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=quiet"

alias gitlog='git log --graph --all --pretty=oneline'
alias ap='sudo ip netns exec ccu_dcu ssh ${no_host_check} 10.0.6.0'

alias builder5='ssh felipe@builder5.sonatus-internal'
alias builder7='ssh felipe@builder7.sonatus-internal'
alias tester1='ssh felipe@ccu-tester-1.sonatus-internal'
alias tester2='ssh felipe@ccu-tester-2.sonatus-internal'
alias tester3='ssh felipe@ccu-tester-3.sonatus-internal'
alias tester4='ssh felipe@ccu-tester-4.sonatus-internal'
alias tester5='ssh felipe@ccu-tester-5.sonatus-internal'
alias tester6='ssh felipe@ccu-tester-6.sonatus-internal'
alias tester7='ssh felipe@ccu-tester-7.sonatus-internal'
alias tester8='ssh felipe@ccu-tester-8.sonatus-internal'
alias tester9='ssh felipe@ccu-tester-9.sonatus-internal'
alias tester10='ssh felipe@ccu-tester-10.sonatus-internal'
alias tester11='ssh felipe@ccu-tester-11.sonatus-internal'

alias tester2-1='ssh felipe@ccu2-tester-1.sonatus-internal'
alias tester2-2='ssh felipe@ccu2-tester-2.sonatus-internal'
alias tester2-3='ssh felipe@ccu2-tester-3.sonatus-internal'
alias tester2-4='ssh felipe@ccu2-tester-4.sonatus-internal'
alias tester2-5='ssh felipe@ccu2-tester-5.sonatus-internal'
alias tester2-6='ssh felipe@ccu2-tester-6.sonatus-internal'
alias tester2-7='ssh felipe@ccu2-tester-7.sonatus-internal'
alias tester2-8='ssh felipe@ccu2-tester-8.sonatus-internal'
alias tester2-9='ssh felipe@ccu2-tester-9.sonatus-internal'
alias tester2-10='ssh felipe@ccu2-tester-10.sonatus-internal'
alias tester2-11='ssh felipe@ccu2-tester-11.sonatus-internal'
alias tester2-100='ssh felipe@ccu2-tester-100.sonatus-internal'
alias tester2-101='ssh felipe@ccu2-tester-101.sonatus-internal'
alias tester2-102='ssh felipe@ccu2-tester-102.sonatus-internal'

alias win2-1='ssh snbuilder@ccu2-win-1.sonatus-internal'
alias win2-2='ssh snbuilder@ccu2-win-2.sonatus-internal'
alias win2-3='ssh snbuilder@ccu2-win-3.sonatus-internal'
alias win2-4='ssh snbuilder@ccu2-win-4.sonatus-internal'
alias win2-5='ssh snbuilder@ccu2-win-5.sonatus-internal'
alias win2-6='ssh snbuilder@ccu2-win-6.sonatus-internal'
alias win2-7='ssh snbuilder@ccu2-win-7.sonatus-internal'
alias win2-8='ssh snbuilder@ccu2-win-8.sonatus-internal'
alias win2-9='ssh snbuilder@ccu2-win-9.sonatus-internal'
alias win2-10='ssh snbuilder@ccu2-win-10.sonatus-internal'
alias win2-11='ssh snbuilder@ccu2-win-11.sonatus-internal'
alias win2-100='ssh snbuilder@ccu2-win-100.sonatus-internal'
alias win2-101='ssh snbuilder@ccu2-win-101.sonatus-internal'
alias win2-102='ssh snbuilder@ccu2-win-102.sonatus-internal'

# Git clone CCU2-manifest repository into $1
manifest() {
    git clone git@github.com:sonatus/CCU_GEN2.0_SONATUS.manifest.git $1 
}

# scp $1 to 10.0.6.0:/download 
scp_ccu() {
    sudo ip netns exec ccu_dcu ssh ${no_host_check} 10.0.6.0 mount -o remount,rw /
    sudo ip netns exec ccu_dcu scp ${no_host_check} -r $1 10.0.6.0:/download
}

get_local_station_info() {
    ccu_num=$(awk -F '-' '{print $3}' <<< $HOSTNAME)
    win_server="ccu2-win-${ccu_num}.sonatus-internal"
    windows_boot_dir="C:\Users\snbuilder\Desktop\SerialDownload"
    set_serial_normal="set_serial.py 2"
}

reset_board() {
    get_local_station_info
    echo ""
    print_yellow "============================================================================="
    print_yellow "Resetting the CCU board ..."
    reset_cmd="cd ${windows_boot_dir} && power_off.py && ${set_serial_normal} && power_on.py"
    print_grey "reset_cmd: ${reset_cmd}"
    ssh ${no_host_check} snbuilder@${win_server} ${reset_cmd}
    # status_code=$?
    # if [ $status_code -ne 0 ]; then
    #     print_red "---> [ERROR] Failed to reset CCU board"
    #     exit $status_code
    # fi
    print_green "---> [OK]"
}
