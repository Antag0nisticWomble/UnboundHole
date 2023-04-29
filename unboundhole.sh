#!/bin/bash
# Filename: unboundhole-auto.sh
# Version: 2.0
# Creation: 17 Nov 2022
# Author: Antag0nisticWomble

## Log output Variables.

export LOGDIR="${PWD%/}"
export DATE=$(date +"%Y%m%d")
export DATETIME=$(date +"%Y%m%d_%H%M%S")
 
Job=$(basename $0 .sh)
JobClass=$(basename $0 .sh)

ERROR='\033[1;91m'  #  -> RED
GOOD='\033[1;92m'   #  -> GREEN
WARN='\033[1;93m'   #  -> YELLOW
INFO='\033[1;96m'   #  -> BLUE
END='\033[0m'       #  -> DEFAULT

## Logging function

function Log_Open() {
        if [ "$NO_JOB_LOGGING" ] ; then
                einfo "Not logging to a logfile because -Z option specified." #(*)
        else
                [[ -d $LOGDIR/$JobClass ]] || mkdir -p "$LOGDIR"/"$JobClass"
                Pipe=${LOGDIR}/$JobClass/${Job}_${DATETIME}.pipe
                mkfifo -m 700 "$Pipe"
                LOGFILE=/${LOGDIR}/$JobClass/${Job}_${DATETIME}.log
                exec 3>&1
                tee "${LOGFILE}" <"$Pipe" >&3 &
                teepid=$!
                exec 1>"$Pipe"
                PIPE_OPENED=1
                echo -e "Logging to $LOGFILE  # (*)"
                [ "$SUDO_USER" ] && echo -e "Sudo user: $SUDO_USER" #(*)
        fi
}
 
function Log_Close() {
        if [ "${PIPE_OPENED}" ] ; then
                exec 1<&3
                sleep 0.2
                ps --pid "$teepid" >/dev/null
                if [ $? -eq 0 ] ; then
                        # a wait $teepid whould be better but some
                        # commands leave file descriptors open
                        sleep 1
                        kill  "$teepid"
                fi
                sudo rm "$Pipe"
                unset PIPE_OPENED
        fi
}
 
OPTIND=1
while getopts ":Z" opt ; do
        case $opt in
                Z)
                NO_JOB_LOGGING="true"
                ;;
        esac
done

## Shared functions

function whitelist(){
    sudo git clone https://github.com/anudeepND/whitelist.git /opt/whitelist/
    sudo sed -i '87s/.*/ /' /opt/whitelist/scripts/whitelist.py
    cd /opt/whitelist/scripts/ || exit
    sudo python3 whitelist.py
}

function gravity_up(){
    sudo pihole -g
}

function sysreboot(){
    echo -e "$INFO Would you like to reboot the system now? Y/N $END"
        read sys_reboot_yn
            case $sys_reboot_yn in
                [yY])
                    echo -e "$WARN system rebooting in 10 seconds! $END"
                    sleep 10
                    sudo reboot
                    ;;
                [nN])
                    echo -e "$INFO Please restart the script once system has rebooted. $END"
                    exit 0
                    ;;
            esac
}

## Script start

Log_Open

## Ubuntu

