#!/bin/bash
# Filename: unboundhole-auto.sh
# Version: 1.4
# Creation: 5 Sept 2022
# Author: Antag0nisticWomble

## Log output Variables.

export LOGDIR="${PWD%/}"
export DATE=`date +"%Y%m%d"`
export DATETIME=`date +"%Y%m%d_%H%M%S"`
 
ScriptName=`basename $0`
Job=`basename $0 .sh`
JobClass=`basename $0 .sh`

## Logging functions

function Log_Open() {
        if [ $NO_JOB_LOGGING ] ; then
                einfo "Not logging to a logfile because -Z option specified." #(*)
        else
                [[ -d $LOGDIR/$JobClass ]] || mkdir -p $LOGDIR/$JobClass
                Pipe=${LOGDIR}/$JobClass/${Job}_${DATETIME}.pipe
                mkfifo -m 700 $Pipe
                LOGFILE=/${LOGDIR}/$JobClass/${Job}_${DATETIME}.log
                exec 3>&1
                tee ${LOGFILE} <$Pipe >&3 &
                teepid=$!
                exec 1>$Pipe
                PIPE_OPENED=1
                enotify="Logging to $LOGFILE  # (*)"
                [ $SUDO_USER ] && enotify "Sudo user: $SUDO_USER" #(*)
        fi
}
 
function Log_Close() {
        if [ ${PIPE_OPENED} ] ; then
                exec 1<&3
                sleep 0.2
                ps --pid $teepid >/dev/null
                if [ $? -eq 0 ] ; then
                        # a wait $teepid whould be better but some
                        # commands leave file descriptors open
                        sleep 1
                        kill  $teepid
                fi
                rm $Pipe
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
 
Log_Open

## Output Formatting

ERROR='\033[1;91m'  #  -> RED
GOOD='\033[1;92m'   #  -> GREEN
WARN='\033[1;93m'   #  -> YELLOW
INFO='\033[1;96m'   #  -> BLUE
END='\033[0m'       #  -> DEFAULT

## Common Functions

function whitelist(){
    echo -e "$INFO Installing whitelist script. $END"
    sudo git clone https://github.com/anudeepND/whitelist.git /opt/whitelist/
    sudo sed -i '87s/.*/ /' /opt/whitelist/scripts/whitelist.py
    echo -e "$INFO Starting whitelist script. $END"
    cd /opt/whitelist/scripts/
    sudo ./whitelist.py
}

function gravity_up(){
    echo -e "$INFO Pulling in new lists into gravity. $END"
    sudo pihole -g
}

function sig_check(){
    echo -e "$INFO Checking DNSSEC is working $END"
        if [ "$(dig sigfail.verteiltesysteme.net @127.0.0.1 -p 5335 | grep -oE 'SERVFAIL')" = 'SERVFAIL' ]
            then
                echo -e "$GOOD Bad signature test passed successfully. $END"
            else
                echo -e "$ERROR Bad signature test failed. Issue with Unbound installation please report your fault along with the log files generated in 
                $LOGDIR $END"
        fi
        if [ "$(dig sigok.verteiltesysteme.net @127.0.0.1 -p 5335 | grep -oE 'NOERROR')" = 'NOERROR' ]
            then
                echo -e "$GOOD Good signature test passed successfully. $END"
            else
                cat /var/log/syslog | grep -i unbound > $LOGDIR/unbound.log
                echo -e "$ERROR Good signature test faied. Issue with Unbound installation pplease report your fault along with the log files generated in 
                $LOGDIR $END"
                exit
        fi
        if [ "$(dig google.com 127.0.0.1 -p 53 | grep -oE 'NOERROR')" = 'NOERROR' ]
            then    
                echo -e "$GOOD Pihole test complete. Installation complete. $END"
            else
                cat /var/log/syslog | grep -i pihole > $LOGDIR/pihole.log
                echo -e "$ERROR Issue with installation please report your fault along with the log files generated in 
                $LOGDIR. $END"
                exit
        fi
}

function sysreboot(){
    echo -e "$INFO Would you like to reboot the system now? Y/N $END"
        read sys_reboot_yn
            case $sys_reboot_yn in
                [yY])
                    echo -e "$WARN system rebooting in 10 seconds! $END"
                    sudo shutdown -r 10
                    ;;
                [nN])
                    echo -e "$INFO Please restart the script once system has rebooted. $END"
                    exit 0
                    ;;
            esac
}

