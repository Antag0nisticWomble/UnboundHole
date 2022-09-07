#!/bin/bash
# Filename: debian.sh
# Version: 1.3
# Creation: 2 Sept 2022
# Author: Antag0nisticWomble

source varFunc.sh

function unbound_prereq(){
    echo -e "$INFO Installing required packages. $END"
    sudo apt install curl python3 unbound sqlite3 -y
    echo -e "$GOOD Packages installed. $END"
    root_hints
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

function debian_upgrade(){
    read debian_upgrade_yn
        case $debian_upgrade_yn in
            [yY])
                echo -e "$WARN Proceeding to upgrade.$END"
                echo -e "$INFO Fetching latest updates. $END"
                sudo apt update
                echo -e "$INFO Downloading & installing any new packages. $END"
                sudo apt full-upgrade -y
                echo -e "$GOOD System upgrades complete! $END"
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
    read debian_updated_yn
        case $debian_updated_yn in
            [yY])
                echo -e "$GOOD Continuing to installation Phase. $END"
                unbound_prereq
                ;;
            [nN])
                echo -e "$WARN Would you like to upgrade the system now? Y/N $END"
                debian_upgrade
                ;;
        esac

## Install prerequisites

unbound_prereq

## Install unbound configuration

unboundconf

## Add whitelist script and root hints update to cron

update_crontab

## Setup time servers for unbound

timesync_conf

## Install pihole

pihole

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

whitelist

## Check Unbound DNSSEC and Pihole are functioning correctly

sig_check

## Password Reminder.

echo -e "$GOOD Installation complete. Please reboot. $END"
echo -e "$WARN Remember to run sudo pihole -a -p to change your password. $END"