if  [ "$(hostnamectl | grep -oE 'Ubuntu')" = 'Ubuntu' ]
    then
        echo -e "$INFO Ubuntu detected continuing $END"
            echo -e "$INFO Is the system fully updated? [Y / N] $END"
            read ubuntu_updated_yn
                case $ubuntu_updated_yn in
                    [yY])
                        sudo apt install curl unbound sqlite3 -y
                        echo -e " "
                        wget https://www.internic.net/domain/named.root -qO- | sudo tee /var/lib/unbound/root.hints
                        echo -e " "
                        sudo sed -i '$ a net.core.rmem_max=1048576' /etc/sysctl.conf
                        wget https://raw.githubusercontent.com/Antag0nisticWomble/UnboundHole/stable/pi-hole.conf -qO- | sudo tee /etc/unbound/unbound.conf
                        echo -e ""
                        sudo sed -i '$ a 0 1 * * */7     root    /opt/whitelist/scripts/whitelist.py' /etc/crontab
                        sudo sed -i '$ a 05 01 15 */3 *  root    wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root' /etc/crontab
                        sudo sed -i '$ a 10 01 15 */3 *  root    service unbound restart' /etc/crontab
                        sudo sed -i '$ a FallbackNTP=194.58.204.20 pool.ntp.org/' /etc/systemd/timesyncd.conf
                        sudo systemctl enable unbound
                        sudo systemctl stop unbound
                        sleep 2
                        sudo systemctl start unbound
                        sleep 2
                        if [ "$(systemctl status unbound | grep -oE 'Active')" = 'Active' ]
                            then
                                echo -e "$GOOD Unbound working correctly coninuing $END"
                            else
                                echo -e "$ERROR Issue with installation. Please try again $END"
                                cat /var/log/syslog | grep -i unbound > "$LOGDIR"/unbound.log
                                exit
                        fi
                        sudo curl -sSL https://install.pi-hole.net | sudo PIHOLE_SKIP_OS_CHECK=true bash
                        sudo systemctl status pihole-FTL
                        if [ "$(systemctl status pihole-FTL | grep -oE 'Active')" = 'Active' ]
                            then
                                echo -e "$GOOD Pihole FTL working correctly coninuing $END"
                            else
                                echo -e "$ERROR Issue with pihole-FTL installation. Please try again $END"
                                cat /var/log/syslog | grep -i pihole-FTL > "$LOGDIR"/pihole-FTL.Log
                                exit
                        fi
                        sudo sed -i 's/cache-size=10000/cache-size=0 /' /etc/dnsmasq.d/01-pihole.conf
                        sudo sed -i 's/CACHE_SIZE=10000/CACHE_SIZE=0 /' /etc/pihole/setupVars.conf
                        sudo sed -i '$ a ANALYZE_ONLY_A_AND_AAAA=true' /etc/pihole/pihole-FTL.conf
                        sudo sed -i '$ a MAXDBDAYS=90' /etc/pihole/pihole-FTL.conf
                        sudo sed -i '$ a BLOCK_ICLOUD_PR=true' /etc/pihole/pihole-FTL.conf
                        sudo sed -i '$ a MOZILLA_CANARY=true' /etc/pihole/pihole-FTL.conf
                        sudo systemctl stop pihole-FTL
                        sudo systemctl start pihole-FTL
                        sudo curl -sSL https://raw.githubusercontent.com/Antag0nisticWomble/UnboundHole/stable/adlists.sh | bash
                        gravity_up
                        whitelist
                        sleep 5
                        if [ "$(dig dnssec-failed.org @127.0.0.1 -p 5335 | grep -oE 'SERVFAIL')" = 'SERVFAIL' ]
                            then
                                echo -e "$GOOD Bad signature test passed successfully. $END"
                            else
                                echo -e "$ERROR Bad signature test failed. Issue with Unbound installation please report your fault along with the log files generated in $LOGDIR $END"
                                cat /var/log/syslog | grep -i unbound > $LOGDIR/unbound.log
                        fi
                        if [ "$(dig amazon.com @127.0.0.1 -p 5335 | grep -oE 'NOERROR')" = 'NOERROR' ]
                            then
                                echo -e "$GOOD Good signature test passed successfully. $END"
                            else
                                echo -e "$ERROR Good signature test faied. Issue with Unbound installation pplease report your fault along with the log files generated in $LOGDIR $END"
                                cat /var/log/syslog | grep -i unbound > $LOGDIR/unbound.log
                                exit
                        fi
                        echo -e "$WARN Remember to run sudo pihole -a -p to change your password. $END"
                        echo -e "$GOOD Installation complete. Please reboot.$END"
                        ;;
                    [nN])
                        echo -e "$WARN Would you like to upgrade the system now? Y/N $END"    
                        read ubuntu_upgrade_yn
                            case $ubuntu_upgrade_yn in
                                [yY])
                                    sudo apt update
                                    sudo apt full-upgrade -y
                                    sudo snap refresh
                                    sysreboot
                                    ;;
                                [nN])
                                    echo -e "$ERROR Please update and reboot system then try again. $END"
                                    exit 0
                                    ;;
                            esac
                    ;;
                esac

fi


# Debian