## -------------------------  Script start  ------------------------- ##

# Ubuntu

if  [ "$(hostnamectl | grep -oE 'Ubuntu')" = 'Ubuntu' ]
    then
        echo -e "$INFO Ubuntu detected continuing $END"
            echo -e "$INFO Is the system fully updated? [Y / N] $END"
            read ubuntu_updated_yn
                case $ubuntu_updated_yn in
                    [yY])
                        echo -e "$GOOD Continuing to installation Phase. $END"
                        echo -e "$INFO Installing required packages. $END"
                        sudo apt install curl unbound sqlite3 -y
                        echo -e "$INFO Downloading and installing root hints file. $END"
                        wget https://www.internic.net/domain/named.root -qO- | sudo tee /var/lib/unbound/root.hints
                        echo -e " "
                        echo -e "$INFO Installing unbound configuration. $END"
                        sudo sed -i '$ a net.core.rmem_max=1048576' /etc/sysctl.conf
                        wget https://raw.githubusercontent.com/Antag0nisticWomble/UnboundHole/main/pi-hole.conf -qO- | sudo tee /etc/unbound/unbound.conf
                        echo -e ""
                        echo -e "$INFO Updating Crontab. $END"
                        sudo sed -i '$ a 0 1 * * */7     root    /opt/whitelist/scripts/whitelist.py' /etc/crontab
                        sudo sed -i '$ a 05 01 15 */3 *  root    wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root' /etc/crontab
                        sudo sed -i '$ a 10 01 15 */3 *  root    service unbound restart' /etc/crontab
                        echo -e "$INFO Updating NTP Server configuration $END"
                        sudo sed -i '$ a FallbackNTP=194.58.204.20 pool.ntp.org/' /etc/systemd/timesyncd.conf
                        echo -e "$INFO starting and enabling unbound service $END"
                        sudo systemctl enable --now unbound
                        if [ "$(systemctl status unbound | grep -oE 'Active')" = 'Active' ]
                            then
                                echo -e "$GOOD Unbound working correctly coninuing $END"
                            else
                                echo -e "$ERROR Issue with installation. Please try again $END"
                                cat /var/log/syslog | grep -i unbound > $LOGDIR/unbound.log
                                exit
                        fi
                        echo -e "$INFO Beginning pihole installation. $END"
                        sudo curl -sSL https://install.pi-hole.net | sudo PIHOLE_SKIP_OS_CHECK=true bash
                        echo -e "$INFO Disabling pihole cache. $END"
                        sudo sed -i 's/cache-size=10000/cache-size=0 /' /etc/dnsmasq.d/01-pihole.conf
                        echo -e "$INFO Making pihole config persistent. $END"
                        sudo sed -i 's/CACHE_SIZE=10000/CACHE_SIZE=0 /' /etc/pihole/setupVars.conf
                        echo -e "$INFO Adding tweaks to pihole-FTL. $END"
                        sudo sed -i '$ a ANALYZE_ONLY_A_AND_AAAA=true' /etc/pihole/pihole-FTL.conf
                        sudo sed -i '$ a MAXDBDAYS=90' /etc/pihole/pihole-FTL.conf
                        sudo systemctl stop pihole-FTL
                        sudo systemctl start pihole-FTL
                        echo -e "$INFO Installing adlists $END"
                        sudo curl -sSL https://raw.githubusercontent.com/Antag0nisticWomble/UnboundHole/main/automated/adlists.sh | bash
                        gravity_up
                        whitelist
                        sig_check
                        echo -e "$WARN Remember to run sudo pihole -a -p to change your password. $END"
                        echo -e "$GOOD Installation complete. Please reboot.$END"
                        ;;
                    [nN])
                        echo -e "$WARN Would you like to upgrade the system now? Y/N $END"    
                        read ubuntu_upgrade_yn
                            case $ubuntu_upgrade_yn in
                                [yY])
                                    echo -e "$WARN Proceeding to upgrade.$END"
                                    echo -e "$INFO Fetching latest updates. $END"
                                    sudo apt update
                                    echo -e "$INFO Downloading & installing any new packages. $END"
                                    sudo apt full-upgrade -y
                                    echo -e "$INFO Performing snap refresh. $END"
                                    sudo snap refresh
                                    echo -e "$GOOD System upgrades complete! $END"
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
                        echo -e "$GOOD Continuing to installation Phase. $END"
                        echo -e "$INFO Installing required packages. $END"
                        sudo apt install curl unbound sqlite3 -y
                        echo -e "$INFO Downloading and installing root hints file. $END"
                        wget https://www.internic.net/domain/named.root -qO- | sudo tee /var/lib/unbound/root.hints
                        echo -e " "
                        echo -e "$INFO Installing unbound configuration. $END"
                        sudo sed -i '$ a net.core.rmem_max=1048576' /etc/sysctl.conf
                        wget https://raw.githubusercontent.com/Antag0nisticWomble/UnboundHole/main/pi-hole.conf -qO- | sudo tee /etc/unbound/unbound.conf
                        echo -e ""
                        echo -e "$INFO Updating Crontab. $END"
                        sudo sed -i '$ a 0 1 * * */7     root    /opt/whitelist/scripts/whitelist.py' /etc/crontab
                        sudo sed -i '$ a 05 01 15 */3 *  root    wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root' /etc/crontab
                        sudo sed -i '$ a 10 01 15 */3 *  root    service unbound restart' /etc/crontab
                        echo -e "$INFO Updating NTP Server configuration $END"
                        sudo sed -i '$ a FallbackNTP=194.58.204.20 pool.ntp.org/' /etc/systemd/timesyncd.conf
                        echo -e "$INFO starting and enabling unbound service $END"
                        sudo systemctl enable --now unbound
                        sudo systemctl restart unbound
                        if [ "$(systemctl status unbound | grep -oE 'Active')" = 'Active' ]
                            then
                                echo -e "$GOOD Unbound working correctly coninuing $END"
                            else
                                echo -e "$ERROR Issue with installation. Please try again $END"
                                cat /var/log/syslog | grep -i unbound > $LOGDIR/unbound.log
                                exit
                        fi
                        echo -e "$INFO Beginning pihole installation. $END"
                        sudo curl -sSL https://install.pi-hole.net | sudo PIHOLE_SKIP_OS_CHECK=true bash
                        echo -e "$INFO Disabling pihole cache. $END"
                        sudo sed -i 's/cache-size=10000/cache-size=0 /' /etc/dnsmasq.d/01-pihole.conf
                        echo -e "$INFO Making pihole config persistent. $END"
                        sudo sed -i 's/CACHE_SIZE=10000/CACHE_SIZE=0 /' /etc/pihole/setupVars.conf
                        echo -e "$INFO Adding tweaks to pihole-FTL. $END"
                        sudo sed -i '$ a ANALYZE_ONLY_A_AND_AAAA=true' /etc/pihole/pihole-FTL.conf
                        sudo sed -i '$ a MAXDBDAYS=90' /etc/pihole/pihole-FTL.conf
                        sudo systemctl stop pihole-FTL
                        sudo systemctl start pihole-FTL
                        echo -e "$INFO Installing adlists $END"
                        sudo curl -sSL https://raw.githubusercontent.com/Antag0nisticWomble/UnboundHole/main/automated/adlists.sh | bash
                        gravity_up
                        whitelist
                        sig_check
                        echo -e "$WARN Remember to run sudo pihole -a -p to change your password. $END"
                        echo -e "$GOOD Installation complete. Please reboot.$END"
                        ;;
                    [nN])
                        echo -e "$WARN Would you like to upgrade the system now? Y/N $END"    
                        read debian_upgrade_yn
                            case $debian_upgrade_yn in
                                [yY])
                                    echo -e "$WARN Proceeding to upgrade.$END"
                                    echo -e "$INFO Fetching latest updates. $END"
                                    sudo apt update
                                    echo -e "$INFO Downloading & installing any new packages. $END"
                                    sudo apt full-upgrade -y
                                    echo -e "$GOOD System upgrades complete! $END"
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

