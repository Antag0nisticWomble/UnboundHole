#!/bin/bash
# Filename: fedora.sh
# Version: 1.3
# Creation: 2 Sept 2022
# Author: Antag0nisticWomble

source varFunc.sh

## Disable SELinux (Required for pihole and unbound to function)

sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
sudo setenforce 0

function unbound_prereq(){
    echo -e "$INFO Installing required packages. $END"
    echo -e " "
    sudo dnf install curl python3 unbound sqlite -y
    echo -e "$GOOD Packages installed. $END"
    echo -e " "
}

function sys_reboot(){
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

function fedora_upgrade(){
    read fedora_upgrade_yn
        case $fedora_upgrade_yn in
            [yY])
                echo -e "$WARN Proceeding to upgrade.$END"
                echo -e " "
                echo -e "$INFO Fetching and installing latest updates. $END"
                echo -e " "
                sudo dnf update -y
                echo -e " "
                echo -e "$GOOD System upgrades complete! $END"
                echo -e " "
                echo -e "$INFO Would you like to reboot the system now? Y/N $END"
                sys_reboot
                ;;
            [nN])
                echo -e "$ERROR Please update and reboot system then try again. $END"
                exit 0
                ;;
        esac
}


echo -e "$INFO Is the system fully updated? [Y / N] $END"
    read fedora_updated_yn
        case $fedora_updated_yn in
            [yY])
                echo -e "$GOOD Continuing to installation Phase. $END"
                echo -e " "
                unbound_prereq
                ;;
            [nN])
                echo -e "$WARN Would you like to upgrade the system now? Y/N $END"
                echo -e " "
                fedora_upgrade
                ;;
        esac


## Install prerequisites

unbound_prereq

## Install root hints

echo -e "$INFO Downloading and installing root hints file. $END"
echo -e " "
wget https://www.internic.net/domain/named.root -qO- | sudo tee /var/lib/unbound/root.hints
echo -e " "
echo -e "$GOOD Root hints file successfully installed. $END"
echo -e " "

## Install unbound configuration

unboundconf

## Add whitelist script and root hints update to cron

update_crontab

## Starting unbound service

echo -e "$INFO starting and enabling unbound service $END"
echo -e " "
chown -R unbound:unbound /var/lib/unbound
sudo systemctl enable unbound
sudo systemctl restart unbound

if [ "$(systemctl status unbound | grep -oE 'Active')" = 'Active' ]
    then
        echo -e "$GOOD Unbound working correctly coninuing $END"
    else
        echo -e "$ERROR Issue with installation. Please try again $END"
        cat /var/log/messages | grep -i unbound > $log_location/unbound.log
        exit 1
fi

## Install pihole

echo -e "$INFO Beginning pihole installation. $END"
echo -e " "
sudo curl -sSL https://install.pi-hole.net | sudo PIHOLE_SELINUX=true PIHOLE_SKIP_OS_CHECK=true bash -l
echo -e "$INFO Pihole successfully installed. $END"
echo -e " "

## Disable pihole cache and dnssec

pihole_conf

## Make pihole config persistent

config_persist

## Tweal FTL for better performance with unbound

ftl_tweaks

## Add community adlists to gravity

adlists

## Update gravity database

gravity_up

## Pull in whitelist scripts

cd /opt/
    
## Download whitelist scrips for pihole.

echo -e "$INFO Install whitelist script. $END"
echo -e " "
sudo git clone https://github.com/anudeepND/whitelist.git 

## Remove clear console line.

sudo sed -i '87s/.*/ /' /opt/whitelist/scripts/whitelist.py

## Move to Whitelist Directory.

cd /opt/whitelist/scripts

## Run Whitelist script for first time. (Cron will run this on schedule).

echo -e "$INFO Starting whitelist script. $END"
echo -e " "
sudo python3 ./whitelist.py
echo -e "$GOOD Script completed successfully. Proceeding to test DNSSEC. $END"
echo -e " "

## Check Unbound DNSSEC and Pihole are functioning correctly

echo -e "$INFO Checking DNSSEC is working $END"
echo -e " "
if [ "$(dig sigfail.verteiltesysteme.net @127.0.0.1 -p 5335 | grep -oE 'SERVFAIL')" = 'SERVFAIL' ]
    then
        echo -e "$GOOD Bad signature test passed successfully. $END"
        echo -e " "
    else
        cat /var/log/messages | grep -i unbound > $log_location/unbound.log
        dig sigfail.verteiltesysteme.net @127.0.0.1 -p 5335 > badsig.log
        echo -e "$ERROR Bad signature test failed. Issue with Unbound installation please report your fault along with the log files generated in 
        $log_location $END"
        echo -e " "
fi
if [ "$(dig sigok.verteiltesysteme.net @127.0.0.1 -p 5335 | grep -oE 'NOERROR')" = 'NOERROR' ]
    then
        echo -e "$GOOD Good signature test passed successfully. $END"
        echo -e " "
    else
        cat /var/log/messages | grep -i unbound > $log_location/unbound.log
        dig sigfail.verteiltesysteme.net @127.0.0.1 -p 5335 > goodsig.log
        echo -e "$ERROR Good signature test faied. Issue with Unbound installation pplease report your fault along with the log files generated in 
        $log_location $END"
        echo -e " "
        exit 1
fi
if [ "$(dig google.com 127.0.0.1 -p 53 | grep -oE 'NOERROR')" = 'NOERROR' ]
    then    
        echo -e "$GOOD Pihole test complete. Installation complete. $END"
        echo -e " "
    else
        cat /var/log/messages | grep -i pihole > $log_location/pihole.log
        echo -e "$ERROR Issue with installation please report your fault along with the log files generated in 
        $log_location. $END"
        echo -e " "
        exit 1
fi

## Password Reminder.

echo -e "$GOOD Installation complete.$END""$WARN Remember to run sudo pihole -a -p to change your password. $END"