if [ "$(hostnamectl | grep -oE 'Debian')" = 'Debian' ]
    then
        echo -e "$INFO Debian Detected Proceeding $END"
            echo -e "$INFO Is the system fully updated? [Y / N] $END"
            read debian_updated_yn
                case $debian_updated_yn in
                    [yY])
                        sudo apt install curl unbound sqlite3 -y
                        wget https://www.internic.net/domain/named.root -qO- | sudo tee /var/lib/unbound/root.hints
                        echo -e " "
                        echo -e "$INFO Installing unbound configuration. $END"
                        sudo sed -i '$ a net.core.rmem_max=1048576' /etc/sysctl.conf
                        wget https://raw.githubusercontent.com/Antag0nisticWomble/UnboundHole/stable/pi-hole.conf -qO- | sudo tee /etc/unbound/unbound.conf
                        echo -e ""
                        sudo sed -i '$ a 0 1 * * */7     root    /opt/whitelist/scripts/whitelist.py' /etc/crontab
                        sudo sed -i '$ a 05 01 15 */3 *  root    wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root' /etc/crontab
                        sudo sed -i '$ a 10 01 15 */3 *  root    service unbound restart' /etc/crontab
                        sudo sed -i '$ a FallbackNTP=194.58.204.20 pool.ntp.org/' /etc/systemd/timesyncd.conf
                        sudo systemctl enable unbound
                        sudo systemctl stop unbound
                        sleep 2
                        sudo systemctl start unbound
                        if [ "$(systemctl status unbound | grep -oE 'Active')" = 'Active' ]
                            then
                                echo -e "$GOOD Unbound working correctly coninuing $END"
                            else
                                echo -e "$ERROR Issue with installation. Please try again $END"
                                cat /var/log/syslog | grep -i unbound > "$LOGDIR"/unbound.log
                                exit
                        fi
                        sudo curl -sSL https://install.pi-hole.net | sudo PIHOLE_SKIP_OS_CHECK=true bash
                        sudo sed -i 's/cache-size=10000/cache-size=0 /' /etc/dnsmasq.d/01-pihole.conf
                        sudo sed -i 's/CACHE_SIZE=10000/CACHE_SIZE=0 /' /etc/pihole/setupVars.conf
                        sudo sed -i '$ a ANALYZE_ONLY_A_AND_AAAA=true' /etc/pihole/pihole-FTL.conf
                        sudo sed -i '$ a MAXDBDAYS=90' /etc/pihole/pihole-FTL.conf
                        sudo sed -i '$ a BLOCK_ICLOUD_PR=true' /etc/pihole/pihole-FTL.conf
                        sudo sed -i '$ a MOZILLA_CANARY=true' /etc/pihole/pihole-FTL.conf
                        sudo systemctl stop pihole-FTL
                        sleep 2
                        sudo systemctl start pihole-FTL
                        sudo curl -sSL https://raw.githubusercontent.com/Antag0nisticWomble/UnboundHole/stable/adlists.sh | bash
                        gravity_up
                        whitelist
                        sleep 5
                        if [ "$(dig dnssec-failed.org @127.0.0.1 -p 5335 | grep -oE 'SERVFAIL')" = 'SERVFAIL' ]
                            then
                                echo -e "$GOOD Bad signature test passed successfully. $END"
                            else
                                echo -e "$ERROR Bad signature test failed. Issue with Unbound installation please report your fault along with the log files generated in $LOGDIR $END"
                                cat /var/log/syslog | grep -i unbound > "$LOGDIR"/unbound.log
                        fi
                        if [ "$(dig amazon.com @127.0.0.1 -p 5335 | grep -oE 'NOERROR')" = 'NOERROR' ]
                            then
                                echo -e "$GOOD Good signature test passed successfully. $END"
                            else
                                echo -e "$ERROR Good signature test faied. Issue with Unbound installation pplease report your fault along with the log files generated in $LOGDIR $END"
                                cat /var/log/syslog | grep -i unbound > "$LOGDIR"/unbound.log
                                exit
                        fi
                        echo -e "$WARN Remember to run sudo pihole -a -p to change your password. $END"
                        echo -e "$GOOD Installation complete. Please reboot.$END"
                        ;;
                    [nN])
                        echo -e "$WARN Would you like to upgrade the system now? Y/N $END"    
                        read debian_upgrade_yn
                            case $debian_upgrade_yn in
                                [yY])
                                    sudo apt update
                                    sudo apt full-upgrade -y
                                    sysreboot
                                    ;;
                                [nN])
                                    echo -e "$ERROR Please update and reboot system then try again. $END"
                                    exit 0
                                    ;;
                            esac
                    ;;
                esac

fi

Log_Close