# Centos

if [ "$(hostnamectl | grep -oE 'CentOS')" = 'CentOS' ]
    then 
        echo -e "$INFO CentOS Detected Proceeding $END"
            echo -e "$INFO Is the system fully updated? [Y / N] $END"
            read centos_updated_yn
                case $centos_updated_yn in
                    [yY])
                        echo -e "$WARN Disabling SELinux for pihole/unbound operation"
                        sudo sed -i 's/SELINUX=enforcing/SELINUX=permisive/' /etc/selinux/config
                        sudo setenforce 0
                        echo -e "$GOOD Continuing to installation Phase. $END"
                        echo -e "$INFO Installing required packages. $END"
                        sudo yum install epel-release -y
                        sudo yum install curl git python3 unbound sqlite -y
                        echo -e "$INFO Downloading and installing root hints file. $END"
                        wget https://www.internic.net/domain/named.root -qO- | sudo tee /var/lib/unbound/root.hints
                        sudo chown -R unbound:unbound /var/lib/unbound/
                        echo -e " "
                        echo -e "$INFO Installing unbound configuration. $END"
                        sudo sed -i '$ a net.core.rmem_max=1048576' /etc/sysctl.conf
                        wget https://raw.githubusercontent.com/Antag0nisticWomble/UnboundHole/main/pi-hole.conf -qO- | sudo tee /etc/unbound/unbound.conf
                        echo -e ""
                        sudo systemctl enable unbound
                        sudo systemctl start unbound-anchor
                        sudo systemctl restart unbound
                        echo -e "$INFO Updating Crontab. $END"
                        sudo sed -i '$ a 0 1 * * */7     root    /opt/whitelist/scripts/whitelist.py' /etc/crontab
                        sudo sed -i '$ a 05 01 15 */3 *  root    wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root' /etc/crontab
                        sudo sed -i '$ a 10 01 15 */3 *  root    service unbound restart' /etc/crontab
                        if [ "$(systemctl status unbound | grep -oE 'Active')" = 'Active' ]
                            then
                                echo -e "$GOOD Unbound working correctly coninuing $END"
                            else
                                echo -e "$ERROR Issue with installation. Please try again $END"
                                cat /var/log/messages | grep -i unbound > $LOGDIR/unbound.log
                                exit 1
                        fi
                        echo -e "$INFO Beginning pihole installation. $END"
                        sudo curl -sSL https://install.pi-hole.net | sudo PIHOLE_SELINUX=true PIHOLE_SKIP_OS_CHECK=true bash -l
                        echo -e "$INFO Disabling pihole cache. $END"
                        sudo sed -i 's/cache-size=10000/cache-size=0 /' /etc/dnsmasq.d/01-pihole.conf
                        echo -e "$INFO Making pihole config persistent. $END"
                        sudo sed -i 's/CACHE_SIZE=10000/CACHE_SIZE=0 /' /etc/pihole/setupVars.conf
                        echo -e "$INFO Adding tweaks to pihole-FTL. $END"
                        sudo sed -i '$ a ANALYZE_ONLY_A_AND_AAAA=true' /etc/pihole/pihole-FTL.conf
                        sudo sed -i '$ a MAXDBDAYS=90' /etc/pihole/pihole-FTL.conf
                        sudo systemctl stop pihole-FTL
                        sudo systemctl start pihole-FTL
                        echo -e "$INFO Installing adlists $END"
                        sudo curl -sSL https://raw.githubusercontent.com/Antag0nisticWomble/UnboundHole/main/automated/adlists.sh | bash
                        gravity_up
                        whitelist
                        echo -e "$INFO Checking DNSSEC is working $END"
                        if [ "$(dig sigfail.verteiltesysteme.net @127.0.0.1 -p 5335 | grep -oE 'SERVFAIL')" = 'SERVFAIL' ]
                            then
                                echo -e "$GOOD Bad signature test passed successfully. $END"
                            else
                                cat /var/log/messages | grep -i unbound > $LOGDIR/unbound.log
                                dig sigfail.verteiltesysteme.net @127.0.0.1 -p 5335 > badsig.log
                                echo -e "$ERROR Bad signature test failed. Issue with Unbound installation please report your fault along with the log files generated in 
                                $LOGDIR $END"
                        fi
                        if [ "$(dig sigok.verteiltesysteme.net @127.0.0.1 -p 5335 | grep -oE 'NOERROR')" = 'NOERROR' ]
                            then
                                echo -e "$GOOD Good signature test passed successfully. $END"
                            else
                                cat /var/log/messages | grep -i unbound > $LOGDIR/unbound.log
                                dig sigfail.verteiltesysteme.net @127.0.0.1 -p 5335 > goodsig.log
                                echo -e "$ERROR Good signature test faied. Issue with Unbound installation pplease report your fault along with the log files generated in 
                                $LOGDIR $END"
                                exit 1
                        fi
                        if [ "$(dig google.com 127.0.0.1 -p 53 | grep -oE 'NOERROR')" = 'NOERROR' ]
                            then    
                            echo -e "$GOOD Pihole test complete. Installation complete. $END"
                            else
                            cat /var/log/messages | grep -i pihole > $LOGDIR/pihole.log
                            echo -e "$ERROR Issue with installation please report your fault along with the log files generated in 
                            $LOGDIR. $END"
                            exit 1
                        fi
                        echo -e "$WARN Remember to run sudo pihole -a -p to change your password. $END"
                        echo -e "$GOOD Installation complete. Please reboot.$END"
                        ;;
                    [nN])
                        echo -e "$WARN Would you like to upgrade the system now? Y/N $END"
                            read centos_upgrade_yn
                                case $centos_upgrade_yn in
                                    [yY])
                                        echo -e "$WARN Proceeding to upgrade.$END"
                                        echo -e "$INFO Fetching and installing latest updates. $END"
                                        sudo dnf update -y
                                        echo -e "$GOOD System upgrades complete! $END"
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

# Fedora

if [ "$(hostnamectl | grep -oE 'Fedora')" = 'Fedora' ]
    then
        echo -e "$INFO Fedora Detected Proceeding $END"
            echo -e "$INFO Is the system fully updated? [Y / N] $END"
            read fedora_updated_yn
                case $fedora_updated_yn in
                    [yY])
                        echo -e "$WARN Disabling SELinux for pihole/unbound operation"
                        sudo sed -i 's/SELINUX=enforcing/SELINUX=permisive/' /etc/selinux/config
                        sudo setenforce 0
                        echo -e "$GOOD Continuing to installation Phase. $END"
                        echo -e "$INFO Installing required packages. $END"
                        sudo dnf install curl git python3 unbound sqlite -y
                        echo -e "$INFO Downloading and installing root hints file. $END"
                        wget https://www.internic.net/domain/named.root -qO- | sudo tee /var/lib/unbound/root.hints
                        sudo chown -R unbound:unbound /var/lib/unbound/
                        echo -e " "
                        echo -e "$INFO Installing unbound configuration. $END"
                        sudo sed -i '$ a net.core.rmem_max=1048576' /etc/sysctl.conf
                        wget https://raw.githubusercontent.com/Antag0nisticWomble/UnboundHole/main/pi-hole.conf -qO- | sudo tee /etc/unbound/unbound.conf
                        echo -e ""
                        sudo systemctl enable unbound
                        sudo systemctl start unbound-anchor
                        sudo systemctl restart unbound
                        echo -e "$INFO Updating Crontab. $END"
                        sudo sed -i '$ a 0 1 * * */7     root    /opt/whitelist/scripts/whitelist.py' /etc/crontab
                        sudo sed -i '$ a 05 01 15 */3 *  root    wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root' /etc/crontab
                        sudo sed -i '$ a 10 01 15 */3 *  root    service unbound restart' /etc/crontab
                        if [ "$(systemctl status unbound | grep -oE 'Active')" = 'Active' ]
                            then
                                echo -e "$GOOD Unbound working correctly coninuing $END"
                            else
                                echo -e "$ERROR Issue with installation. Please try again $END"
                                cat /var/log/messages | grep -i unbound > $LOGDIR/unbound.log
                                exit 1
                        fi
                        echo -e "$INFO Beginning pihole installation. $END"
                        sudo curl -sSL https://install.pi-hole.net | sudo PIHOLE_SELINUX=true PIHOLE_SKIP_OS_CHECK=true bash -l
                        echo -e "$INFO Disabling pihole cache. $END"
                        sudo sed -i 's/cache-size=10000/cache-size=0 /' /etc/dnsmasq.d/01-pihole.conf
                        echo -e "$INFO Making pihole config persistent. $END"
                        sudo sed -i 's/CACHE_SIZE=10000/CACHE_SIZE=0 /' /etc/pihole/setupVars.conf
                        echo -e "$INFO Adding tweaks to pihole-FTL. $END"
                        sudo sed -i '$ a ANALYZE_ONLY_A_AND_AAAA=true' /etc/pihole/pihole-FTL.conf
                        sudo sed -i '$ a MAXDBDAYS=90' /etc/pihole/pihole-FTL.conf
                        sudo systemctl stop pihole-FTL
                        sudo systemctl start pihole-FTL
                        echo -e "$INFO Installing adlists $END"
                        sudo curl -sSL https://raw.githubusercontent.com/Antag0nisticWomble/UnboundHole/main/automated/adlists.sh | bash
                        gravity_up
                        whitelist
                        echo -e "$INFO Checking DNSSEC is working $END"
                        if [ "$(dig sigfail.verteiltesysteme.net @127.0.0.1 -p 5335 | grep -oE 'SERVFAIL')" = 'SERVFAIL' ]
                            then
                                echo -e "$GOOD Bad signature test passed successfully. $END"
                            else
                                cat /var/log/messages | grep -i unbound > $LOGDIR/unbound.log
                                dig sigfail.verteiltesysteme.net @127.0.0.1 -p 5335 > badsig.log
                                echo -e "$ERROR Bad signature test failed. Issue with Unbound installation please report your fault along with the log files generated in 
                                $LOGDIR $END"
                        fi
                        if [ "$(dig sigok.verteiltesysteme.net @127.0.0.1 -p 5335 | grep -oE 'NOERROR')" = 'NOERROR' ]
                            then
                                echo -e "$GOOD Good signature test passed successfully. $END"
                            else
                                cat /var/log/messages | grep -i unbound > $LOGDIR/unbound.log
                                dig sigfail.verteiltesysteme.net @127.0.0.1 -p 5335 > goodsig.log
                                echo -e "$ERROR Good signature test faied. Issue with Unbound installation pplease report your fault along with the log files generated in 
                                $LOGDIR $END"
                                exit 1
                        fi
                        if [ "$(dig google.com 127.0.0.1 -p 53 | grep -oE 'NOERROR')" = 'NOERROR' ]
                            then    
                            echo -e "$GOOD Pihole test complete. Installation complete. $END"
                            else
                            cat /var/log/messages | grep -i pihole > $LOGDIR/pihole.log
                            echo -e "$ERROR Issue with installation please report your fault along with the log files generated in 
                            $LOGDIR. $END"
                            exit 1
                        fi
                        echo -e "$WARN Remember to run sudo pihole -a -p to change your password. $END"
                        echo -e "$GOOD Installation complete. Please reboot.$END"
                        ;;
                    [nN])
                        echo -e "$WARN Would you like to upgrade the system now? Y/N $END"
                            read fedora_upgrade_yn
                                case $fedora_upgrade_yn in
                                    [yY])
                                        echo -e "$WARN Proceeding to upgrade.$END"
                                        echo -e "$INFO Fetching and installing latest updates. $END"
                                        sudo dnf update -y
                                        echo -e "$GOOD System upgrades complete! $END"
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

rm $Pipe
